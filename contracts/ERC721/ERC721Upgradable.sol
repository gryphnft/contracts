// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./extensions/ERC721Pausable.sol";
import "./extensions/ERC721URIContract.sol";

abstract contract ERC721Upgradable is 
  OwnableUpgradeable, 
  ReentrancyGuardUpgradeable,
  ERC721Pausable,
  ERC721URIContract 
{
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