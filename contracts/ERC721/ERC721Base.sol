// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

import "./extensions/ERC721Pausable.sol";
import "./extensions/ERC721URIContract.sol";

abstract contract ERC721Base is
  Context,
  ERC721Pausable,
  ERC721URIContract
{
  // ============ Deploy ============

  /**
   * @dev Grants `DEFAULT_ADMIN_ROLE` and `PAUSER_ROLE` to the
   * account that deploys the contract. Sets the contract's URI. 
   */
  constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

  // ============ Overrides ============

  /**
   * @dev Describes linear override for `_beforeTokenTransfer` used in 
   * both `ERC721` and `ERC721Pausable`
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721, ERC721Pausable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }
}