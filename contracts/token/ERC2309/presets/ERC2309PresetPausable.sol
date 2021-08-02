// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//A simple way to get a counter that can only be incremented or decremented.
//Very useful for ID generation, counting contract activity, among others
//usage: Counters.Counter private ids
//       ids.increment()
//       ids.current()
//see: https://docs.openzeppelin.com/contracts/3.x/api/utils#Counters
import "@openzeppelin/contracts/utils/Counters.sol";

//custom abstract implementation of ERC2309
import "./../extensions/ERC2309Pausable.sol";

contract ERC2309PresetPausable is ERC2309Pausable {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  /**
   * @dev Sets `name` and `symbol`
   */
  constructor(
    string memory tokenName,
    string memory tokenSymbol
  ) ERC2309(tokenName, tokenSymbol) {}

  /**
   * @dev Basic mint and transfer
   */
  function mint(address recipient) public returns (uint256) {
    _tokenIds.increment();

    uint256 tokenId = _tokenIds.current();
    _mint(recipient, tokenId);

    return tokenId;
  }

  /**
   * @dev Pauses all token transfers.
   */
  function pause() public virtual {
    _pause();
  }

  /**
   * @dev Unpauses all token transfers.
   */
  function unpause() public virtual {
    _unpause();
  }

  /**
   * @dev Resolves duplicate _beforeTokenTransfer method definition
   * between ERC2309 and ERC2309Pausable
   */
  function _beforeTokenTransfer(
      address from,
      address to,
      uint256 tokenId
  ) internal virtual override {
      super._beforeTokenTransfer(from, to, tokenId);
  }
}
