// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//abstract implementation of ERC2309
//allows this contract to be treated as a token factory organized by collections
import "./ERC2309Collection.sol";

//crypto logic for merkle trees
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title ERC2309 Collection Based Air Drops
 * @dev ERC2309 Factory where merkle drops are attached per collection
 */
abstract contract ERC2309CollectionDrops is ERC2309Collection {
  //collection id -> root
  mapping(uint256 => bytes32) private _collectionRoots;

  /**
   * @dev Defines a redeemable collection
   */
  function _drop(
    string memory uri,
    uint256 allowance,
    bytes32 merkleroot
  ) internal returns(uint256) {
    //create the collection first to see if there are any errors
    uint256 collectionId = _createCollection(uri, allowance);

    //next save the merkle root
    _collectionRoots[collectionId] = merkleroot;

    return collectionId;
  }

  /**
   * @dev Allows anyone to generally redeem anyone's token
   */
  function _redeem(
    uint256 collectionId,
    uint256 key,
    address recipient,
    bytes32[] calldata proof
  ) internal returns(uint256) {
    //error if the proof is not verified
    require(
      //this verifies that the recipient owns this token
      MerkleProof.verify(
        proof,
        _collectionRoots[collectionId],
        //this is the leaf hash
        keccak256(abi.encodePacked(collectionId, key, recipient))
      ),
      "ERC2309CollectionDrops: Recipient does not own this token"
    );
    return _mintCollection(collectionId, recipient);
  }
}
