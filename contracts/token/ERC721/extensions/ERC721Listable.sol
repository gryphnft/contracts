// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//abstract implementation of ERC721
//used to store an item's metadata (ex. https://game.example/item-id-8u5h2m.json)
//it already has IERC721Metadata and IERC721Enumerable, so no need to add it
//usage: _setTokenURI(tokenId, tokenURI)
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

abstract contract ERC721Listable is ERC721 {
  //allow others to watch for listed tokens
  event Listed(
    address indexed owner,
    uint256 indexed tokenId,
    uint256 indexed amount
  );
  //allow others to watch for delisted tokens
  event Delisted(address indexed owner, uint256 indexed tokenId);

  // tokenId => amount
  // amount defaults to 0 and is in wei
  // apparently the data type for ether units is uint256 so we can interact
  // with it the same
  // see: https://docs.soliditylang.org/en/v0.7.1/units-and-global-variables.html
  mapping (uint256 => uint256) public listings;

  /**
   * @dev Allows token owners to list their tokens for sale
   */
  function list(uint256 tokenId, uint256 amount) public {
    //get the owner
    address owner = ownerOf(tokenId);
    //error if the sender is not the owner
    // even the contract owner cannot list a token
    require(owner == msg.sender, "Only the token owner can list a token");
    //add the listing
    listings[tokenId] = amount;
    //emit that something was listed
    emit Listed(owner, tokenId, amount);
  }

  /**
   * @dev Allows token owners to remove their token sale listing
   */
  function delist(uint256 tokenId) public {
    //error if the sender is not the owner
    // even the contract owner cannot delist a token
    require(
      ownerOf(tokenId) == msg.sender,
      "Only the token owner can delist a token"
    );
    //remove the listing
    delete listings[tokenId];
    //emit that something was delisted
    emit Delisted(ownerOf(tokenId), tokenId);
  }

  /**
   * @dev Returns the amount being sold for
   */
  function getListing(uint256 tokenId) public view returns(uint256) {
    return listings[tokenId];
  }
}
