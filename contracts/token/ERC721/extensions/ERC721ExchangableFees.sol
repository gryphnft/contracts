// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//custom abstract implementation of ERC721
import "./ERC721TransferFees.sol";

//custom abstract implementation of ERC721
import "./ERC721Listable.sol";

abstract contract ERC721ExchangableFees is ERC721TransferFees, ERC721Listable {
  /**
   * @dev Allows for a sender to avail of the offer price
   */
  function exchange(uint256 tokenId) public payable {
    //get listing
    uint256 listing = listings[tokenId];
    //should be a valid listing
    require(listing > 0, "Token is not listed");
    //value should equal the listing amount
    require(
      msg.value == listing,
      "Amount sent does not match the listing amount"
    );

    //release payments to recipients
    for (uint i = 0; i < _recipients.length; i++) {
      // (10 eth * 2000) / 10000 =
      payable(_recipients[i]).transfer(
        (msg.value * fees[_recipients[i]]) / TOTAL_ALLOWABLE_FEES
      );
    }

    //get the token owner
    address payable tokenOwner = payable(ownerOf(tokenId));
    //determine the remaining fee
    uint256 remainingFee = TOTAL_ALLOWABLE_FEES - totalFees;
    //send the remaining fee to the token owner
    tokenOwner.transfer((msg.value * remainingFee) / TOTAL_ALLOWABLE_FEES);
    //transfer token from owner to buyer
    _transfer(tokenOwner, msg.sender, tokenId);
    //finally delist
    delete listings[tokenId];
    //emit that something was delisted
    emit Delisted(ownerOf(tokenId), tokenId);
  }
}
