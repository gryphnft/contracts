// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//implementation of ERC721
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract ERC1155PresetVanilla is ERC1155 {
  constructor(string memory _uri)
    ERC1155(_uri)
  {}

  /**
   * @dev Creates `amount` new tokens for `to`, of token type `id`.
   */
  function mint(address to, uint256 id, uint256 amount, bytes memory data)
    public
    virtual
  {
    _mint(to, id, amount, data);
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
