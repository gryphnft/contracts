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
//used to store a contract's metadata upon contract creation
//(ex. https://game.example/item-id-8u5h2m.json)
import "./../extensions/ERC721ContractURI.sol";


contract ERC721PresetContractURI is ERC721, ERC721ContractURI {
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIds;

  /**
   * @dev Constructor function (adding uri)
   */
  constructor (
    string memory _name,
    string memory _symbol,
    string memory _uri
  )
  ERC721(_name, _symbol)
  ERC721ContractURI(_uri)
  {}

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
