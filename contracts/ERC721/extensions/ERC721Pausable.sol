// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

error TransferWhilePaused();

/**
 * @dev ERC721 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC721Pausable is PausableUpgradeable, ERC721 {
  /**
   * @dev See {ERC721B-_beforeTokenTransfer}.
   *
   * Requirements:
   *
   * - the contract must not be paused.
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    if (paused()) revert TransferWhilePaused();
    super._beforeTokenTransfer(from, to, tokenId);
  }
}
