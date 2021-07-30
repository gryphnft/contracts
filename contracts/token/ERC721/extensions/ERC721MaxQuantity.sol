// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//abstract implementation of ERC721
//used to store an item's metadata (ex. https://game.example/item-id-8u5h2m.json)
//it already has IERC721Metadata and IERC721Enumerable, so no need to add it
//usage: _setTokenURI(tokenId, tokenURI)
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

//A simple way to get a counter that can only be incremented or decremented.
//Very useful for ID generation, counting contract activity, among others
//usage: Counters.Counter private ids
//       ids.increment()
//       ids.current()
//see: https://docs.openzeppelin.com/contracts/3.x/api/utils#Counters
import "@openzeppelin/contracts/utils/Counters.sol";

abstract contract ERC721MaxQuantity is ERC721 {
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIds;

  uint256 public maxQuantity = 1;

  /**
   * @dev Constructor function
   */
  constructor (uint256 _maxQuantity) {
    maxQuantity = _maxQuantity;
  }

  /**
   * @dev Returns true if the token id can increment
   */
  function canIncrementTokenId() public view returns(bool) {
    uint256 tokenId = _tokenIds.current();
    return tokenId < maxQuantity;
  }

  /**
   * @dev Increments the token ID with respect to max quantity
   */
  function _incrementTokenId() internal {
    require(
      canIncrementTokenId(),
      "ERC721MaxQuantity: Token ID has reached its limit"
    );
    _tokenIds.increment();
  }

  /**
   * @dev Returns the current token id
   */
  function currentTokenId() public view returns(uint256) {
    return _tokenIds.current();
  }
}
