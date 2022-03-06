// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//IERC721MultiClassData interface
import "./../interfaces/IERC721MultiClassData.sol";

/**
 * @dev Abstract extension of ERC721MultiClass that allows a
 * class to reference data (like a uri)
 */
abstract contract ERC721MultiClassData is IERC721MultiClassData {
  //mapping of `classId` to `data`
  mapping(uint256 => string) private _references;

  /**
   * @dev Returns the reference of `classId`
   */
  function referenceOf(uint256 classId)
    public view override returns(string memory)
  {
    return _references[classId];
  }

  /**
   * @dev References `data` to `classId`
   */
  function _referenceClass(uint256 classId, string memory data)
    internal virtual
  {
    require(
      bytes(_references[classId]).length == 0,
      "ERC721MultiClass: Class is already referenced"
    );
    _references[classId] = data;
  }
}
