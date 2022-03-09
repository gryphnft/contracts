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
  using Strings for uint16;
  using Counters for Counters.Counter;

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
  constructor(string memory uri) ERC721Base("Gryph Namespaces", "GNS") {
    _setContractURI(uri);
  }

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
          '"description": "', _description(), '",',
          '"image":"data:image/svg+xml;base64,', _svg64(name), '"}'
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
    //get prices
    uint64[7] memory prices = _prices();
    //get index
    uint256 index = length - 4;
    if (index >= prices.length) {
      index = prices.length - 1;
    }
    //check price
    if (msg.value < prices[index]) revert InvalidAmountSent();
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

  function _prices() internal pure returns(uint64[7] memory) {
    return [
      0.192 ether, //4 letters
      0.096 ether, //5 letters
      0.048 ether, //6 letters 
      0.024 ether, //7 letters
      0.012 ether, //8 letters
      0.006 ether, //9 letters
      0.003 ether  //10 letters or more
    ];
  }

  function _description() internal pure returns(string memory) {
    return "GRY.PH is a cross chain NFT marketplace. Holders of this collection namespace have the rights to customize its contents";
  }

  function _grid() internal pure returns(uint16[5][73] memory) {
    return [
      [uint16(25), 25, 13, 125, 0],
      [uint16(50), 25, 38, 100, 0],
      [uint16(75), 25, 88, 75, 0],
      [uint16(25), 25, 163, 50, 0],
      [uint16(25), 25, 188, 25, 0],
      [uint16(25), 25, 213, 0, 0],
      [uint16(25), 25, 288, 75, 0],
      [uint16(25), 25, 263, 50, 0],
      [uint16(25), 25, 238, 25, 0],
      [uint16(25), 50, 338, 75, 0],
      [uint16(25), 25, 363, 125, 0],
      [uint16(25), 25, 388, 150, 0],
      [uint16(25), 25, 413, 175, 0],
      [uint16(25), 75, 438, 200, 0],
      [uint16(50), 25, 38, 150, 0],
      [uint16(25), 25, 113, 175, 0],
      [uint16(25), 75, 88, 200, 0],
      [uint16(25), 25, 113, 275, 0],
      [uint16(25), 25, 13, 325, 0],
      [uint16(50), 25, 38, 300, 0],
      [uint16(50), 25, 38, 350, 0],
      [uint16(75), 25, 88, 375, 0],
      [uint16(25), 25, 163, 400, 0],
      [uint16(25), 25, 188, 425, 0],
      [uint16(25), 25, 213, 450, 0],
      [uint16(25), 25, 288, 375, 0],
      [uint16(25), 25, 263, 400, 0],
      [uint16(25), 25, 238, 425, 0],
      [uint16(25), 50, 338, 350, 0],
      [uint16(25), 25, 363, 325, 0],
      [uint16(25), 25, 388, 300, 0],
      [uint16(25), 25, 413, 275, 0],
      [uint16(50), 25, 38, 125, 1],
      [uint16(50), 25, 38, 325, 1],
      [uint16(50), 25, 88, 150, 1],
      [uint16(75), 25, 88, 100, 1],
      [uint16(75), 25, 88, 350, 1],
      [uint16(50), 25, 88, 300, 1],
      [uint16(25), 75, 113, 200, 1],
      [uint16(25), 25, 163, 75, 1],
      [uint16(75), 25, 188, 50, 1],
      [uint16(25), 25, 213, 25, 1],
      [uint16(25), 25, 263, 75, 1],
      [uint16(25), 25, 138, 175, 1],
      [uint16(25), 25, 138, 275, 1],
      [uint16(75), 25, 188, 400, 1],
      [uint16(25), 25, 213, 425, 1],
      [uint16(25), 25, 263, 375, 1],
      [uint16(25), 25, 163, 375, 1],
      [uint16(25), 25, 88, 125, 2],
      [uint16(25), 25, 88, 325, 2],
      [uint16(25), 50, 213, 100, 2],
      [uint16(25), 50, 238, 125, 2],
      [uint16(25), 50, 238, 300, 2],
      [uint16(25), 25, 288, 175, 2],
      [uint16(25), 25, 288, 275, 2],
      [uint16(25), 50, 213, 325, 2],
      [uint16(25), 25, 213, 200, 2],
      [uint16(25), 25, 213, 250, 2],
      [uint16(25), 25, 363, 150, 2],
      [uint16(25), 25, 363, 300, 2],
      [uint16(25), 125, 388, 175, 2],
      [uint16(75), 75, 238, 200, 3],
      [uint16(25), 25, 263, 175, 3],
      [uint16(25), 25, 263, 275, 3],
      [uint16(25), 25, 288, 150, 3],
      [uint16(25), 25, 288, 300, 3],
      [uint16(25), 50, 313, 75, 3],
      [uint16(50), 50, 313, 125, 3],
      [uint16(75), 125, 313, 175, 3],
      [uint16(50), 50, 313, 300, 3],
      [uint16(25), 50, 313, 350, 3],
      [uint16(25), 75, 413, 200, 3]
    ];
  }

  function _svg64(string memory name) internal pure returns(string memory) {
    bytes memory svg = abi.encodePacked(
      '<svg width="475" height="475" xmlns="http://www.w3.org/2000/svg"><g><rect height="475" width="475" fill="#ffffff"/>'
    );

    string[4] memory color = [
      'D0D0D0',
      'F5F5F5',
      'EDEDED',
      'DBDBDB'
    ];

    uint16[5][73] memory grid = _grid();
    for (uint8 i = 0; i < grid.length; i++) {
      svg = abi.encodePacked(svg,
        '<rect height="', grid[i][0].toString(),
        '" width="', grid[i][1].toString(),
        '" y="', grid[i][2].toString(),
        '" x="', grid[i][3].toString(),
        '" fill="#', color[grid[i][4]],'"/>'
      );
    }

    svg = abi.encodePacked(svg,
      '<text font-family="', "'Courier New'", '" font-weight="bold" font-size="30" y="60%" x="50%" fill="#444" dominant-baseline="middle" text-anchor="middle">gry.ph</text>',
      '<text id="name" font-family="', "'Courier New'", '" font-weight="bold" font-size="30" y="50%" x="50%" fill="#000" dominant-baseline="middle" text-anchor="middle">', name,'</text>',
      '</g></svg>'
    );

    return Base64.encode(svg);
  }

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