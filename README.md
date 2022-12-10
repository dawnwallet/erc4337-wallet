<!-- // How this works:
// 1. Smart wallet is deployed for each user
// 2. User off-chain has a mechanism of authorising a transaction. This is likely a private key they hold. The user creates a 
//    UserOperation object using an SDK, signs the request and then via an RPC sends it to the alternative mempool
// 3. A bundler takes the user UserOperation, along with other UserOperations and turns them into a single Ethereum transaction. During this process
//    it calls the validateUserOp() method on each wallet to verify that it will be successful
// 4. The bundler then submits the transaction to the Ethereum network. The transaction will call the Entrypoint point, specifically the handleOps() method
//    handleOps(UserOperation[] calldata userOps) itself will iterate through all UserOperations and for each call wallet.validateUserOp(). It also
//    calls the target address and with the calldata (i.e. executing the UserOperation). The EntryPoint may also call execFromEntryPoint() on the wallet
// 5.  -->


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


## Acknowledgements
Based on the the work done on the Eth-Infinitism repo: https://github.com/eth-infinitism/account-abstraction 