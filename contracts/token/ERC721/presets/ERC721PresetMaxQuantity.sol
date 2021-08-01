// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//custom abstract implementation of ERC721
//used to set a max quantity upon contract creation
import "./../extensions/ERC721MaxQuantity.sol";

contract ERC721PresetMaxQuantity is ERC721MaxQuantity {
  /**
   * @dev Constructor function
   */
  constructor (
    string memory _name,
    string memory _symbol,
    uint256 _maxQuantity
  )
  ERC721(_name, _symbol)
  ERC721MaxQuantity(_maxQuantity)
  {}

  //no methods or configuration needs to be added for this preset

  /**
   * @dev Mint and transfer considering max quantity
   */
  function mint(address recipient) public returns (uint256) {
    _incrementTokenId();

    uint256 tokenId = currentTokenId();
    _mint(recipient, tokenId);

    return tokenId;
  }
}
