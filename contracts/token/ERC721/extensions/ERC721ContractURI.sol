// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//implementation of ERC721
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


abstract contract ERC721ContractURI is ERC721 {
  string public contractURI;

  /**
   * @dev Constructor function
   */
  constructor (string memory _uri) {
    contractURI = _uri;
  }
}
