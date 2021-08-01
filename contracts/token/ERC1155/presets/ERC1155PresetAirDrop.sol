// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//custom abstract implementation of ERC721
//used to configure zero trust air drop scenario
import "./../extensions/ERC1155AirDroppable.sol";

contract ERC1155PresetAirDrop is ERC1155AirDroppable {
  //in this preset only the contract owner can add a fee
  address owner;

  modifier onlyContractOwner {
    require(
      msg.sender == owner,
      'Restricted method access to only the contract owner'
    );
    _;
  }

  constructor(string memory _uri) ERC1155(_uri) {
    owner = msg.sender;
  }

  /**
   * @dev Only the contract owner can airdrop a token
   */
  function drop(uint256 tokenId, bytes32 merkleRoot) public onlyContractOwner {
    _drop(tokenId, merkleRoot);
  }

  //minting is disabled for this preset
}
