// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//implementation of ERC721
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

  uint256 public maxQuantity;

  /**
   * @dev Constructor function
   */
  constructor (uint256 _maxQuantity) {
    require(_maxQuantity > 0, "Max quantity should be greater than 0");
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
