// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//abstract implementation of ERC721
//used to allow destruction of an owned token (never to return)
//usage: burn(tokenId)
//see: https://docs.openzeppelin.com/contracts/4.x/api/token/erc721#ERC721Burnable
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

//custom abstract extension of ERC721
//used to add a contract URI on instantiation
import "./extensions/ERC721ContractURI.sol";

//custom abstract implementation of ERC721
//used to configure zero trust air drop scenario
import "./extensions/ERC721AirDroppable.sol";

//custom abstract extension of ERC721
//used to list tokens for sale and set royalties
import "./extensions/ERC721ExchangableFees.sol";

contract ERC721AirDrop is
  ERC721Burnable,
  ERC721ContractURI,
  ERC721AirDroppable,
  ERC721ExchangableFees
{
  //in only the contract owner can add a fee
  address owner;

  modifier onlyContractOwner {
    require(msg.sender == owner, 'Restricted method access to only the contract owner');
    _;
  }

  /**
   * @dev Constructor function
   */
  constructor (
    string memory _name,
    string memory _symbol,
    string memory _uri,
    bytes32 merkleroot
  )
  ERC721(_name, _symbol)
  ERC721ContractURI(_uri)
  ERC721AirDroppable(merkleroot)
  {
    owner = msg.sender;
  }

  /**
   * @dev Only the contract owner can add a fee
   */
  function setFee(address payable recipient, uint256 fee)
    public
    onlyContractOwner
  {
    _setFee(recipient, fee);
  }

  /**
   * @dev Only the contract owner can remove a fee
   */
  function removeFee(address payable recipient)
    public
    onlyContractOwner
  {
    _removeFee(recipient);
  }
}
