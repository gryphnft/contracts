// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//custom abstract implementation of ERC721
import "./ERC1155TransferFees.sol";

//custom abstract implementation of ERC1155
import "./ERC1155Listable.sol";

abstract contract ERC1155ExchangableFees is ERC1155TransferFees, ERC1155Listable {
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

    //release payments to recipients
    for (uint i = 0; i < _recipients[tokenId].length; i++) {
      // (10 eth * 2000) / 10000 =
      payable(_recipients[tokenId][i]).transfer(
        (msg.value * _fees[tokenId][_recipients[tokenId][i]]) / TOTAL_ALLOWABLE_FEES
      );
    }

    //get the token owner
    address payable tokenOwner = payable(owner);
    //determine the remaining fee
    uint256 remainingFee = TOTAL_ALLOWABLE_FEES - _totalFees[tokenId];
    //send the remaining fee to the token owner
    tokenOwner.transfer((msg.value * remainingFee) / TOTAL_ALLOWABLE_FEES);
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
