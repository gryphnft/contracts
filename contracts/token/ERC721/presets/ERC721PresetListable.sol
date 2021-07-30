// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//A simple way to get a counter that can only be incremented or decremented.
//Very useful for ID generation, counting contract activity, among others
//usage: Counters.Counter private ids
//       ids.increment()
//       ids.current()
//see: https://docs.openzeppelin.com/contracts/3.x/api/utils#Counters
import "@openzeppelin/contracts/utils/Counters.sol";

//implementation of ERC721
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

//custom abstract implementation of ERC721
//used to set secondary transfer fees
import "./../extensions/ERC721Listable.sol";

contract ERC721PresetListable is ERC721, ERC721Listable {
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIds;

  /**
   * @dev Constructor function
   */
  constructor (
    string memory _name,
    string memory _symbol
  ) ERC721(_name, _symbol) {}

  //no methods or configuration needs to be added for this mock

  /**
   * @dev Basic mint and transfer
   */
  function mint(address recipient) public returns (uint256) {
    _tokenIds.increment();

    uint256 tokenId = _tokenIds.current();
    _mint(recipient, tokenId);

    return tokenId;
  }
}
