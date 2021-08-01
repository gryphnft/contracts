// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//A simple way to get a counter that can only be incremented or decremented.
//Very useful for ID generation, counting contract activity, among others
//usage: Counters.Counter private ids
//       ids.increment()
//       ids.current()
//see: https://docs.openzeppelin.com/contracts/3.x/api/utils#Counters
import "@openzeppelin/contracts/utils/Counters.sol";

//abstract implementation of ERC721
//used to store an item's metadata (ex. https://game.example/item-id-8u5h2m.json)
//it already has IERC721Metadata and IERC721Enumerable, so no need to add it
//usage: _setTokenURI(tokenId, tokenURI)
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

//abstract implementation of ERC721
//used to allow destruction of an owned token (never to return)
//usage: burn(tokenId)
//see: https://docs.openzeppelin.com/contracts/4.x/api/token/erc721#ERC721Burnable
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

contract ERC721PresetZeppelin is ERC721URIStorage, ERC721Burnable {
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIds;

  /**
   * @dev Constructor function
   */
  constructor (
    string memory _name,
    string memory _symbol
  ) ERC721(_name, _symbol) {}

  /**
   * @dev Basic mint and transfer
   */
  function mint(address recipient, string memory uri) public returns (uint256) {
    _tokenIds.increment();

    uint256 tokenId = _tokenIds.current();
    _mint(recipient, tokenId);
    _setTokenURI(tokenId, uri);

    return tokenId;
  }

  /**
   * @dev Resolves duplicate _burn method definition between ERC721 and ERC721URIStorage
   */
  function _burn(uint256 tokenId)
    internal
    virtual override(ERC721, ERC721URIStorage)
  {
    return super._burn(tokenId);
  }

  /**
   * @dev Resolves duplicate tokenURI method definition between ERC721 and ERC721URIStorage
   */
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override(ERC721, ERC721URIStorage)
    returns (string memory)
  {
    return super.tokenURI(tokenId);
  }
}
