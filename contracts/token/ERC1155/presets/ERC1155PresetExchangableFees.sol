// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//custom abstract implementation of ERC721
//used to allow token owners to list their tokens for sale
import "./../extensions/ERC1155ExchangableFees.sol";

contract ERC1155PresetExchangableFees is ERC1155ExchangableFees {
  //in only the contract owner can add a fee
  address owner;

  modifier onlyContractOwner {
    require(msg.sender == owner, 'Restricted method access to only the contract owner');
    _;
  }

  constructor(string memory _uri) ERC1155(_uri) {
    owner = msg.sender;
  }

  /**
   * @dev Only the contract owner can add a fee
   */
  function setFee(uint256 tokenId, address payable recipient, uint256 fee)
    public
    onlyContractOwner
  {
    _setFee(tokenId, recipient, fee);
  }

  /**
   * @dev Only the contract owner can remove a fee
   */
  function removeFee(uint256 tokenId, address payable recipient)
    public
    onlyContractOwner
  {
    _removeFee(tokenId, recipient);
  }

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
