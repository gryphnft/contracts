// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721/ERC721Upgradable.sol";
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

contract GryphNamespaces is 
  OwnableUpgradeable, 
  ReentrancyGuardUpgradeable,
  ERC721Upgradable
{
  using StringsUpgradeable for uint16;

  // ============ Constants ============

  //royalty percent
  uint256 private constant _ROYALTY_PERCENT = 500;
  //bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

  // ============ Storage ============

  //mapping of token id to name
  mapping(uint256 => string) private _registry;

  //mapping of names to blacklist
  mapping(string => bool) public blacklisted;

  // ============ Deploy ============

  /**
   * @dev Sets contract URI
   */
  function initialize(string memory uri) 
    public initializer 
  {
    __Ownable_init();
    __ReentrancyGuard_init();
    _setContractURI(uri);
  }

  // ============ Read Methods ============

  /**
   * @dev See {IERC721Metadata-name}.
   */
  function name() external pure returns(string memory) {
    return "Gryph Namespaces";
  }

  /**
   * @dev implements ERC2981 `royaltyInfo()`
   */
  function royaltyInfo(uint256, uint256 salePrice) 
    external 
    view 
    returns(address receiver, uint256 royaltyAmount) 
  {
    return (
      payable(address(owner())), 
      (salePrice * _ROYALTY_PERCENT) / 10000
    );
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override
    returns(bool)
  {
    //support ERC2981
    if (interfaceId == _INTERFACE_ID_ERC2981) {
      return true;
    }
    return super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC721Metadata-symbol}.
   */
  function symbol() external pure returns(string memory) {
    return "GNS";
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId) public view returns(string memory) {
    if(!_exists(tokenId)) revert NonExistentToken();
    string memory namespace = _registry[tokenId];
    return string(
      abi.encodePacked(
        "data:application/json;base64,",
        Base64.encode(bytes(abi.encodePacked(
          '{"name":"', namespace, '.gry.ph",',
          '"description": "', _description(), '",',
          '"image":"data:image/svg+xml;base64,', _svg64(namespace), '"}'
        )))
      )
    );
  }

  // ============ Write Methods ============

  /**
   * @dev Allows anyone to buy a name
   */
  function buy(address recipient, string memory namespace) 
    external payable 
  {
    //get the length of name
    uint256 length = bytes(namespace).length;
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
    _nameMint(recipient, namespace);
  }

  // ============ Admin Methods ============

  /**
   * @dev Assigns a name to a new owner. This would only ever be called  
   * if there was a reported breach of a trademark
   */
  function assign(uint256 tokenId, address recipient) external onlyOwner {
    _transfer(ownerOf(tokenId), recipient, tokenId);
  }

  /**
   * @dev Disallows `names` to be minted
   */
  function blacklist(string[] memory names) external onlyOwner {
    for (uint256 i = 0; i < names.length; i++) {
      blacklisted[names[i]] = true;
    }
  }

  /**
   * @dev Allow admin to mint a name without paying (used for airdrops)
   */
  function mint(address recipient, string memory namespace) 
    external onlyOwner 
  {
    _nameMint(recipient, namespace);
  }

  /**
   * @dev Allow `names`
   */
  function whitelist(string[] memory names) external onlyOwner {
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
    AddressUpgradeable.sendValue(payable(recipient), address(this).balance);
  }

  /**
   * @dev This contract should not hold any tokens in the first place. 
   * This method exists to transfer out tokens funds.
   */
  function withdraw(IERC20Upgradeable erc20, address recipient, uint256 amount) 
    external virtual nonReentrant onlyOwner
  {
    SafeERC20Upgradeable.safeTransfer(erc20, recipient, amount);
  }

  // ============ Private Methods ============

  function _prices() private pure returns(uint64[7] memory) {
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

  function _description() private pure returns(string memory) {
    return "GRY.PH is a cross chain NFT marketplace. Holders of this collection namespace have the rights to customize the content available.";
  }

  function _grid() private pure returns(uint16[5][73] memory) {
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

  function _svg64(string memory namespace) private pure returns(string memory) {
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
      '<text id="name" font-family="', "'Courier New'", '" font-weight="bold" font-size="30" y="50%" x="50%" fill="#000" dominant-baseline="middle" text-anchor="middle">', namespace,'</text>',
      '</g></svg>'
    );

    return Base64.encode(svg);
  }

  function _nameMint(address recipient, string memory namespace) private {
    //if blacklisted
    if (blacklisted[namespace]) revert InvalidName();
    //determine token id from name
    bytes32 nameHash = keccak256(abi.encodePacked(namespace));
    if (nameHash.length < 32) revert InvalidName();
    uint256 tokenId = uint256(nameHash);
    //now mint
    _safeMint(recipient, tokenId);
    _registry[tokenId] = namespace;
  }
}