// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//Abstract of an ERC721 managing multiple classes of tokens
import "./IERC721MultiClass.sol";

/**
 * @dev Required interface of an IERC721MultiClassDrop compliant contract.
 */
interface IERC721MultiClassDrop is IERC721MultiClass {
  /**
   * @dev Returns true if the `proof` is redeemable
   */
  function redeemable(
    uint256 classId,
    uint256 tokenId,
    address recipient,
    bytes32[] calldata proof
  ) external returns(bool);
}
