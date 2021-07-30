// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//abstract implementation of ERC721
//used to store an item's metadata (ex. https://game.example/item-id-8u5h2m.json)
//it already has IERC721Metadata and IERC721Enumerable, so no need to add it
//usage: _setTokenURI(tokenId, tokenURI)
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

abstract contract ERC721TransferFees is ERC721 {
  //10000 means 100.00%
  uint256 internal constant TOTAL_ALLOWABLE_FEES = 10000;
  //cache for total fee (could be problematic if not synced)
  uint256 public totalFees;
  //map for all fees
  mapping(address => uint256) public fees;
  //index for recipients (so we can loop the map)
  address[] internal _recipients;

  /**
   * @dev Sets a fee that will be collected during the exchange method
   */
  function _setFee(address recipient, uint256 fee) internal {
    require(fee > 0, 'Allocation should be more than 0');
    require(
      fee <= TOTAL_ALLOWABLE_FEES,
      'Allocation should not be more than 100% where 10000 equals 100.00%'
    );
    require(
      (totalFees + fee) <= TOTAL_ALLOWABLE_FEES,
      'Total fee should be more than 0'
    );

    //if no recipient
    if (fees[recipient] == 0) {
      //add recipient
      _recipients.push(recipient);
      //map fee
      fees[recipient] = fee;
      //add to total fee
      totalFees += fee;
    //else there's already an existing recipient
    } else {
      //remove old fee from total fee
      totalFees -= fees[recipient];
      //map fee
      fees[recipient] = fee;
      //add to total fee
      totalFees += fee;
    }
  }

  /**
   * @dev Removes a fee
   */
  function _removeFee(address recipient) internal {
    require(fees[recipient] != 0, 'Recipient has no fees');
    totalFees -= fees[recipient];
    delete fees[recipient];
  }
}
