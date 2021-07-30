# GRY.PH NFT Smart Contracts

The contract defined here are to allow auditors to evaluate the contracts that
are designed and specifically for the purpose of the GRY.PH project. It
specifies the process of digitizing collectable designs. Some of the business
requirements include the following.

 - Ability to cheaply define a set of tokens that can be minted for each design which include the following.
   - Design information
   - Token quantity limits
   - Royalty Fees
 - Ability to mint tokens cheaply or,
   - Ability to facilitate air drops off chain and,
   - Ability for buyers to redeem air drops and pay the minting costs.
 - Ability for holders to list tokens in a decentralized manner and,
   - Ability for buyers to purchase listed tokens on any NFT marketplace while having,
   - Ability to distribute royalties no matter where it was exchanged

#### Compatibility

Solidity ^0.8.0

 - Recommended v0.8.4

## 1. Install

```bash
$ cp .env.sample to .env
$ npm install
```

You will need to provide an [Ethereum Private Key](https://www.myetherwallet.com/wallet/create/software?type=overview)
to deploy to a test net and a [Coin Market Cap Key](https://coinmarketcap.com/api/pricing/)
to see gas price conversions when testing.

## 2. Testing

Make sure in `hardhat.config.js` to set the `defaultNetwork` to `hardhat`.

```bash
npm test
```

## 3. Documentation

 - [ERC721](./contracts/token/ERC721/README.md)
 - [ERC1155](./contracts/token/ERC1155/README.md)

> WARNING: The contracts provided here are as is and GRY.PH does not warrant that these will work on a live environment. It is possible that these contracts are out dated and it is possible for GRY.PH to update these contracts without notification. Use at your own risk.
