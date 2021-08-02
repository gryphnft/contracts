// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//A simple way to get a counter that can only be incremented or decremented.
//Very useful for ID generation, counting contract activity, among others
//usage: Counters.Counter private ids
//       ids.increment()
//       ids.current()
//see: https://docs.openzeppelin.com/contracts/3.x/api/utils#Counters
import "@openzeppelin/contracts/utils/Counters.sol";

//implementation of ERC2309
import "./../ERC2309.sol";

abstract contract ERC2309Collection is ERC2309 {
  using Counters for Counters.Counter;
  Counters.Counter public LastCollectionId;

  //ex. precision 4 is 0.0000
  //10000001 = 1000.0001 vs 10000001 = 10.000001
  uint256 immutable internal _collectionPrecision;
  //collection id -> uri
  mapping(uint256 => string) private _collectionURIs;
  //collection id -> last token id
  mapping(uint256 => uint256) private _collectionLast;
  //collection id -> allowance
  mapping(uint256 => uint256) private _collectionAllowance;

  /**
   * @dev Constructor function
   */
  constructor (uint256 precision) {
    _collectionPrecision = precision;
  }

  /**
   * @dev Defines a collection
   */
  function _createCollection(string memory uri, uint256 allowance)
    internal
    returns(uint256)
  {
    //allowance cannot be more than the precision allowance
    //to get the precision allowance of precision 4 is
    //(10 ** 4) - 1 = 10000 - 1 = 9999
    require(
      allowance <= ((10 ** _collectionPrecision) - 1),
      "Allowance more than the max allowance"
    );

    //get the collection id
    LastCollectionId.increment();
    uint256 collectionId = LastCollectionId.current();

    //set the allowance
    _collectionAllowance[collectionId] = allowance;
    //set the collection uri
    _collectionURIs[collectionId] = uri;

    return collectionId;
  }

  /**
   * @dev Collection minting factory
   */
  function _mintCollection(uint256 collectionId, address recipient)
    internal
    returns(uint256)
  {
    require(
      _collectionAllowance[collectionId] > 0,
      "ERC2309Collection: Collection does not exist"
    );

    //calculate the zero id
    //to get the zero id of precision 4 of collection id 22
    //(10 ** 4) * 22 = (10000 * 22) = 220000
    uint256 zeroId = (10 ** _collectionPrecision) * collectionId;
    //determine last id
    uint256 lastId = _collectionLast[collectionId];
    //if no last
    if (lastId == 0) {
      //make it the zero id
      lastId = zeroId;
    }

    //determine the token id
    uint256 tokenId = lastId + 1;
    //determine the allowance
    //if zero id is 220000 and allowance is 1000 the allowance should be 221000
    uint256 allowance = zeroId + _collectionAllowance[collectionId];
    require(
      tokenId <= allowance,
      "ERC2309Collection: Minting exceeded for this collection"
    );

    //now mint
    _safeMint(recipient, tokenId);
    //update the last id
    _collectionLast[collectionId] = tokenId;

    return tokenId;
  }

  /**
   * @dev Collection minting factory
   */
  function _mintCollectionBatch(
    uint256 collectionId,
    address[] memory recipients
  ) internal returns(uint256) {
    //calculate the zero id
    //to get the zero id of precision 4 of collection id 22
    //(10 ** 4) * 22 = (10000 * 22) = 220000
    uint256 zeroId = (10 ** _collectionPrecision) * collectionId;
    //determine last id
    uint256 lastId = _collectionLast[collectionId];
    //if no last
    if (lastId == 0) {
      //make it the zero id
      lastId = zeroId;
    }

    //ex. from token id 2 and 3 recipients, the to token should be 4 [2, 3, 4]
    uint256 fromTokenId = lastId + 1;
    uint256 toTokenId = fromTokenId + recipients.length - 1;
    //determine the allowance
    //if zero id is 220000 and allowance is 1000 the allowance should be 221000
    uint256 allowance = zeroId + _collectionAllowance[collectionId];
    require(
      toTokenId <= allowance,
      "ERC2309Collection: Minting exceeded for this collection"
    );

    //now mint
    _mintBatchEnumerate(fromTokenId, recipients);
    //update the last id
    _collectionLast[collectionId] = toTokenId;

    return toTokenId;
  }

  /**
   * @dev Returns a collection's URI
   */
  function CollectionURI(uint256 collectionId) external view returns(string memory) {
    return _collectionURIs[collectionId];
  }

  /**
   * @dev Returns a collection's URI
   */
  function CollectionAllowance(uint256 collectionId)
    external
    view
    returns(uint256)
  {
    return _collectionAllowance[collectionId];
  }

  /**
   * @dev Returns a collection id given the token id
   */
  function TokenCollection(uint256 tokenId) public view returns(uint256) {
    //to get the collection id 22 from the token id 220034 of precision 4
    //220034 / (10 ** 4) = 220034 / 10000 = 22 (solidity automatically floors)
    return tokenId / (10 ** _collectionPrecision);
  }

  /**
   * @dev Returns the last token id for a collection
   */
  function LastCollectionToken(uint256 collectionId)
    public
    view
    returns(uint256)
  {
    return _collectionLast[collectionId];
  }
}
