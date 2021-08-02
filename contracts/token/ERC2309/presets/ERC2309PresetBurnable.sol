// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//A simple way to get a counter that can only be incremented or decremented.
//Very useful for ID generation, counting contract activity, among others
//usage: Counters.Counter private ids
//       ids.increment()
//       ids.current()
//see: https://docs.openzeppelin.com/contracts/3.x/api/utils#Counters
import "@openzeppelin/contracts/utils/Counters.sol";

//custom abstract implementation of ERC2309
import "./../extensions/ERC2309Burnable.sol";

contract ERC2309PresetBurnable is ERC2309Burnable {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  /**
   * @dev Sets `name` and `symbol`
   */
  constructor(
    string memory tokenName,
    string memory tokenSymbol
  ) ERC2309(tokenName, tokenSymbol) {}

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
