// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//custom abstract implementation of ERC721
//used to configure zero trust air drop scenario
import "./../extensions/ERC721AirDroppable.sol";

contract ERC721PresetAirDrop is ERC721AirDroppable {
  /**
   * @dev Constructor function
   */
  constructor (
    string memory _name,
    string memory _symbol,
    bytes32 merkleroot
  )
  ERC721(_name, _symbol)
  ERC721AirDroppable(merkleroot)
  {}
}
