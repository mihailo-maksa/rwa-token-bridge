# Solidity Coding Challenge

## Scenario

We want to develop a bridge for our RWA tokens utilising the approach of mint and burn. Meaning, RWA tokens will be burned on source chains and minted on destination chain. To do this, we want to use other protocols like Axelar, Layerzero, and Wormhole since we do not want to develop the ability to pass messages across several chains.

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

## Nice to Have

- Use all 3 message passing protocols.
- Implement bucket level rate limiting based on source<>destination chain.
- Implement upgradability.
- Make all contracts have the same addresses on all EVM compatible chains.
- Require manual approver for certain thresholds (where a multisig of the issuer approves each transaction in that threshold).

## Extra

- Make the bridge work on Solana.

## Development

Use Foundry or Hardhat for development.

### Evaluation Criteria

Code quality, unit tests, documentation, and readme will be assessed.

### Useful Links
- https://github.com/foundry-rs/foundry
- https://hardhat.org/ 


Have fun coding! 🚀
