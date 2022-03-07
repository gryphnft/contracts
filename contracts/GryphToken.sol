// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

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

contract GryphToken is
  Pausable,
  AccessControlEnumerable, 
  ERC20Burnable, 
  ERC20Capped 
{
  //all custom roles
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

  /**
   * @dev Sets the name and symbol. Sets the fixed supply. 
   * Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` 
   * to the account that deploys the contract.
   */
  constructor() 
    ERC20("GRYPH", "GRYPH")
    ERC20Capped(1000000000 ether) 
  {
    address sender = _msgSender();
    //set up roles for contract creator
    _setupRole(DEFAULT_ADMIN_ROLE, sender);
    _setupRole(MINTER_ROLE, sender);
    _setupRole(PAUSER_ROLE, sender);
    //prevent unauthorized transfers
    _pause();
  }

  /**
   * @dev Creates `amount` new tokens for `to`.
   */
  function mint(address to, uint256 amount) 
    public virtual whenNotPaused onlyRole(MINTER_ROLE)  
  {
    _mint(to, amount);
  }

  /**
   * @dev Pauses all token transfers.
   */
  function pause() public virtual onlyRole(PAUSER_ROLE) {
    _pause();
  }

  /**
   * @dev Unpauses all token transfers.
   */
  function unpause() public virtual onlyRole(PAUSER_ROLE) {
    _unpause();
  }

  /**
   * @dev Checks blacklist before token transfer
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override {
    if (!hasRole(MINTER_ROLE, _msgSender()) && !hasRole(MINTER_ROLE, from)) {
      require(!paused(), "Token transfer while paused");
    }

    super._beforeTokenTransfer(from, to, amount);
  }

  /**
   * @dev See {ERC20-_mint}.
   */
  function _mint(address account, uint256 amount) 
    internal virtual override(ERC20, ERC20Capped) 
  {
    super._mint(account, amount);
  }
}
