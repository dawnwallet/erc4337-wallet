# <h1 align="center"> Forge Template </h1>

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

## Deployed contracts
Smart wallet Goerli: https://goerli.etherscan.io/address/0xf4c812424382b2d7720c08bb45f24f86302f2ae6#code 