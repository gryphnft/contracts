// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//custom abstract implementation of ERC721
//used to allow token owners to list their tokens for sale
import "./../extensions/ERC1155Exchangable.sol";

contract ERC1155PresetExchangable is ERC1155Exchangable {
  constructor(string memory _uri) ERC1155(_uri) {}

  //no methods or configuration needs to be added for this preset

  /**
   * @dev Creates `quantity` new tokens for `to`, of token type `id`.
   */
  function mint(address to, uint256 id, uint256 quantity, bytes memory data)
    public
    virtual
  {
    _mint(to, id, quantity, data);
  }

  /**
   * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] variant of {mint}.
   */
  function mintBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public virtual {
    _mintBatch(to, ids, amounts, data);
  }
}
