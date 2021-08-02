// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//custom abstract implementation of ERC2309
import "./ERC2309CollectionFees.sol";

//custom abstract implementation of ERC2309
import "./ERC2309OrderBook.sol";

/**
 * @title ERC2309 Collection Exchange
 * @dev ERC2309 Factory where buyers can buy tokens in the book and royalties are paid
 */
abstract contract ERC2309CollectionExchange is
  ERC2309CollectionFees,
  ERC2309OrderBook
{
  /**
   * @dev Allows for a sender to avail of the offer price
   */
  function exchange(uint256 tokenId) public payable {
    //get listing
    uint256 listing = book[tokenId];
    //should be a valid listing
    require(listing > 0, "ERC2309Exchange: Token is not listed");
    //value should equal the listing amount
    require(
      msg.value == listing,
      "ERC2309Exchange: Amount sent does not match the listing amount"
    );

    //get collection from token
    uint256 collectionId = TokenCollection(tokenId);

    //placeholder for recipient in the loop
    address recipient;
    //release payments to recipients
    for (uint i = 0; i < _collectionRecipients[collectionId].length; i++) {
      //get the recipient
      recipient = _collectionRecipients[collectionId][i];
      // (10 eth * 2000) / 10000 =
      payable(recipient).transfer(
        (msg.value * _collectionFees[collectionId][recipient]) / TOTAL_ALLOWABLE_FEES
      );
    }

    //get the token owner
    address payable tokenOwner = payable(ownerOf(tokenId));
    //determine the remaining fee
    uint256 remainingFee = TOTAL_ALLOWABLE_FEES - _totalCollectionFees[collectionId];
    //send the remaining fee to the token owner
    tokenOwner.transfer((msg.value * remainingFee) / TOTAL_ALLOWABLE_FEES);
    //transfer token from owner to buyer
    _transfer(tokenOwner, _msgSender(), tokenId);
    //finally delist
    delete book[tokenId];
    //emit that something was delisted
    emit Delisted(tokenOwner, tokenId);
  }
}
