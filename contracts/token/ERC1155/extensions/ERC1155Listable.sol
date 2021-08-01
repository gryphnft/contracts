// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//implementation of ERC1155
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

abstract contract ERC1155Listable is ERC1155 {
  //allow others to watch for listed tokens
  event Listed(
    address indexed owner,
    uint256 indexed tokenId,
    uint256[2] indexed listing
  );
  //allow others to watch for delisted tokens
  event Delisted(address indexed owner, uint256 indexed tokenId);

  //map for all listings
  //token id -> recipient -> amount
  mapping(uint256 => mapping(address => uint256)) internal _listingAmounts;

  //map for all listings
  //token id -> recipient -> quantity
  mapping(uint256 => mapping(address => uint256)) internal _listingQuantities;

  struct Listing {
    address owner;
    uint256 tokenId;
    uint256 amount;
    uint256 quantity;
  }

  /**
   * @dev Allows token owners to list their tokens for sale
   */
  function list(uint256 tokenId, uint256 amount, uint256 quantity) public {
    uint256 balance = balanceOf(msg.sender, tokenId);
    //error if the sender is not the owner
    // even the contract owner cannot list a token
    require(balance > 0, "Only the token owner can list a token");
    //error if the balance is less than the quantity to be listed
    require(quantity <= balance, "Token owner listing more than available");
    //add the listing
    //if the listing exists, update
    _listingAmounts[tokenId][msg.sender] = amount;
    _listingQuantities[tokenId][msg.sender] = quantity;

    //emit that something was listed
    emit Listed(msg.sender, tokenId, [amount, quantity]);
  }

  /**
   * @dev Allows token owners to remove their token sale listing
   */
  function delist(uint256 tokenId) public {
    //error if the sender is not the owner
    // even the contract owner cannot delist a token
    require(
      balanceOf(msg.sender, tokenId) > 0,
      "Only the token owner can delist a token"
    );
    //remove the listing
    delete _listingAmounts[tokenId][msg.sender];
    delete _listingQuantities[tokenId][msg.sender];
    //emit that something was delisted
    emit Delisted(msg.sender, tokenId);
  }

  /**
   * @dev Returns the amount being sold for
   */
  function getListing(address owner, uint256 tokenId)
    public
    view
    returns(Listing memory)
  {
    return Listing(
      owner,
      tokenId,
      _listingAmounts[tokenId][msg.sender],
      _listingQuantities[tokenId][msg.sender]
    );
  }
}
