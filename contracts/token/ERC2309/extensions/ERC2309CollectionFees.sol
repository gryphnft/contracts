// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//abstract implementation of ERC2309
//allows this contract to be treated as a token factory organized by collections
import "./ERC2309Collection.sol";

/**
 * @title ERC2309 Collection Fees
 * @dev ERC2309 Factory where percent fees can be defined per collection
 */
abstract contract ERC2309CollectionFees is ERC2309Collection {
  //10000 means 100.00%
  uint256 internal constant TOTAL_ALLOWABLE_FEES = 10000;
  //map for total fees (could be problematic if not synced)
  //collection id -> total fees
  mapping(uint256 => uint256) internal _totalCollectionFees;
  //map for all fees
  //collection id -> recipient -> fee
  mapping(uint256 => mapping(address => uint256)) internal _collectionFees;
  //index for recipients (so we can loop the map)
  //collection id -> recipients
  mapping(uint256 => address[]) internal _collectionRecipients;

  /**
   * @dev Sets a fee that will be collected during the exchange method
   */
  function _setFee(
    uint256 collectionId,
    address recipient,
    uint256 fee
  ) internal {
    require(fee > 0, 'Allocation should be more than 0');
    require(
      fee <= TOTAL_ALLOWABLE_FEES,
      'ERC2309CollectionFees: Allocation more than 100%'
    );
    require(
      (_totalCollectionFees[collectionId] + fee) <= TOTAL_ALLOWABLE_FEES,
      'ERC2309CollectionFees: Exceeds total fees'
    );

    //if no recipient
    if (_collectionFees[collectionId][recipient] == 0) {
      //add recipient
      _collectionRecipients[collectionId].push(recipient);
      //map fee
      _collectionFees[collectionId][recipient] = fee;
      //add to total fee
      _totalCollectionFees[collectionId] += fee;
    //else there's already an existing recipient
    } else {
      //remove old fee from total fee
      _totalCollectionFees[collectionId] -= _collectionFees[collectionId][recipient];
      //map fee
      _collectionFees[collectionId][recipient] = fee;
      //add to total fee
      _totalCollectionFees[collectionId] += fee;
    }
  }

  /**
   * @dev Removes a fee
   */
  function _removeFee(uint256 collectionId, address recipient) internal {
    require(
      _collectionFees[collectionId][recipient] != 0,
      'ERC2309CollectionFees: Recipient has no fees'
    );
    //deduct total fees
    _totalCollectionFees[collectionId] -= _collectionFees[collectionId][recipient];
    //remove fees from the map
    delete _collectionFees[collectionId][recipient];
    //Tricky logic to remove an element from an array...
    //if there are at least 2 elements in the array,
    if (_collectionRecipients[collectionId].length > 1) {
      //find the recipient
      for (uint i = 0; i < _collectionRecipients[collectionId].length; i++) {
        if(_collectionRecipients[collectionId][i] == recipient) {
          //move the last element to the deleted element
          _collectionRecipients[collectionId][i] = _collectionRecipients[collectionId][_collectionRecipients[collectionId].length - 1];
          break;
        }
      }
    }

    //either way remove the last element
    _collectionRecipients[collectionId].pop();
  }

  /**
   * @dev Returns the fee of a recipient given the collection id
   */
  function CollectionFee(uint256 collectionId, address recipient)
    public
    view
    returns(uint256)
  {
    return _collectionFees[collectionId][recipient];
  }

  /**
   * @dev returns the total fees of a collection
   */
  function CollectionFees(uint256 collectionId) public view returns(uint256) {
    return _totalCollectionFees[collectionId];
  }
}
