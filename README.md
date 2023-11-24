# **Solidity Bridge Coding Challenge Documentation**

## **Overview**

The system is purpose-built to support bridging any RWA (real world asset) ERC20 tokens from any supported EVM chain to any other supported EVM chain. To do this, protocols such as Axelar and LayerZero were used, since we didn't want to develop the functionality for general message passing across blockchains natively. The system consists of the following components:

1. **LayerZero Bridge Smart Contract System:**
   1. **`RWATokenOFT`:** Simple OFT (omnichain fungible token) ERC20 token representing a tokenized real world asset (RWA) for the LayerZero bridge.
   2. **`LayerZeroBridge`:** Smart contract system for the LayerZero bridge, which allows for the transfer of `RWATokenOFT` between EVM chains.
2. **Axelar Bridge Smart Contract System**
   1. **`RWAToken`:** Simple ERC20 token representing a tokenized real world asset (RWA) for the Axelar bridge.
   2. **`AxelarSourceBridge`:** Initiates cross-chain transfers of `RWAToken` between EVM chains using Axelar's protocol.
   3. **`AxelarDestinationBridge`:** Receives cross-chain messages of `RWAToken` transfers from the source chain, and mints `RWATokenOFT` on the destination chain.

### Key Dependencies

To achieve cross-chain interoperability, the system relies on the following key dependencies:
1. **OFT:**: The omnichain fungible token (`OFT`) standard, developed by LayerZero Labs, and used for constructing our `RWATokenOFT`. It allows the bridge admin to set trusted remote chains and addresses on each chain, ensuring secure two-way communication between the chains.
2. **Axelar GMP SDK:** Several key components from the Axelar's General Message Passing (GMP) SDK were used to facilitate cross-chain communication. These include the `AxelarGateway`, `AxelarGasService` and finally, `AxelarExecutable`

## **Deployment**

This section outlines the steps to deploy the system to a local or public Ethereum network. In this example, we'll use Hardhat as the development environment, but you can use any other Ethereum development tool of your choice, like Truffle, Remix, Brownie or Foundry.

### **Prerequisites**

- Ensure you have the required Ethereum development tools installed, including Node.js, NPM and Hardhat.
- Various testnet tokens (e.g. AVAX on Fuji, MATIC on Mumbai, ETH on Arbitrum Goerli and BNB on BSC Testnet) are required if deploying to a live network. Alternatively, you can use Hardhat's built-in local network for testing.
- The system has dependencies on OpenZeppelin libraries, so ensure they're accessible in your environment. 
- Usage of TypeScript is recommended, but not required.

### **Steps**:

1. **Compile the Contracts**:

   ```bash
   npx hardhat compile
   ```

2. **Deployment**:
- There is also a separate args file for each contract, which contains the constructor arguments for that contract. The args files are located in the `scripts/args` directory. This is useful for the contract verification step, and also contains some key contract addresses that are used in the deployment scripts.

   ```bash
    npx hardhat run scripts/deploy/deployContractName.ts --network YOUR_NETWORK
   ```

3. **Verification**: If deploying to a public network, always verify the contract's source code to ensure transparency and trust with users. For this, we'll be using the `hardhat-etherscan` plugin:

   ```bash
   npx hardhat verify CONTRACT_ADDRESS --network YOUR_NETWORK --constructor-args scripts/args/argsContractName.ts
   ```

4. **Testing**: The system includes a thorough set of unit tests that address all of its main features. To run the tests, use the following command:
- **Note:** The tests are written in TypeScript, so ensure you have the required dependencies installed. Also, some tests were only possible on an actual public testnet, so make sure to look at the comments in the test files to see live examples of the system in action.

   ```bash
   npx hardhat test
   ```

5. **Live Example**: The system is deployed on the 3 public testnets:
- BSC Testnet
- Arbitrum Goerli
- Polygon Mumbai

Note that the contract addresses are the same across all chains, as they were deployed from a fresh deployer address. This ensures consistency and trust, as users can easily verify the contract addresses on different chains.

**The addresses are as following:**
- **`RWATokenOFT`**: `0x4c74013f2dDd453D7bB7ae48ED8A8dfbacf69aBB`
- **`LayerZeroBridge`**: `0x9804Ca3c7A9d2fD5Db3257c6Ed1f7c3eFeD253d4`
- **`RWAToken`**: `0x202AEa9fC1401cF9a1629103A2b140E350e09C24`
- **`AxelarSourceBridge`**: `0x91C0bFfD5451132ceb8156f32f935581B5F1B78F`
- **`AxelarDestinationBridge`**: `0x0FFABc97C6ad8D69Da45AE5F5a11017ac0962F3d`

## **Design Rationale**

The Solidity Bridge Coding Challenge's design is centered around several key properties to address the constraints and assumptions of the system:

1. **Modularity and Extensibility**: The system is built with a modular structure, allowing for easy integration or replacement of components like bridge protocols (LayerZero, Axelar) and RWA tokens. This modularity ensures adaptability to future technologies and standards.

2. **Uniform Contract Addresses**: All contracts, across all supported blockchains, maintain the same addresses. This is achieved by deploying them from a fresh deployer address. This consistency simplifies cross-chain interactions and enhances user trust, as it ensures recognizable and verifiable contract addresses on different chains.

3. **Simplicity in Design**: The system adheres to the KISS and DRY principles, aiming to reduce complexity wherever possible. This is evident in the straightforward design of the `RWAToken` and `RWATokenOFT`, which are simple ERC20 tokens, ensuring ease of use and understanding.

4. **Scalability and Efficiency**: By using established protocols like Axelar and LayerZero, the system leverages their optimized, secure cross-chain communication, avoiding the need to reinvent the wheel. This not only saves development time but also ensures high performance and scalability.

5. **Configurability and Control**: The admin's ability to define arbitrary thresholds and pause the bridge operations provides a high degree of control and flexibility, accommodating various operational scenarios and risk management strategies.

6. **Security and Reliability**: With a focus on security, the system incorporates features like rate limiting, and multi-approver thresholds, ensuring robust protection against overuse and malicious activities.

## **System Architecture**

### **LayerZero Bridge Smart Contract System**

- **`RWATokenOFT`**:
  - **OFT Standard**: Implements the Omnichain Fungible Token standard, enabling token representation across multiple chains.
  - **Bridge Admin Control**: Allows the bridge admin to set trusted remote chains, ensuring secure and controlled token flow.

- **`LayerZeroBridge`**:
  - **Cross-Chain Communication**: Facilitates token transfers between EVM chains, leveraging LayerZero's interoperability protocol.
  - **Configurable Thresholds**: Enables setting of transfer thresholds and approvers, adhering to the admin's risk management policies.

### **Axelar Bridge Smart Contract System**

- **`RWAToken`**:
  - **ERC20 Compliance**: Standard ERC20 implementation, ensuring compatibility with a broad range of wallets and services.
  - **Mint and Burn**: Facilitates tokenization and redemption of RWA, crucial for representing real-world assets on-chain.

- **`AxelarSourceBridge`**:
  - **Axelar GMP Integration**: Utilizes Axelar's General Message Passing SDK for initiating reliable cross-chain messages.
  - **Admin Controls**: Includes mechanisms for pausing the bridge and setting rate limits, providing essential administrative tools.

- **`AxelarDestinationBridge`**:
  - **Axelar GMP Integration**: Utilizes Axelar's General Message Passing SDK for receiving reliable cross-chain messages.
  - **Minting and Burning**: Mints and burns `RWATokenOFT` on the destination chain, ensuring asset fidelity across chains.

## **Usage**

1. **LayerZero Bridge Operations**:
   - Users can bridge `RWATokenOFT` between supported EVM chains, maintaining asset fidelity across chains.
   - Owner (admin) sets and manage cross-chain relationships and thresholds through the `LayerZeroBridge`.

2. **Axelar Bridge Operations**:
   - `RWAToken` can be bridged using Axelar's protocol, ensuring secure and efficient cross-chain transfers.
   - The `AxelarSourceBridge` enables nuanced control over bridging operations, including rate limiting and emergency pause functionalities.

## **Potential Upgrades**

1. **Additional Protocols**: Integrating more general message passing protocols like Wormhole or Chainlink's CCIP, expanding the bridge's versatility and reach.

2. **Upgradeable Contracts**: Implementing upgradeable proxy patterns for critical contracts with a timelock feature, providing transparency and flexibility in system updates.

3. **Bucket Level Rate Limiting**: Establishing chain-pair specific rate limits for each token, adding an extra layer of control to the existing global daily limits.

4. **Manual Approver Thresholds**: Introducing a multisig approval mechanism for large transfers, enhancing security for high-value transactions.

5. **Non-EVM Chain Support**: Expanding the bridging capabilities to include non-EVM chains like Aptos, Cosmos and IBC, and Solana, leveraging protocols like LayerZero, Axelar, and Wormhole, respectively, to cater to a broader market.
