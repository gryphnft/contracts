// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//implementation of ERC1155
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

//crypto logic for merkle trees
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

abstract contract ERC1155AirDroppable is ERC1155 {
  //token id -> merkle roots
  mapping(uint256 => bytes32) private _merkleRoots;

  function _drop(uint256 tokenId, bytes32 merkleRoot) internal {
    //use logic to make it immutable
    require(_merkleRoots[tokenId] == 0, "Merkle root is immutable");
    _merkleRoots[tokenId] = merkleRoot;
  }

  /**
   * @dev Allows recipients to generally redeem their token
   */
  function redeem(
    address recipient,
    uint256 tokenId,
    uint256 quantity,
    bytes32[] calldata proof,
    bytes memory data
  ) external {
    require(
      //this verifies that the recipient owns this token
      MerkleProof.verify(
        proof,
        _merkleRoots[tokenId],
        //this is the leaf hash
        keccak256(abi.encodePacked(recipient, tokenId, quantity))
      ),
      "Recipient does not own this token"
    );
    _mint(recipient, tokenId, quantity, data);
  }
}
