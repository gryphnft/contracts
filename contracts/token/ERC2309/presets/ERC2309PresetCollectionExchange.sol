// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//custom abstract implementation of ERC2309
import "./../extensions/ERC2309CollectionExchange.sol";

contract ERC2309PresetCollectionExchange is ERC2309CollectionExchange {
  /**
   * @dev Sets `name` and `symbol`
   */
  constructor(
    string memory tokenName,
    string memory tokenSymbol,
    uint256 precision
  )
    ERC2309(tokenName, tokenSymbol)
    ERC2309Collection(precision)
  {}

  /**
   * @dev Defines a collection
   */
  function createCollection(
    string memory uri,
    uint256 allowance
  ) public virtual {
    _createCollection(uri, allowance);
  }

  /**
   * @dev Collection minting factory
   */
  function mintCollection(uint256 collectionId, address recipient)
    public
    virtual
  {
    _mintCollection(collectionId, recipient);
  }

  /**
   * @dev Collection minting factory
   */
  function mintCollectionBatch(
    uint256 collectionId,
    address[] memory recipients
  ) public virtual {
    _mintCollectionBatch(collectionId, recipients);
  }

  /**
   * @dev Sets a fee that will be collected during the exchange method
   */
  function setFee(
    uint256 collectionId,
    address recipient,
    uint256 fee
  ) public virtual {
    _setFee(collectionId, recipient, fee);
  }

  /**
   * @dev Removes a fee
   */
  function removeFee(uint256 collectionId, address recipient) public virtual {
    _removeFee(collectionId, recipient);
  }
}
