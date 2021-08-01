// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//custom abstract implementation of ERC721
//used to mint tokens and assign them to recipients on deploy
import "./../extensions/ERC721PreMintable.sol";

contract ERC721PresetPreMint is ERC721PreMintable {
  /**
   * @dev Constructor function
   */
  constructor (
    string memory _name,
    string memory _symbol,
    address[] memory _recipients
  )
  ERC721(_name, _symbol)
  ERC721PreMintable(_recipients)
  {}

  //no methods or configuration needs to be added for this preset
  //minting is disabled for this preset
}
