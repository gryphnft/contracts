# ERC1155Exchange Contract

## Compatibility

Solidity ^0.8.0

 - Recommended v0.8.4

## Deploy to Blockchain

 - **uri (string):** ex. ipfs://QmXrknumwVrvNhgPFUJSEoakGLsF4NJgQ6cgdx1SBA8PUJ

```js
//load the factory
const NFT = await ethers.getContractFactory('ERC1155Exchange')
//deploy the contract
const nft = await NFT.deploy('ipfs://QmXrknumwVrvNhgPFUJSEoakGLsF4NJgQ6cgdx1SBA8PUJ')
//wait for it to be confirmed
await nft.deployed()

console.log('Contract deployed to:', nft.address)
```

## Contract Owner Actions

Only the contract owner can do the following actions. These are included in the
project's API.

#### Mint

Mints a token copy.

`mint(address recipient, uint256 tokenId, uint256 quantity, bytes32 data)`

 - **recipient** - ex. 0x63FC745B5309cE72921ED6dF48D4eAdddEB55f27
 - **tokenId** - ex. 1
 - **quantity** - ex. 1000
 - **data** - ex. 0x0

```js
await nft.mint('0x63FC745B5309cE72921ED6dF48D4eAdddEB55f27', 1, 1000, 0x0)
```

#### Set Fee

Sets a percent royalty. Setting again while its set will just
update the fee.

`setFee(uint256 tokenId, address recipient, uint256 fee)`

 - **tokenId** - ex. 1
 - **recipient** - ex. 0x63FC745B5309cE72921ED6dF48D4eAdddEB55f27
 - **fee** - any number between 1 and 10000 (where 10000 is 100.00%)

```js
await nft.setFee(1, '0x63FC745B5309cE72921ED6dF48D4eAdddEB55f27', 1000)
```

#### Remove Fee

Removes a royalty fee

`removeFee(uint256 tokenId, address recipient)`

 - **tokenId** - ex. 1
 - **recipient** - ex. 0x63FC745B5309cE72921ED6dF48D4eAdddEB55f27

```js
await nft.removeFee(1, '0x63FC745B5309cE72921ED6dF48D4eAdddEB55f27')
```

## Token Owner Actions

Only the token owner can do the following actions. These are not included in the
project's API and should be implemented on the client side.

#### List

Lists a token for sale. Listing again while its listed will just
update the amount.

`list(uint256 tokenId, uint256 amount, uint256 quantity)`

 - **tokenId** - ex. 1
 - **amount** - ex. 10000000000 (this is in wei)
 - **quantity** - ex. 1000

```js
await nft.list(1, ethers.utils.parseEther('1.0'), 1000)
```

#### Delist

Removes a token from being saleable.

`delist(uint256 tokenId)`

 - **tokenId** - ex. 1

```js
await nft.list(1, ethers.utils.parseEther('1.0'))
```

## Public Actions

Anyone can do the following actions. These are not included in the
project's API and should be implemented on the client side.

#### Exchange

Allows the buyer to purchase a token by sending the listed price amount
using this method.

`exchange(address owner, uint256 tokenId, uint256 quantity, bytes32 data)`

 - **owner** - ex. 0x63FC745B5309cE72921ED6dF48D4eAdddEB55f27
 - **tokenId** - ex. 1
 - **quantity** - ex. 1000
 - **data** - ex. 0x0

```js
await nft.exchange('0x63FC745B5309cE72921ED6dF48D4eAdddEB55f27', 1, 1000, 0x0, { value: ethers.utils.parseEther('1.0') })
```
