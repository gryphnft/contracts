// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//custom abstract implementation of ERC2309
import "./../extensions/ERC2309CollectionDrops.sol";
//custom abstract implementation of ERC2309
import "./../extensions/ERC2309CollectionExchange.sol";
//custom abstract implementation of ERC2309
import "./../extensions/ERC2309Burnable.sol";
//custom abstract implementation of ERC2309
import "./../extensions/ERC2309Pausable.sol";

contract ERC2309PresetMarketplace is
  ERC2309Burnable,
  ERC2309Pausable,
  ERC2309CollectionDrops,
  ERC2309CollectionExchange
{
  //in only the contract owner can add a fee
  address admin;

  modifier onlyAdmin {
    require(
      _msgSender() == admin,
      "ERC2309PresetMarketplace: Restricted method access to only the contract admin"
    );
    _;
  }

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
  {
    admin = _msgSender();
  }

  /**
   * @dev Defines a collection
   */
  function createCollection(
    string memory uri,
    uint256 allowance
  ) public virtual onlyAdmin {
    _createCollection(uri, allowance);
  }

  /**
   * @dev Defines a redeemable collection
   */
  function dropCollection(
    string memory uri,
    uint256 allowance,
    bytes32 merkleroot
  ) public virtual onlyAdmin {
    _drop(uri, allowance, merkleroot);
  }

  /**
   * @dev Collection minting factory
   */
  function mintCollection(uint256 collectionId, address recipient)
    public
    virtual
    onlyAdmin
  {
    _mintCollection(collectionId, recipient);
  }

  /**
   * @dev Collection minting factory
   */
  function mintCollectionBatch(
    uint256 collectionId,
    address[] memory recipients
  ) public virtual onlyAdmin {
    _mintCollectionBatch(collectionId, recipients);
  }

  /**
   * @dev Allows anyone to generally redeem anyone's token
   * who ever does it pays the gas fees though :)
   */
  function redeem(
    uint256 collectionId,
    uint256 key,
    address recipient,
    bytes32[] calldata proof
  ) public virtual {
    _redeem(collectionId, key, recipient, proof);
  }

  /**
   * @dev Sets a fee that will be collected during the exchange method
   */
  function setFee(
    uint256 collectionId,
    address recipient,
    uint256 fee
  ) public virtual onlyAdmin {
    _setFee(collectionId, recipient, fee);
  }

  /**
   * @dev Removes a fee
   */
  function removeFee(uint256 collectionId, address recipient)
    public
    virtual
    onlyAdmin
  {
    _removeFee(collectionId, recipient);
  }

  /**
   * @dev Pauses all token transfers.
   *
   * See {ERC2309Pausable} and {Pausable-_pause}.
   *
   * Requirements:
   *
   * - the caller must have the `PAUSER_ROLE`.
   */
  function pause() public virtual onlyAdmin {
    _pause();
  }

  /**
   * @dev Unpauses all token transfers.
   *
   * See {ERC2309Pausable} and {Pausable-_unpause}.
   *
   * Requirements:
   *
   * - the caller must have the `PAUSER_ROLE`.
   */
  function unpause() public virtual onlyAdmin {
    _unpause();
  }

  /**
   * @dev Resolves duplicate _beforeTokenTransfer method definition
   * between ERC2309 and ERC2309Pausable
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC2309, ERC2309Pausable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }
}
