// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

import "../interfaces/IRWAToken.sol";

/**
 * @title Wormhole Bridge
 * @author Mihailo Maksa 
 * @notice Wormhole bridge demo for bridging real world assets (RWA) cross-chain
 */
contract WormholeBridge is Ownable, Pausable {
  /// @notice Chain ID of the chain where the bridge contract is deployed
  uint256 public immutable CHAIN_ID;

  /**
   * @notice The constructor for the WormholeBridge contract
   * @param _owner address - The address of the owner of the contract
   */
  constructor(address _owner) Ownable(_owner) {
    CHAIN_ID = block.chainid;
  }
}