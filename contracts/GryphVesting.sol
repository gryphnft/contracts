// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

//
//     ______  _______   ____  ____   _______  ____  ____  
//   .' ___  ||_   __ \ |_  _||_  _| |_   __ \|_   ||   _| 
//  / .'   \_|  | |__) |  \ \  / /     | |__) | | |__| |   
//  | |   ____  |  __ /    \ \/ /      |  ___/  |  __  |   
//  \ `.___]  |_| |  \ \_  _|  |_  _  _| |_    _| |  | |_  
//   `._____.'|____| |___||______|(_)|_____|  |____||____| 
//
//  CROSS CHAIN NFT MARKETPLACE
//  https://www.gry.ph/
//

// ============ Interfaces ============

interface IGryphToken is IERC20 {
  function mint(address to, uint256 amount) external;
}

// ============ Errors ============

error InvalidRelease();
error InvalidVesting();
error InvalidRefund();
error InvalidWithdraw();

contract GryphVesting is 
  Pausable, 
  AccessControlEnumerable, 
  ReentrancyGuard 
{
  //used in release()
  using Address for address;

  // ============ Events ============

  event ERC20Released(
    address indexed token, 
    address indexed beneficiary, 
    uint256 amount
  );

  event EtherRefunded(address indexed beneficiary, uint256 amount);

  // ============ Constants ============

  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
  //the timestamp when all accounts are fully vested
  //May 1, 2024 12:00AM GMT
  uint64 public constant VESTED_DATE = 1714521600;
  //the timestamp when all accounts can start releasing $GRYPH
  //November 1, 2022 12:00AM GMT
  uint64 public constant UNLOCK_DATE = 1667260800;

  //this is the contract address for $GRYPH
  IGryphToken public immutable GRYPH_TOKEN;
  //this is the contract address for the $GRYPH treasury
  address public immutable GRYPH_TREASURY;
  //this is the contract address for the $GRYPH economy engine
  address public immutable GRYPH_ECONOMY;

  // ============ Store ============

  //the ETH price per $GRYPH
  uint256 public currentTokenPrice;
  //the $GRYPH limit that can be vested
  uint256 public currentTokenLimit;
  //the total $GRYPH that are currently allocated
  uint256 public currentTokenAllocated;
  //the total amount that has been withdrawn
  uint256 public currentTotalWithdrawn;
  //flag to allow people to receive a refund
  bool public refunding;

  //mapping of address to $GRYPH vesting
  mapping(address => uint256) public vestingTokens;
  //mapping of address to $GRYPH already released
  mapping(address => uint256) public releasedTokens;
  //mapping of address to ether collected
  mapping(address => uint256) public etherCollected;

  //whether manually unlocked
  uint64 private _unlockedDate;

  // ============ Deploy ============

  /**
   * @dev Sets the `token`, `treasury` and `economy` addresses. Grants 
   * `DEFAULT_ADMIN_ROLE` to the account that deploys the contract.
   */
  constructor(IGryphToken token, address treasury, address economy) {
    //set up roles for the contract creator
    address sender = _msgSender();
    _setupRole(DEFAULT_ADMIN_ROLE, sender);
    _setupRole(PAUSER_ROLE, sender);
    //set the $GRYPH addresses
    GRYPH_TOKEN = token;
    GRYPH_TREASURY = treasury;
    GRYPH_ECONOMY = economy;
  }

  // ============ Read Methods ============

  /**
   * @dev Calculates the amount of tokens that are releasable. 
   * Default implementation is a linear vesting curve.
   */
  function totalReleasableAmount(address beneficiary, uint64 timestamp) 
    public view virtual returns (uint256) 
  {
    uint amount = totalVestedAmount(beneficiary, timestamp);
    return amount - releasedTokens[beneficiary];
  }

  /**
   * @dev Calculates the amount of tokens that has already vested. 
   * Default implementation is a linear vesting curve.
   */
  function totalVestedAmount(address beneficiary, uint64 timestamp) 
    public view virtual returns (uint256) 
  {
    //if time now is more than the vested date
    if (timestamp > VESTED_DATE) {
      //release all the tokens
      return vestingTokens[beneficiary];
    }

    uint64 start = unlockDate();
  
    //if nothing can be released
    if (uint64(block.timestamp) < start) {
      //no tokens releasable
      return 0;
    }
    //determine the vesting duration in seconds
    uint64 duration = VESTED_DATE - start;
    //determine the elapsed time that has passed
    uint64 elapsed = timestamp - start;
    //this is the max possible tokens we can release
    //total vesting tokens * elapsed / duration
    return (vestingTokens[beneficiary] * elapsed) / duration;
  }

  /**
   * @dev Returns the unlock date
   */
  function unlockDate() public virtual view returns(uint64) {
    if (_unlockedDate > 0) {
      return _unlockedDate;
    }
    return UNLOCK_DATE;
  }

  // ============ Write Methods ============

  /**
   * @dev Allows anyone to invest during the current stage for an `amount`
   */
  function buy(address beneficiary, uint256 amount) 
    external virtual payable nonReentrant 
  {
    // if no amount
    if (amount == 0 
      //if no price
      || currentTokenPrice == 0 
      //if no limit
      || currentTokenLimit == 0 
      //if the amount exceeds the token limit
      || (currentTokenAllocated + amount) > currentTokenLimit
      //calculate eth amount = 1000 * 0.000005 ether
      || msg.value < (amount * currentTokenPrice)
    ) revert InvalidVesting();

    //track ether collected for refund
    etherCollected[beneficiary] += msg.value;
    //last start vesting
    _vest(beneficiary, amount);
  }

  /**
   * @dev Release $GRYPH that have already vested.
   *
   * Emits a {TokensReleased} event.
   */
  function release(address beneficiary) public virtual nonReentrant {
    //if paused or not unlocked yet
    if (paused() || uint64(block.timestamp) < unlockDate()) 
      revert InvalidRelease();

    //releasable calc by total releaseable amount - amount already released
    uint256 releasable = totalReleasableAmount(
      beneficiary, 
      uint64(block.timestamp)
    );
    if (releasable == 0) revert InvalidRelease();
    //already account for the new tokens
    releasedTokens[beneficiary] += releasable;
    //next mint tokens
    address(GRYPH_TOKEN).functionCall(
      abi.encodeWithSelector(
        GRYPH_TOKEN.mint.selector, 
        beneficiary, 
        releasable
      ), 
      "Low-level mint failed"
    );
    //finally emit released
    emit ERC20Released(address(GRYPH_TOKEN), beneficiary, releasable);
  }

  /**
   * @dev Release $GRYPH that have already vested.
   */
  function refund(address beneficiary) public virtual nonReentrant {
    //should not refund if paused
    if (paused()
      //should not refund if not refunding
      || !refunding
      //should not refund if no eth was collected
      || etherCollected[beneficiary] == 0
      //should not refund if no tokens were vested
      || vestingTokens[beneficiary] == 0
      //should not refund if tokens were released
      || releasedTokens[beneficiary] > 0
    ) revert InvalidRefund();

    //less amount to the total allocated
    currentTokenAllocated -= vestingTokens[beneficiary];
    //zero out vested
    vestingTokens[beneficiary] = 0;
    //zero out eth collected
    etherCollected[beneficiary] = 0;
    //send the eth
    Address.sendValue(payable(beneficiary), etherCollected[beneficiary]);

    //finally emit released
    emit EtherRefunded(beneficiary, etherCollected[beneficiary]);
  }

  // ============ Admin Methods ============

  /**
   * @dev Pauses all token transfers.
   */
  function pause() public virtual onlyRole(PAUSER_ROLE) {
    _pause();
  }
  
  /**
   * @dev Unpauses all token transfers.
   */
  function refundAll(bool yes) 
    public virtual onlyRole(DEFAULT_ADMIN_ROLE) 
  {
    //dont allow refund if something was withdrawn
    if (currentTotalWithdrawn > 0) revert InvalidRefund();
    refunding = yes;
  }

  /**
   * @dev Unlocks vesting tokens
   */
  function unlock(uint64 timestamp) 
    public virtual onlyRole(DEFAULT_ADMIN_ROLE) 
  {
    _unlockedDate = timestamp;
  }

  /**
   * @dev Unpauses all token transfers.
   */
  function unpause() public virtual onlyRole(PAUSER_ROLE) {
    _unpause();
  }

  /**
   * @dev Allow an admin to manually vest a `beneficiary` for an `amount`
   */
  function vest(address beneficiary, uint256 amount) 
    public virtual onlyRole(DEFAULT_ADMIN_ROLE) 
  {
    _vest(beneficiary, amount); 
  }

  /**
   * @dev Sends the specified `amount` to the treasury
   */
  function sendToTreasury(uint256 amount) 
    external virtual nonReentrant onlyRole(DEFAULT_ADMIN_ROLE)
  {
    //don't allow to send if refunding
    if (refunding) revert InvalidWithdraw();
    //add to the withdrawn
    currentTotalWithdrawn += amount;
    //now withdraw
    Address.sendValue(payable(GRYPH_TREASURY), amount);
  }

  /**
   * @dev Sends the specified `amount` to the economy
   */
  function sendToEconomy(uint256 amount) 
    external virtual nonReentrant onlyRole(DEFAULT_ADMIN_ROLE)
  {
    //don't allow to send if refunding
    if (refunding) revert InvalidWithdraw();
    //add to the withdrawn
    currentTotalWithdrawn += amount;
    Address.sendValue(payable(GRYPH_ECONOMY), amount);
  }

  /**
   * @dev This contract should not hold any tokens in the first place. 
   * This method exists to transfer out tokens funds.
   */
  function withdraw(address erc20, address to, uint256 amount) 
    external virtual nonReentrant onlyRole(DEFAULT_ADMIN_ROLE)
  {
    SafeERC20.safeTransfer(IERC20(erc20), to, amount);
  }

  // ============ Internal Methods ============

  /**
   * @dev Vest a `beneficiary` for an `amount`
   */
  function _vest(address beneficiary, uint256 amount) internal virtual {
    // if no amount or refunding
    if (amount == 0 || refunding) revert InvalidVesting();
    //now add to the beneficiary
    vestingTokens[beneficiary] += amount;
    //add amount to the total allocated
    currentTokenAllocated += amount;
  }
}