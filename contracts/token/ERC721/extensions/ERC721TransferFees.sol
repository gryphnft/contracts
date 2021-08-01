// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//implementation of ERC721
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
      'Exceeds total fees'
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
    //deduct total fees
    totalFees -= fees[recipient];
    //remove fees from the map
    delete fees[recipient];
    //Tricky logic to remove an element from an array...
    //if there are at least 2 elements in the array,
    if (_recipients.length > 1) {
      //find the recipient
      for (uint i = 0; i < _recipients.length; i++) {
        if(_recipients[i] == recipient) {
          //move the last element to the deleted element
          _recipients[i] = _recipients[_recipients.length - 1];
          break;
        }
      }
    }

    //either way remove the last element
    _recipients.pop();
  }
}
