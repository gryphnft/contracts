// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//custom abstract implementation of ERC1155
import "./ERC1155Listable.sol";

abstract contract ERC1155Exchangable is ERC1155Listable {
  /**
   * @dev Allows for a sender to avail of the offer price
   */
  function exchange(
    address owner,
    uint256 tokenId,
    uint256 quantity,
    bytes memory data
  ) public payable {
    //get listing
    uint256 listingAmount = _listingAmounts[tokenId][owner];
    //get quantity
    uint256 listingQuantity = _listingQuantities[tokenId][owner];
    //should be a valid listing
    require(
      listingAmount > 0 && listingQuantity > 0,
      'Owner token is not listed'
    );
    //quantity should be lte to the listing quantity
    require(
      quantity <= listingQuantity,
      'Quantity is more than what was listed'
    );
    //value should equal the listing amount
    require(
      msg.value == (listingAmount * quantity),
      "Amount sent does not match the listing amount"
    );
    //get the token owner
    address payable tokenOwner = payable(owner);

    //distribute payment to the token owner ...
    tokenOwner.transfer(msg.value);
    //transfer token
    _safeTransferFrom(owner, msg.sender, tokenId, quantity, data);

    //if no more available
    if (quantity == listingQuantity) {
      //delist
      delete _listingAmounts[tokenId][owner];
      delete _listingQuantities[tokenId][owner];
      //emit that something was delisted
      emit Delisted(owner, tokenId);
    } else {
      //otherwise, adjust the quantity
      _listingQuantities[tokenId][owner] -= quantity;
    }
  }
}
