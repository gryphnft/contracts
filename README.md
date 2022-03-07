# GRY.PH NFT Smart Contracts

#### Compatibility

Solidity ^0.8.0

 - Recommended v0.8.9

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

> WARNING: The contracts provided here are as is and GRY.PH does not warrant that these will work on a live environment. It is possible that these contracts are out dated and it is possible for GRY.PH to update these contracts without notification. Use at your own risk.

## 4. Reports

The following is an example gas report from the tests ran in this project and could change based on the cost of Ethereum itself.

<pre>
·------------------------------------|---------------------------|-------------|-----------------------------·
|        Solc version: 0.8.4         ·  Optimizer enabled: true  ·  Runs: 200  ·  Block limit: 12450000 gas  │
·····································|···························|·············|······························
|  Methods                           ·              200 gwei/gas               ·       1.01 usd/matic        │
······················|··············|·············|·············|·············|···············|··············
|  Contract           ·  Method      ·  Min        ·  Max        ·  Avg        ·  # calls      ·  usd (avg)  │
······················|··············|·············|·············|·············|···············|··············
|  ERC721Marketplace  ·  allocate    ·      35698  ·     113680  ·      84399  ·            5  ·       0.02  │
······················|··············|·············|·············|·············|···············|··············
|  ERC721Marketplace  ·  deallocate  ·          -  ·          -  ·      24940  ·            1  ·       0.01  │
······················|··············|·············|·············|·············|···············|··············
|  ERC721Marketplace  ·  delist      ·          -  ·          -  ·      15517  ·            1  ·       0.00  │
······················|··············|·············|·············|·············|···············|··············
|  ERC721Marketplace  ·  drop        ·          -  ·          -  ·      46379  ·            2  ·       0.01  │
······················|··············|·············|·············|·············|···············|··············
|  ERC721Marketplace  ·  exchange    ·      56830  ·     100764  ·      78797  ·            2  ·       0.02  │
······················|··············|·············|·············|·············|···············|··············
|  ERC721Marketplace  ·  list        ·          -  ·          -  ·      48178  ·            4  ·       0.01  │
······················|··············|·············|·············|·············|···············|··············
|  ERC721Marketplace  ·  mint        ·      89405  ·     123605  ·     115055  ·            4  ·       0.02  │
······················|··············|·············|·············|·············|···············|··············
|  ERC721Marketplace  ·  redeem      ·      88848  ·     126418  ·      99092  ·            4  ·       0.02  │
······················|··············|·············|·············|·············|···············|··············
|  ERC721Marketplace  ·  register    ·          -  ·          -  ·      70023  ·            5  ·       0.01  │
······················|··············|·············|·············|·············|···············|··············
|  Deployments                       ·                                         ·  % of limit   ·             │
·····································|·············|·············|·············|···············|··············
|  ERC721Marketplace                 ·          -  ·          -  ·    2771489  ·       22.3 %  ·       0.56  │
·------------------------------------|-------------|-------------|-------------|---------------|-------------·
</pre>
