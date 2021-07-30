// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//custom abstract implementation of ERC721
import "./ERC721Listable.sol";


abstract contract ERC721Exchangable is ERC721Listable {
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
    //get the token owner
    address payable tokenOwner = payable(ownerOf(tokenId));
    //distribute payment to the token owner ...
    tokenOwner.transfer(msg.value);
    //transfer token
    _transfer(tokenOwner, msg.sender, tokenId);
    //and delist
    delete listings[tokenId];
    //emit that something was delisted
    emit Delisted(ownerOf(tokenId), tokenId);
  }
}
