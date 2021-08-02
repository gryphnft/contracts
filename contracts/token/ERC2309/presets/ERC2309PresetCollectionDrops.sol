// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//custom abstract implementation of ERC2309
import "./../extensions/ERC2309CollectionDrops.sol";

contract ERC2309PresetCollectionDrops is ERC2309CollectionDrops {
  /**
   * @dev Sets `name` and `symbol`
   */
  constructor(
    string memory tokenName,
    string memory tokenSymbol,
    uint256 precision
  )
    ERC2309(tokenName, tokenSymbol)
    ERC2309Collection(precision)
  {}

  /**
   * @dev Defines a redeemable collection
   */
  function dropCollection(
    string memory uri,
    uint256 allowance,
    bytes32 merkleroot
  ) public virtual {
    _drop(uri, allowance, merkleroot);
  }

  /**
   * @dev Allows anyone to generally redeem anyone's token
   * who ever does it pays the gas fees though :)
   */
  function redeem(
    uint256 collectionId,
    uint256 key,
    address recipient,
    bytes32[] calldata proof
  ) public virtual {
    _redeem(collectionId, key, recipient, proof);
  }
}
