// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./../ERC2309.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @title ERC2309 Burnable Token
 * @dev ERC2309 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC2309Burnable is Context, ERC2309 {
  /**
   * @dev Burns `tokenId`. See {ERC721-_burn}.
   *
   * Requirements:
   *
   * - The caller must own `tokenId` or be an approved operator.
   */
  function burn(uint256 tokenId) public virtual {
    //solhint-disable-next-line max-line-length
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      "ERC2309Burnable: caller is not owner nor approved"
    );
    _burn(tokenId);
  }
}
