// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../ERC721/ERC721Base.sol";
import "../utils/Base64.sol";

//
//     ______  _______   ____  ____   _______  ____  ____  
//   .' ___  ||_   __ \ |_  _||_  _| |_   __ \|_   ||   _| 
//  / .'   \_|  | |__) |  \ \  / /     | |__) | | |__| |   
//  | |   ____  |  __ /    \ \/ /      |  ___/  |  __  |   
//  \ `.___]  |_| |  \ \_  _|  |_  _  _| |_    _| |  | |_  
//   `._____.'|____| |___||______|(_)|_____|  |____||____| 
//
//  CROSS CHAIN NFT MARKETPLACE
//  https://www.gry.ph/
//

// ============ Errors ============

error InvalidName();
error InvalidAmountSent();

contract GryphNamespaces is ERC721Base, Ownable, ReentrancyGuard {
  using Counters for Counters.Counter;
  // ============ Immutable ============

  uint256[] public PRICES = [
    0.192 ether, //4 letters
    0.096 ether, //5 letters
    0.048 ether, //6 letters 
    0.024 ether, //7 letters
    0.012 ether, //8 letters
    0.006 ether, //9 letters
    0.003 ether  //10 letters or more
  ];

  string private DESCRIPTION = "GRY.PH is a cross chain NFT marketplace. Holders of this collection namespace have the rights to customize its contents";

  // ============ Storage ============

  Counters.Counter private _tokenIdTracker;
  
  //mapping of token id to name
  mapping(uint256 => string) public tokenName;

  //mapping of name to token id
  mapping(string => uint256) public reserved;

  //mapping of names to blacklist
  mapping(string => bool) public blacklisted;

  string private _baseURI;

  // ============ Deploy ============

  /**
   * @dev Sets the erc721 required fields
   */
  constructor() ERC721Base("Gryph Namespaces", "GNS") {}

  // ============ Read Methods ============

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId) public view returns(string memory) {
    if(!_exists(tokenId)) revert NonExistentToken();
    string memory name = tokenName[tokenId];
    return string(
      abi.encodePacked(
        "data:application/json;base64,",
        Base64.encode(bytes(abi.encodePacked(
          '{"name":"', name, '.gry.ph",',
          '"description": "', DESCRIPTION, '",',
          '"animation_url": "', _baseURI, '/namespace?', name, '",',
          '"image":"', _baseURI, '/gryph-water.svg"}'
        )))
      )
    );
  }

  // ============ Write Methods ============

  /**
   * @dev Allows anyone to buy a name
   */
  function buy(address recipient, string memory name) external payable {
    //get the length of name
    uint256 length = bytes(name).length;
    //disallow length length less than 4
    if (length < 4) revert InvalidName();
    //get index
    uint256 index = length - 4;
    if (index >= PRICES.length) {
      index = PRICES.length - 1;
    }
    //check price
    if (msg.value < PRICES[index]) revert InvalidAmountSent();
    //okay to mint
    _nameMint(recipient, name);
  }

  // ============ Admin Methods ============

  /**
   * @dev Disallows `names`
   */
  function blacklist(string[] memory names) public onlyOwner {
    for (uint256 i = 0; i < names.length; i++) {
      //we can't blacklist if the name is already reserved
      if (reserved[names[i]] > 0) revert InvalidName();
      blacklisted[names[i]] = true;
    }
  }

  /**
   * @dev Allow admin to mint a name without paying (used for airdrops)
   */
  function mint(address recipient, string memory name) public onlyOwner {
    _nameMint(recipient, name);
  }

  /**
   * @dev Updates the base token uri
   */
  function setBaseURI(string memory uri) public onlyOwner {
    _baseURI = uri;
  }

  /**
   * @dev Allow `names`
   */
  function whitelist(string[] memory names) public onlyOwner {
    for (uint256 i = 0; i < names.length; i++) {
      blacklisted[names[i]] = false;
    }
  }

  /**
   * @dev Sends the entire contract balance to a `recipient`
   */
  function withdraw(address recipient) 
    external virtual nonReentrant onlyOwner
  {
    Address.sendValue(payable(recipient), address(this).balance);
  }

  /**
   * @dev This contract should not hold any tokens in the first place. 
   * This method exists to transfer out tokens funds.
   */
  function withdraw(IERC20 erc20, address recipient, uint256 amount) 
    external virtual nonReentrant onlyOwner
  {
    SafeERC20.safeTransfer(erc20, recipient, amount);
  }

  // ============ Internal Methods ============

  function _nameMint(address recipient, string memory name) internal {
    //already reserved or blacklisted
    if (reserved[name] > 0 || blacklisted[name]) revert InvalidName();
    // We cannot just use balanceOf to create the new tokenId because tokens
    // can be burned (destroyed), so we need a separate counter.
    // first increment
    _tokenIdTracker.increment();
    //get token id
    uint256 tokenId = _tokenIdTracker.current();
    //now mint
    _safeMint(recipient, tokenId);
    //now add name
    tokenName[tokenId] = name;
    reserved[name] = tokenId;
  }
}