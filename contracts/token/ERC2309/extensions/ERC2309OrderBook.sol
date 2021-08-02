// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//abstract implementation of ERC2309
//allows this contract to be treated as a token factory organized by collections
import "./../ERC2309.sol";

/**
 * @title ERC2309 One Sided Order Book
 * @dev ERC2309 Factory where a token owner can list their token for sale
 */
abstract contract ERC2309OrderBook is ERC2309 {
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
  mapping (uint256 => uint256) public book;

  /**
   * @dev Allows token owners to list their tokens for sale
   */
  function list(uint256 tokenId, uint256 amount) public {
    //error if the sender is not the owner
    // even the contract owner cannot list a token
    require(
      ownerOf(tokenId) == _msgSender(),
      "ERC2309CollectionBook: Only the token owner can list a token"
    );
    //add the listing
    book[tokenId] = amount;
    //emit that something was listed
    emit Listed(_msgSender(), tokenId, amount);
  }

  /**
   * @dev Allows token owners to remove their token sale listing
   */
  function delist(uint256 tokenId) public {
    address owner = ownerOf(tokenId);
    //error if the sender is not the owner
    // even the contract owner cannot delist a token
    require(
      owner == _msgSender(),
      "ERC2309CollectionBook: Only the token owner can delist a token"
    );
    //remove the listing
    delete book[tokenId];
    //emit that something was delisted
    emit Delisted(owner, tokenId);
  }

  /**
   * @dev Returns the amount being sold for
   */
  function getListing(uint256 tokenId) public view returns(uint256) {
    return book[tokenId];
  }
}
