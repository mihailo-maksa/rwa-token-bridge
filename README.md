# **Solidity Bridge Coding Challenge Documentation**

## **Overview**

The system is purpose-built to support bridging any RWA (real world asset) ERC20 tokens from any supported EVM chain to any other supported EVM chain. To do this, protocols such as Axelar and LayerZero were used, since we didn't want to develop the functionality for general message passing across blockchains natively. The system consists of the following components:

1. **LayerZero Bridge Smart Contract System:**
   1. **`RWATokenOFT`:** Simple OFT (omnichain fungible token) ERC20 token representing a tokenized real world asset (RWA) for the LayerZero bridge.
   2. **`LayerZeroBridge`:**
2. **Axelar Bridge Smart Contract System**
   1. **`RWAToken`:** Simple ERC20 token representing a tokenized real world asset (RWA) for the Axelar bridge.
   2. **`AxelarSourceBridge`:**

### Key Dependencies

To achieve cross-chain interoperability, the system relies on the following key dependencies:
1. **OFT:**: The omnichain fungible token (OFT) standard, developed by LayerZero Labs, and used for constructing our `RWATokenOFT`. It allows the bridge admin to set trusted remote chains and addresses on each chain, ensuring secure two-way communication between the chains.
2. **Axelar GMP SDK:** Several key components from the Axelar's General Message Passing (GMP) SDK were used to facilitate cross-chain communication. These include the `AxelarGateway` (), `AxelarGasService` () and finally, `AxelarExecutable` ().

## Constraints

- Use at least 2 message passing protocols from {Axelar, Layerzero, Wormhole}.
- Implement thresholds on destination bridge such that arbitrary thresholds can be set based on amounts, e.g., 100K bridge transfer needs 2 approvers (where a message delivered on destination chain by a message passing protocol is considered an approver, like Axelar).
- Admin must have the ability to define arbitrary thresholds.
- The bridge must have the ability to be paused if needed.
- The bridge must support multiple RWA ERC-20 tokens.
- The bridge must have a daily rate limit where no more tokens are minted if this limit is met.
- There should be extensive tests for the bridge.

## Assumptions

- Issuer can solely mint tokens.
- RWA tokens are simple ERC20 tokens with mint and burn.


## **Design Rationale**

The system is designed to be modular and extensible, with the following key properties:








The OffBlocks Smart Contract System is meticulously designed to simulate the mechanics of a real-world escrow service enhanced by the advantages of blockchain technology, such as trustless transactions and immutability. The system is built with the following principles in mind:

1. **MockToken**: Provides a controlled environment for testing the escrow system without using real assets, aligning with the best practices of software testing.

2. **MockOracle**: In decentralized applications, oracles bridge the gap between on-chain and off-chain worlds. The `MockOracle` emulates this behavior, giving developers an insight into how external data might affect the system.

3. **Escrow**: The core component, it embodies the principles of trustless transactions, a hallmark of blockchain. With in-built oracle integration and a timeout mechanism, it caters to versatile real-world scenarios, providing flexibility and security.

## **Deployment**

This section outlines the steps to deploy the system to a local or public Ethereum network. In this example, we'll use Hardhat as the development environment, but you can use any other Ethereum development tool of your choice, like Truffle, Remix, Brownie or Foundry.

### **Prerequisites**

- Ensure you have the required Ethereum development tools installed, including Node.js, NPM and Hardhat.
- An Ethereum testnet, like Goerli or Sepolia, is required if deploying to a live network. Alternatively, you can use Hardhat's built-in local network for testing.
- The system has dependencies on OpenZeppelin libraries, so ensure they're accessible in your environment.

### **Steps**:

1. **Compile the Contracts**:

   ```bash
   npx hardhat compile
   ```

2. **Deployment**:

   - Deploy the `MockToken` and `MockOracle` first, as the `Escrow` contract will require their addresses as constructor parameters.
   - The full deployment script is available in `scripts/deploy.js`. You can modify it to suit your needs.

   ```bash
    npx hardhat run scripts/deploy.js --network YOUR_NETWORK
   ```

3. **Verification**: If deploying to a public network, always verify the contract's source code to ensure transparency and trust with users. For this, we'll be using the `hardhat-etherscan` plugin:

   ```bash
   npx hardhat verify CONTRACT_ADDRESS --network YOUR_NETWORK
   ```

4. **Testing**: The system includes a thorough set of unit tests that address all of its main features. To run the tests, use the following command:

   ```bash
   npx hardhat test test/test.js
   ```

5. **Live Example**: The system is deployed on the Goerli testnet, with the following contract addresses:

   - `MockToken`: [0x4DAdb8beAAe01Aa5A84B1208115606d6664280d5](https://goerli.etherscan.io/address/0x4DAdb8beAAe01Aa5A84B1208115606d6664280d5)
   - `MockOracle`: [0x7334BECA3A3294F6a5366059a2EF352735695F74](https://goerli.etherscan.io/address/0x7334BECA3A3294F6a5366059a2EF352735695F74)
   - `Escrow`: [0x4fc23332623a4223972345Fa3801D0963EAb35CC](https://goerli.etherscan.io/address/0x4fc23332623a4223972345Fa3801D0963EAb35CC)

All of the above contract addresses also have their source code fully verified on Goerli Etherscan.

## **Design Rationale**

The Solidity Bridge Coding Challenge's design is centered around several key properties to address the constraints and assumptions of the system:

1. **Modularity and Extensibility**: The system is built with a modular structure, allowing for easy integration or replacement of components like bridge protocols (LayerZero, Axelar) and RWA tokens. This modularity ensures adaptability to future technologies and standards.

2. **Uniform Contract Addresses**: All contracts, across all supported blockchains, maintain the same addresses. This is achieved by deploying them from a fresh deployer address. This consistency simplifies cross-chain interactions and enhances user trust, as it ensures recognizable and verifiable contract addresses on different chains.

3. **Simplicity in Design**: The system adheres to the KISS principle ("Keep It Simple, Stupid"), aiming to reduce complexity wherever possible. This is evident in the straightforward design of the `RWAToken` and `RWATokenOFT`, which are simple ERC20 tokens, ensuring ease of use and understanding.

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
  - **Axelar GMP Integration**: Utilizes Axelar's General Message Passing SDK for reliable cross-chain messages.
  - **Admin Controls**: Includes mechanisms for pausing the bridge and setting rate limits, providing essential administrative tools.

## **Usage**

1. **LayerZero Bridge Operations**:
   - Users can bridge `RWATokenOFT` between supported EVM chains, maintaining asset fidelity across chains.
   - Administrators set and manage cross-chain relationships and thresholds through the `LayerZeroBridge`.

2. **Axelar Bridge Operations**:
   - `RWAToken` can be bridged using Axelar's protocol, ensuring secure and efficient cross-chain transfers.
   - The `AxelarSourceBridge` enables nuanced control over bridging operations, including rate limiting and emergency pause functionalities.

## **Potential Upgrades**

1. **Additional Protocols**: Integrating more general message passing protocols like Wormhole or Chainlink's CCIP, expanding the bridge's versatility and reach.

2. **Upgradeable Contracts**: Implementing upgradeable proxy patterns for critical contracts with a timelock feature, providing transparency and flexibility in system updates.

3. **Bucket Level Rate Limiting**: Establishing chain-pair specific rate limits for each token, adding an extra layer of control to the existing global daily limits.

4. **Manual Approver Thresholds**: Introducing a multisig approval mechanism for large transfers, enhancing security for high-value transactions.

5. **Non-EVM Chain Support**: Expanding the bridging capabilities to include non-EVM chains like Aptos, Cosmos, and Solana, leveraging protocols like LayerZero, Axelar, and Wormhole, respectively, to cater to a broader market.