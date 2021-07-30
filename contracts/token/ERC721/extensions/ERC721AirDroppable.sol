// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//implementation of ERC721
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

//crypto logic for merkle trees
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

abstract contract ERC721AirDroppable is ERC721 {
  bytes32 immutable public root;

  /**
   * @dev Constructor function
   */
  constructor (bytes32 merkleroot) {
    root = merkleroot;
  }

  /**
   * @dev Allows recipients to generally redeem their token
   */
  function redeem(uint256 tokenId, address recipient, bytes32[] calldata proof)
    external
  {
    require(
      //this verifies that the recipient owns this token
      MerkleProof.verify(
        proof,
        root,
        //this is the leaf hash
        keccak256(abi.encodePacked(tokenId, recipient))
      ),
      "Recipient does not own this token"
    );
    _safeMint(recipient, tokenId);
  }
}
