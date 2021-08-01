// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//custom abstract implementation of ERC1155
//used to configure zero trust air drop scenario
import "./extensions/ERC1155AirDroppable.sol";

//custom abstract extension of ERC1155
//used to list tokens for sale and set royalties
import "./extensions/ERC1155ExchangableFees.sol";

contract ERC1155AirDrop is
  ERC1155AirDroppable,
  ERC1155ExchangableFees
{
  //in only the contract owner can add a fee
  address owner;

  modifier onlyContractOwner {
    require(
      msg.sender == owner,
      'Restricted method access to only the contract owner'
    );
    _;
  }

  /**
   * @dev Constructor function
   */
  constructor (string memory _uri) ERC1155(_uri) {
    owner = msg.sender;
  }

  /**
   * @dev Only the contract owner can airdrop a token
   */
  function drop(uint256 tokenId, bytes32 merkleRoot) public onlyContractOwner {
    _drop(tokenId, merkleRoot);
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

  //minting is disabled
}
