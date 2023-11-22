// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol";
import "@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol";

import "../interfaces/IRWAToken.sol";

/**
 * @title AxelarDestinationBridge
 * @author Mihailo Maksa
 * @notice Axelar destination bridge demo for bridging real world assets (RWA) cross-chain
 */
contract AxelarDestinationBridge is AxelarExecutable, Ownable, Pausable {
  /// @notice Version of the bridge contract, must match the version of the source bridge contract
  bytes32 public constant VERSION = "1.0";
  
  /// @notice Chain ID of the chain where the destination bridge contract is deployed
  uint256 public immutable CHAIN_ID;

  /// @notice Address of the source bridge contract
  address public immutable sourceBridge;

  /// @notice Address of the Axelar Gateway contract
  IAxelarGateway public immutable axelarGateway;

  struct Threshold {
    uint256 amount;
    uint256 numberOfApprovals;
  }

  struct TxThreshold {
    uint256 numberOfApprovals;
    address[] approvers;
  }

  struct Tx {
    address token;
    uint256 amount;
  }

  mapping(address => bool) public approvers;

  mapping(string => bytes32) public chainToApprovedSender;

  mapping(bytes32 => mapping(uint256 => bool)) public isSpentNonce;

  mapping(bytes32 => TxThreshold) public txToThresholdSet;

  mapping(string => Threshold[]) public chainToThresholds;
  
  mapping(bytes32 => Tx) public txHashToTransaction;

  event ApproverAdded(address indexed approver);

  event ApproverRemoved(address indexed approver);

  event ChainSupportAdded(string indexed srcChain, string approvedChain);
  
  event ChainSupportRemoved(string indexed srcChain);

  event ThresholdSet(string indexed chain, uint256[] amounts, uint256[] numberOfApprovals);

  event MessageReceived(bytes32 indexed txHash, string indexed srcChain, address indexed srcSender, uint256 amount, uint256 nonce, uint256 timestamp);

  event TransactionApproved(bytes32 indexed txHash, address approver, uint256 numberOfApprovals, uint256 requiredThreshold, uint256 timestamp);

  event BridgeCompleted(address indexed user, uint256 amount, uint256 timestamp);

  /**
   * @notice Pauses the pausable functions inside the contract
   * @dev Only owner can call it
   */
  function pause() external onlyOwner {
    _pause();
  }

  /**
   * @notice Unpauses the pausable functions inside the contract
   * @dev Only owner can call it
   */
  function unpause() external onlyOwner {
    _unpause();
  }

  /**
   * @notice Admin function used to rescue ERC20 Tokens sent to the contract
   * @param _token The address of the token to rescue
   */
  function rescueTokens(address _token) external onlyOwner {
    uint256 balance = IERC20(_token).balanceOf(address(this));
    require(IERC20(_token).transfer(owner(), balance), "AxelarDestinationBridge::rescueTokens: ERC20 transfer failed");
  }
}
