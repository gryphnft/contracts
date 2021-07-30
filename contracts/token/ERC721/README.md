# ERC721Exchange Contract

## Compatibility

Solidity ^0.8.0

 - Recommended v0.8.4

## Deploy to Blockchain

 - **name (string):** ex. Political Art
 - **symbol (string):** ex. POLYART
 - **contractURI (string):** ex. ipfs://QmXrknumwVrvNhgPFUJSEoakGLsF4NJgQ6cgdx1SBA8PUJ
 - **quantity (uint):** ex. 1000

```js
//load the factory
const NFT = await ethers.getContractFactory('ERC721Exchange')
//deploy the contract
const nft = await NFT.deploy(
  'Political Art',
  'POLYART',
  'ipfs://QmXrknumwVrvNhgPFUJSEoakGLsF4NJgQ6cgdx1SBA8PUJ',
  1000
)
//wait for it to be confirmed
await nft.deployed()

console.log('Contract deployed to:', nft.address)
```

## Contract Owner Actions

Only the contract owner can do the following actions. These are included in the
project's API.

#### Mint

Mints a token copy.

`mint(address recipient, string uri)`

 - **recipient** - ex. 0x63FC745B5309cE72921ED6dF48D4eAdddEB55f27
 - **uri** - ex. ipfs://QmXrknumwVrvNhgPFUJSEoakGLsF4NJgQ6cgdx1SBA8PUJ

```js
await nft.mint(
  '0x63FC745B5309cE72921ED6dF48D4eAdddEB55f27',
  'ipfs://QmXrknumwVrvNhgPFUJSEoakGLsF4NJgQ6cgdx1SBA8PUJ'
)
```

#### Set Fee

Sets a percent royalty. Setting again while its set will just
update the fee.

`setFee(address recipient, uint256 fee)`

 - **recipient** - ex. 0x63FC745B5309cE72921ED6dF48D4eAdddEB55f27
 - **fee** - any number between 1 and 10000 (where 10000 is 100.00%)

```js
await nft.setFee('0x63FC745B5309cE72921ED6dF48D4eAdddEB55f27', 1000)
```

#### Remove Fee

Removes a royalty fee

`removeFee(address recipient)`

 - **recipient** - ex. 0x63FC745B5309cE72921ED6dF48D4eAdddEB55f27

```js
await nft.removeFee('0x63FC745B5309cE72921ED6dF48D4eAdddEB55f27')
```

## Token Owner Actions

Only the token owner can do the following actions. These are not included in the
project's API and should be implemented on the client side.

#### Burn

Burns a token.

`burn(uint256 tokenId)`

 - **tokenId** - ex. 1

```js
await nft.burn(1)
```

#### List

Lists a token for sale. Listing again while its listed will just
update the amount.

`list(uint256 tokenId, uint256 amount)`

 - **tokenId** - ex. 1
 - **amount** - ex. 10000000000 (this is in wei)

```js
await nft.list(1, ethers.utils.parseEther('1.0'))
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

`exchange(uint256 tokenId)`

 - **tokenId** - ex. 1

```js
await nft.exchange(1, { value: ethers.utils.parseEther('1.0') })
```

## TODOS

 - Lazy Mint Spec - This should allow buyers to purchase a token before it is minted. The action should allow the contract owner to set the price (w royalties?) of all NFTs in order for buyers to purchase.
 - Rarible Compatibility - implement Rarible interfaces as extensions which can be used in the main contract
