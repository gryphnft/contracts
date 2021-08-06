// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//implementation of ERC721 Non-Fungible Token Standard
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
//implementation of ERC721 where tokens can be irreversibly burned (destroyed).
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
//implementation of ERC721 where transers can be paused
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
//Abstract extension of ERC721MultiClass that allows a class to reference data (like a uri)
import "./../abstractions/ERC721MultiClassData.sol";
//Abstract extension of ERC721MultiClass that allows tokens to be listed and exchanged considering royalty fees
import "./../abstractions/ERC721MultiClassExchange.sol";
//Abstract extension of ERC721MultiClass that manages class sizes
import "./../abstractions/ERC721MultiClassSize.sol";
//For verifying messages in lazyMint
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract ERC721Marketplace is
  ERC721,
  ERC721Burnable,
  ERC721Pausable,
  ERC721MultiClassData,
  ERC721MultiClassExchange,
  ERC721MultiClassSize
{
  //in only the contract owner can add a fee
  address private _admin;

  modifier onlyAdmin {
    require(
      _msgSender() == _admin,
      "ERC721Marketplace: Restricted method access to only the admin"
    );
    _;
  }

  /**
   * @dev Constructor function
   */
  constructor (string memory _name, string memory _symbol)
    ERC721(_name, _symbol)
  {
    _admin = _msgSender();
  }

  /**
   * @dev References `classId` to `data` and `size`
   */
  function register(uint256 classId, uint256 size, string memory uri)
    external virtual onlyAdmin
  {
    _referenceClass(classId, uri);
    //if size was set, fix it. Setting a zero size means no limit.
    if (size > 0) {
      _fixClassSize(classId, size);
    }
  }

  /**
   * @dev Sets a fee that will be collected during the exchange method
   */
  function allocate(uint256 classId, address recipient, uint256 fee)
    external virtual onlyAdmin
  {
    _allocateFee(classId, recipient, fee);
  }

  /**
   * @dev Removes a fee
   */
  function deallocate(uint256 classId, address recipient)
    external virtual onlyAdmin
  {
    _deallocateFee(classId, recipient);
  }

  /**
   * @dev Allows anyone to self mint a token
   */
  function lazyMint(
    uint256 classId,
    uint256 tokenId,
    address recipient,
    bytes calldata proof
  ) external virtual {
    //check size
    require(!classFilled(classId), "ERC721Marketplace: Class filled.");
    //make sure the admin signed this off
    require(
      ECDSA.recover(
        ECDSA.toEthSignedMessageHash(
          keccak256(
            abi.encodePacked(classId, tokenId, recipient)
          )
        ),
        proof
      ) == _admin,
      "ERC721Marketplace: Invalid proof."
    );

    //mint first and wait for errors
    _safeMint(recipient, tokenId);
    //then classify it
    _classify(tokenId, classId);
    //then increment supply
    _addClassSupply(classId, 1);
  }

  /**
   * @dev Mints `tokenId`, classifies it as `classId` and transfers to `recipient`
   */
  function mint(uint256 classId, uint256 tokenId, address recipient)
    external virtual onlyAdmin
  {
    //check size
    require(!classFilled(classId), "ERC721Marketplace: Class filled.");
    //mint first and wait for errors
    _safeMint(recipient, tokenId);
    //then classify it
    _classify(tokenId, classId);
    //then increment supply
    _addClassSupply(classId, 1);
  }

  /**
   * @dev Lists `tokenId` on the order book for `amount` in wei.
   */
  function list(uint256 tokenId, uint256 amount) external virtual {
    _list(tokenId, amount);
  }

  /**
   * @dev Removes `tokenId` from the order book.
   */
  function delist(uint256 tokenId) external virtual {
    _delist(tokenId);
  }

  /**
   * @dev Allows for a sender to exchange `tokenId` for the listed amount
   */
  function exchange(uint256 tokenId) external virtual override payable {
    _exchange(tokenId, msg.value);
  }

  /**
   * @dev Pauses all token transfers.
   *
   * See {ERC721Pausable} and {Pausable-_pause}.
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
   * See {ERC721Pausable} and {Pausable-_unpause}.
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
   * between ERC721 and ERC721Pausable
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721, ERC721Pausable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }
}
