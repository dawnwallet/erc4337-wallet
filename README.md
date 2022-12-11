# Smart wallet


## Getting started
1. Install Foundry and Forge: https://book.getfoundry.sh/getting-started/installation 
2. Compile contracts: `npm run build`
3. Run tests: `npm run test`

To deploy:
1. Copy `.env.example` to a local gitignored `.env` file. Fill in the environment variables
2. Run `npm run deploy` to deploy to Goerlie. Note, this will verify the contracts as well on Etherscan.

## Deployed contracts (Goerli)
v1
- Smart wallet: https://goerli.etherscan.io/address/0x6f3458201317928919BEf5985d5069ACb155a111#code 
- Paymaster (pays for everything, no check): https://goerli.etherscan.io/address/0x98CeE2e3ffC2d80E6d6D073079926132F1b71B2b#code 

v2
- Smart wallet: https://goerli.etherscan.io/address/0x77fd2AC5385d76B90B48B0A141cc8d418ABE5D18 

V3
- Entrypoint: 0x5bB5b946426ca8aEE5D5A744bcB15951aCCC5323
- Wallet: 0x57FF0B3E0e71e38eBFD1579a3e2B39bb0B09DABC
- Paymaster: 0x904612fBe7cCF7c1f9872e7582f10a106BB86eC4

V4:
- Entrypoint: 0x9d98Bc2609b080a12aFd52477514DB95d668be3b
- Wallet: 0x31Bd1f12aE1B6E70266a441F42Fa90ff89fD8542
- Paymaster: 0xf18d5c7247b31812d3D06a74Db5CE4A09c12285D

V5:
- wallet: 0x1d7dC84343Ae6b068caC1555957ce25513766BD2

## Acknowledgements
Based on the the work done on the Eth-Infinitism repo: https://github.com/eth-infinitism/account-abstraction 