// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//A simple way to get a counter that can only be incremented or decremented.
//Very useful for ID generation, counting contract activity, among others
//usage: Counters.Counter private ids
//       ids.increment()
//       ids.current()
//see: https://docs.openzeppelin.com/contracts/3.x/api/utils#Counters
import "@openzeppelin/contracts/utils/Counters.sol";

//implementation of ERC721
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

//custom abstract implementation of ERC721
//used to set secondary transfer fees
import "./../extensions/ERC721TransferFees.sol";

contract ERC721PresetTransferFees is ERC721, ERC721TransferFees {
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIds;

  //in this mock only the contract owner can add a fee
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
    string memory _symbol
  ) ERC721(_name, _symbol) {
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

  /**
   * @dev Basic mint and transfer
   */
  function mint(address recipient) public returns (uint256) {
    _tokenIds.increment();

    uint256 tokenId = _tokenIds.current();
    _mint(recipient, tokenId);

    return tokenId;
  }
}
