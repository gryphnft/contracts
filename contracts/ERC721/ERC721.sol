// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

error BalanceQueryZeroAddress();
error ExistentToken();
error NonExistentToken();
error ApprovalToCurrentOwner();
error ApprovalOwnerIsOperator();
error NotOwnerOrApproved();
error NotERC721Receiver();
error TransferToZeroAddress();
error InvalidAmount();
error ERC721ReceiverNotReceived();
error TransferFromNotOwner();

abstract contract ERC721 is 
  ContextUpgradeable, 
  ERC165Upgradeable, 
  IERC721Upgradeable, 
  IERC721MetadataUpgradeable 
{
  using AddressUpgradeable for address;
  using StringsUpgradeable for uint256;

  // ============ Storage ============

  // Total supply
  uint256 private _totalSupply;

  // Mapping from token ID to owner address
  mapping(uint256 => address) private _owners;
  // Mapping owner address to token count
  mapping(address => uint256) private _balances;

  // Mapping from token ID to approved address
  mapping(uint256 => address) private _tokenApprovals;
  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  // ============ Modifiers ============

  modifier isToken(uint256 tokenId) {
    //make sure there is a product
    if (!_exists(tokenId)) revert NonExistentToken();
    _;
  }

  modifier isNotToken(uint256 tokenId) {
    //make sure there is a product
    if (_exists(tokenId)) revert ExistentToken();
    _;
  }

  // ============ Read Methods ============

  /**
   * @dev See {IERC721-balanceOf}.
   */
  function balanceOf(address owner) 
    public view virtual override returns(uint256) 
  {
    if (owner == address(0)) revert BalanceQueryZeroAddress();
    return _balances[owner];
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId) 
    public view virtual override isToken(tokenId) returns(address) 
  {
    return _owners[tokenId];
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) 
    public 
    view 
    virtual 
    override(ERC165Upgradeable, IERC165Upgradeable) 
    returns(bool) 
  {
    return
      interfaceId == type(IERC721Upgradeable).interfaceId ||
      interfaceId == type(IERC721Upgradeable).interfaceId ||
      super.supportsInterface(interfaceId);
  }
  
  /**
   * @dev Shows the overall amount of tokens generated in the contract
   */
  function totalSupply() public virtual view returns (uint256) {
    return _totalSupply;
  }

  // ============ Approval Methods ============

  /**
   * @dev See {IERC721-approve}.
   */
  function approve(address to, uint256 tokenId) public virtual override {
    address owner = ERC721.ownerOf(tokenId);
    if (to == owner) revert ApprovalToCurrentOwner();

    address sender = _msgSender();
    if (sender != owner && !isApprovedForAll(owner, sender)) 
      revert ApprovalToCurrentOwner();

    _approve(to, tokenId, owner);
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function getApproved(uint256 tokenId) 
    public view virtual override isToken(tokenId) returns(address) 
  {
    return _tokenApprovals[tokenId];
  }

  /**
   * @dev See {IERC721-isApprovedForAll}.
   */
  function isApprovedForAll(address owner, address operator) 
    public view virtual override returns (bool) 
  {
    return _operatorApprovals[owner][operator];
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved) 
    public virtual override 
  {
    _setApprovalForAll(_msgSender(), operator, approved);
  }

  /**
   * @dev Approve `to` to operate on `tokenId`
   *
   * Emits a {Approval} event.
   */
  function _approve(address to, uint256 tokenId, address owner) 
    internal virtual 
  {
    _tokenApprovals[tokenId] = to;
    emit Approval(owner, to, tokenId);
  }

  /**
   * @dev Returns whether `spender` is allowed to manage `tokenId`.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function _isApprovedOrOwner(
      address spender, 
      uint256 tokenId, 
      address owner
  ) internal view virtual returns(bool) {
    return spender == owner 
      || getApproved(tokenId) == spender 
      || isApprovedForAll(owner, spender);
  }

  /**
   * @dev Approve `operator` to operate on all of `owner` tokens
   *
   * Emits a {ApprovalForAll} event.
   */
  function _setApprovalForAll(
    address owner,
    address operator,
    bool approved
  ) internal virtual {
    if (owner == operator) revert ApprovalOwnerIsOperator();
    _operatorApprovals[owner][operator] = approved;
    emit ApprovalForAll(owner, operator, approved);
  }

  // ============ Transfer Methods ============

  /**
   * @dev See {IERC721-transferFrom}.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    _transfer(from, to, tokenId);
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    safeTransferFrom(from, to, tokenId, "");
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public virtual override {
    _safeTransfer(from, to, tokenId, _data);
  }
  
  /**
   * @dev Burns `tokenId`. See {ERC721B-_burn}.
   *
   * Requirements:
   *
   * - The caller must own `tokenId` or be an approved operator.
   */
  function _burn(uint256 tokenId) internal virtual {
    address owner = ERC721.ownerOf(tokenId);

    if (!_isApprovedOrOwner(_msgSender(), tokenId, owner)) 
      revert NotOwnerOrApproved();

    _beforeTokenTransfer(owner, address(0), tokenId);

    // Clear approvals
    _approve(address(0), tokenId, owner);

    unchecked {
      _owners[tokenId] = address(0);
      _balances[owner] -= 1;
      _totalSupply--;
    }

    emit Transfer(owner, address(0), tokenId);
  }

  /**
   * @dev Internal function to invoke {IERC721Receiver-onERC721Received} 
   * on a target address. The call is not executed if the target address 
   * is not a contract.
   */
  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) private returns (bool) {
    try IERC721ReceiverUpgradeable(to).onERC721Received(
      _msgSender(), from, tokenId, _data
    ) returns (bytes4 retval) {
      return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
    } catch (bytes memory reason) {
      if (reason.length == 0) {
        revert NotERC721Receiver();
      } else {
        assembly {
          revert(add(32, reason), mload(reason))
        }
      }
    }
  }

  /**
   * @dev Returns whether `tokenId` exists.
   *
   * Tokens can be managed by their owner or approved accounts via 
   * {approve} or {setApprovalForAll}.
   *
   * Tokens start existing when they are minted (`_mint`),
   * and stop existing when they are burned (`_burn`).
   */
  function _exists(uint256 tokenId) internal view virtual returns (bool) {
    return _owners[tokenId] != address(0);
  }

  /**
   * @dev Mints `tokenId` and transfers it to `to`.
   *
   * WARNING: Usage of this method is discouraged, use {_safeMint} 
   * whenever possible
   *
   * Requirements:
   *
   * - `tokenId` must not exist.
   * - `to` cannot be the zero address.
   *
   * Emits a {Transfer} event.
   */
  function _mint(
    address to,
    uint256 tokenId,
    bytes memory _data,
    bool safeCheck
  ) internal virtual isNotToken(tokenId) {
    if (to == address(0)) revert TransferToZeroAddress();

    _beforeTokenTransfer(address(0), to, tokenId);

    _balances[to] += 1;
    _owners[tokenId] = to;
    _totalSupply++;

    //if do safe check
    if (safeCheck 
      && to.isContract() 
      && !_checkOnERC721Received(address(0), to, tokenId, _data)
    ) revert ERC721ReceiverNotReceived();

    emit Transfer(address(0), to, tokenId);
  }

  /**
   * @dev Safely mints `tokenId` and transfers it to `to`.
   *
   * Requirements:
   *
   * - `tokenId` must not exist.
   * - If `to` refers to a smart contract, it must implement 
   *   {IERC721Receiver-onERC721Received}, which is called upon a 
   *   safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function _safeMint(address to, uint256 amount) internal virtual {
    _safeMint(to, amount, "");
  }

  /**
   * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], 
   * with an additional `data` parameter which is forwarded in 
   * {IERC721Receiver-onERC721Received} to contract recipients.
   */
  function _safeMint(
    address to,
    uint256 amount,
    bytes memory _data
  ) internal virtual {
    _mint(to, amount, _data, true);
  }

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`, checking 
   * first that contract recipients are aware of the ERC721 protocol to 
   * prevent tokens from being forever locked.
   *
   * `_data` is additional data, it has no specified format and it is 
   * sent in call to `to`.
   *
   * This internal function is equivalent to {safeTransferFrom}, and can 
   * be used to e.g.
   * implement alternative mechanisms to perform token transfer, such as 
   * signature-based.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If `to` refers to a smart contract, it must implement 
   *   {IERC721Receiver-onERC721Received}, which is called upon a 
   *   safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function _safeTransfer(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) internal virtual {
    _transfer(from, to, tokenId);
    if (to.isContract() 
      && !_checkOnERC721Received(from, to, tokenId, _data)
    ) {
        revert ERC721ReceiverNotReceived();
    }
  }

  /**
   * @dev Transfers `tokenId` from `from` to `to`. As opposed to 
   * {transferFrom}, this imposes no restrictions on msg.sender.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `tokenId` token must be owned by `from`.
   *
   * Emits a {Transfer} event.
   */
  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {
    if (to == address(0)) revert TransferToZeroAddress();
    //get owner
    address owner = ERC721.ownerOf(tokenId);
    //owner should be the `from`
    if (from != owner) revert TransferFromNotOwner();
    if (!_isApprovedOrOwner(_msgSender(), tokenId, owner)) 
      revert NotOwnerOrApproved();

    _beforeTokenTransfer(from, to, tokenId);

    // Clear approvals from the previous owner
    _approve(address(0), tokenId, from);

    unchecked {
      //this is the situation when _owners are normalized
      _balances[to] += 1;
      _balances[from] -= 1;
      _owners[tokenId] = to;
    }

    emit Transfer(from, to, tokenId);
  }

  // ============ TODO Methods ============

  /**
   * @dev Hook that is called before a set of serially-ordered token ids 
   * are about to be transferred. This includes minting.
   *
   * startTokenId - the first token id to be transferred
   * amount - the amount to be transferred
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s `tokenId` 
   *   will be transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {}
}