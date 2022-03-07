// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

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

// ============ Inferfaces ============

interface IERC20Capped is IERC20 {
  function cap() external returns(uint256);
}

// ============ Errors ============

error InvalidAmount();

contract GryphEconomy is 
  AccessControlEnumerable, 
  ReentrancyGuard,
  Pausable 
{
  using Address for address;
  using SafeMath for uint256;

  // ============ Events ============

  event ERC20Received(address indexed sender, uint256 amount);
  event ERC20Sent(address indexed recipient, uint256 amount);
  event DepositReceived(address from, uint256 amount);

  // ============ Constants ============

  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

  //this is the contract address for $GRYPH
  IERC20Capped public immutable GRYPH_TOKEN;
  //this is the token cap of $GRYPH
  uint256 public immutable TOKEN_CAP;

  // ============ Store ============

  //where 5000 = 50.00%
  uint16 private _interest = 5000;
  //where 20000 = 200.00%
  uint16 private _sellFor = 20000;
  //where 5000 = 50.00%
  uint16 private _buyFor = 5000;

  // ============ Deploy ============

  /**
   * @dev Grants `DEFAULT_ADMIN_ROLE` to the account that deploys the 
   * contract.
   */
  constructor(IERC20Capped token) payable {
    //set up roles for the contract creator
    address sender = _msgSender();
    _setupRole(DEFAULT_ADMIN_ROLE, sender);
    _setupRole(PAUSER_ROLE, sender);
    //set the token address
    GRYPH_TOKEN = token;
    TOKEN_CAP = token.cap();
    //start paused
    _pause();
  }

  /**
   * @dev The Ether received will be logged with {PaymentReceived} 
   * events. Note that these events are not fully reliable: it's 
   * possible for a contract to receive Ether without triggering this 
   * function. This only affects the reliability of the events, and not 
   * the actual splitting of Ether.
   *
   * To learn more about this see the Solidity documentation for
   * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
   * functions].
   */
  receive() external payable virtual {
    emit DepositReceived(_msgSender(), msg.value);
  }

  // ============ Read Methods ============

  /**
   * @dev Returns the ether balance
   */
  function balanceEther() public view returns(uint256) {
    return address(this).balance;
  }

  /**
   * @dev Returns the $GRYPH token balance
   */
  function balanceToken() public view returns(uint256) {
    return GRYPH_TOKEN.balanceOf(address(this));
  }

  /**
   * @dev Returns the ether amount we are willing to buy $GRYPH for
   */
  function buyingFor(uint256 amount) public view returns(uint256) {
    // (eth / cap) * amount
    return balanceEther().mul(amount).div(TOKEN_CAP).mul(_buyFor).div(1000);
  }

  /**
   * @dev Returns the ether amount we are willing to sell $GRYPH for
   */
  function sellingFor(uint256 amount) public view returns(uint256) {
    // (eth / cap) * amount
    return balanceEther().mul(amount).div(TOKEN_CAP).mul(_sellFor).div(1000);
  }

  // ============ Write Methods ============

  /**
   * @dev Buys `amount` of $GRYPH 
   */
  function buy(address recipient, uint256 amount) 
    public payable whenNotPaused nonReentrant
  {
    uint256 value = buyingFor(amount);
    if (value == 0 
      || msg.value < value
      || balanceToken() < amount
    ) revert InvalidAmount();
    //we already received the ether
    //so just send the tokens
    SafeERC20.safeTransfer(GRYPH_TOKEN, recipient, amount);
    emit ERC20Sent(recipient, amount);
  }

  /**
   * @dev Sells `amount` of $GRYPH 
   */
  function sell(uint256 amount) public whenNotPaused nonReentrant {
    address recipient = _msgSender();
    //check allowance
    if(GRYPH_TOKEN.allowance(recipient, address(this)) < amount) 
      revert InvalidAmount();
    //now accept the payment
    SafeERC20.safeTransferFrom(GRYPH_TOKEN, recipient, address(this), amount);
    //send the ether
    Address.sendValue(payable(recipient), sellingFor(amount));
    emit ERC20Received(recipient, amount);
  }

  // ============ Admin Methods ============

  /**
   * @dev Sets the buy for percent
   */
  function buyFor(uint16 percent) 
    public payable onlyRole(DEFAULT_ADMIN_ROLE) 
  {
    _buyFor = percent;
  }

  /**
   * @dev Sets the interest
   */
  function interest(uint16 percent) 
    public payable onlyRole(DEFAULT_ADMIN_ROLE) 
  {
    _interest = percent;
  }

  /**
   * @dev Pauses all token transfers.
   */
  function pause() public virtual onlyRole(PAUSER_ROLE) {
    _pause();
  }

  /**
   * @dev Sets the sell for percent
   */
  function sellFor(uint16 percent) 
    public payable onlyRole(DEFAULT_ADMIN_ROLE) 
  {
    _sellFor = percent;
  }

  /**
   * @dev Unpauses all token transfers.
   */
  function unpause() public virtual onlyRole(PAUSER_ROLE) {
    _unpause();
  }
}