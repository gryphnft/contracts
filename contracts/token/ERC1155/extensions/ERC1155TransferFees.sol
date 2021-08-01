// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//implementation of ERC1155
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

abstract contract ERC1155TransferFees is ERC1155 {
  //10000 means 100.00%
  uint256 internal constant TOTAL_ALLOWABLE_FEES = 10000;
  //map for total fees (could be problematic if not synced)
  //token id -> total fees
  mapping(uint256 => uint256) internal _totalFees;
  //map for all fees
  //token id -> recipient -> fee
  mapping(uint256 => mapping(address => uint256)) internal _fees;
  //index for recipients (so we can loop the map)
  //token id -> addresses
  mapping(uint256 => address[]) internal _recipients;

  /**
   * @dev Returns the fee of a recipient given the token id
   */
  function getFee(uint256 tokenId, address recipient)
    public
    view
    returns(uint256)
  {
    return _fees[tokenId][recipient];
  }

  /**
   * @dev returns the total fees of a token
   */
  function getTotalFees(uint256 tokenId) public view returns(uint256) {
    return _totalFees[tokenId];
  }

  /**
   * @dev Sets a fee that will be collected during the exchange method
   */
  function _setFee(uint256 tokenId, address recipient, uint256 fee) internal {
    require(fee > 0, 'Allocation should be more than 0');
    require(
      fee <= TOTAL_ALLOWABLE_FEES,
      'Allocation should not be more than 100% where 10000 equals 100.00%'
    );
    require(
      (_totalFees[tokenId] + fee) <= TOTAL_ALLOWABLE_FEES,
      'Exceeds total fees'
    );

    //if no recipient
    if (_fees[tokenId][recipient] == 0) {
      //add recipient
      _recipients[tokenId].push(recipient);
      //map fee
      _fees[tokenId][recipient] = fee;
      //add to total fee
      _totalFees[tokenId] += fee;
    //else there's already an existing recipient
    } else {
      //remove old fee from total fee
      _totalFees[tokenId] -= _fees[tokenId][recipient];
      //map fee
      _fees[tokenId][recipient] = fee;
      //add to total fee
      _totalFees[tokenId] += fee;
    }
  }

  /**
   * @dev Removes a fee
   */
  function _removeFee(uint256 tokenId, address recipient) internal {
    require(_fees[tokenId][recipient] != 0, 'Recipient has no fees');
    //deduct total fees
    _totalFees[tokenId] -= _fees[tokenId][recipient];
    //remove fees from the map
    delete _fees[tokenId][recipient];
    //Tricky logic to remove an element from an array...
    //if there are at least 2 elements in the array,
    if (_recipients[tokenId].length > 1) {
      //find the recipient
      for (uint i = 0; i < _recipients[tokenId].length; i++) {
        if(_recipients[tokenId][i] == recipient) {
          //move the last element to the deleted element
          _recipients[tokenId][i] = _recipients[tokenId][_recipients[tokenId].length - 1];
          break;
        }
      }
    }

    //either way remove the last element
    _recipients[tokenId].pop();
  }
}
