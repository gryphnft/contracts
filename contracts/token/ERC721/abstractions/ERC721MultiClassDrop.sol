// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//IERC721MultiClassDrop interface
import "./../interfaces/IERC721MultiClassDrop.sol";

//crypto logic for merkle trees
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @dev Abstract extension of ERC721MultiClass that
 * allows air drops for all classes
 */
abstract contract ERC721MultiClassDrop is IERC721MultiClassDrop {
  //mapping of `classId` -> root
  mapping(uint256 => bytes32) private _root;

  /**
   * @dev Returns true if the `proof` is redeemable
   */
  function redeemable(
    uint256 classId,
    uint256 tokenId,
    address recipient,
    bytes32[] calldata proof
  ) public virtual override returns(bool) {
    //this verifies that the recipient owns this token
    return MerkleProof.verify(
      proof,
      _root[classId],
      //this is the leaf hash
      keccak256(abi.encodePacked(classId, tokenId, recipient))
    );
  }

  /**
   * @dev Defines a redeemable class
   */
  function _drop(uint256 classId, bytes32 merkleroot) internal virtual {
    //save the merkle root
    _root[classId] = merkleroot;
  }
}
