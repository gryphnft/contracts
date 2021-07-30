// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//implementation of ERC721
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

abstract contract ERC721PreMintable is ERC721 {
  /**
   * @dev Constructor function
   */
  constructor (address[] memory _recipients) {
    for (uint i = 0; i < _recipients.length; i++)  {
      _mint(_recipients[i], i + 1);
    }
  }
}
