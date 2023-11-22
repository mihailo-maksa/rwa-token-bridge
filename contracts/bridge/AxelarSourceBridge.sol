// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol";
import "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol";
import { AddressToString } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/AddressString.sol";

import "../interfaces/IRWAToken.sol";

/**
 * @title AxelarSourceBridge
 * @author Mihailo Maksa 
 * @notice Axelar source bridge demo for bridging real world assets (RWA) cross-chain
 */
contract AxelarSourceBridge is Ownable, Pausable {
  /// @notice The version of the bridge, used for the payload of the bridge transaction
  bytes32 public constant VERSION = "1.0";

  /// @notice Source chain ID, used to salt the hash of the bridge transaction hash on the destination chain
  uint256 public immutable CHAIN_ID;

  /// @notice Address of the Axelar gateway contract on the source chain
  IAxelarGateway public immutable axelarGateway;

  /// @notice Address of the Axelar gas service contract on the source chain
  IAxelarGasService public immutable axelarGasService;

  /// @notice Nonce used for the payload of the bridge transaction, incremented after each bridge transaction is initiated
  uint256 public nonce;

  /// @notice Mapping from destination chain to bridge address on that chain
  /// @dev Axelar uses the string representation of addresses, so we need to use string as the key
  mapping(string => string) public dstChainToBridge;

  /// @notice The mapping of supported tokens by the bridge
  mapping(IRWAToken => bool) public supportedTokens;

  /// @notice The mapping of the maximum transfer sizes for each token
  mapping(IRWAToken => uint256) public maxTransferSizes;

  /// @notice The mapping of the daily limits for each token
  mapping(IRWAToken => uint256) public dailyLimits;

  /// @notice The mapping of the daily transferred amounts for each token in the last 24 hours
  mapping(IRWAToken => uint256) private dailyTransferred;

  /// @notice The mapping of the last daily reset for each token
  mapping(IRWAToken => uint256) private lastDailyReset;

  /// @notice An event emitted when a destination chain is added to the list of supported destination chains by the bridge
  event DestinationChainAdded(
    string indexed destinationChain,
    address indexed bridgeAddress,
    uint256 timestamp
  );

  /// @notice An event emitted when a destination chain is removed from the list of supported destination chains by the bridge
  event DestinationChainRemoved(string indexed destinationChain, uint256 timestamp);

  /// @notice An event emitted when a token is added to the list of supported tokens by the bridge
  event TokenAdded(IRWAToken indexed token, uint256 timestamp);

  /// @notice An event emitted when a token is removed from the list of supported tokens by the bridge
  event TokenRemoved(IRWAToken indexed token, uint256 timestamp);

  /// @notice An event emitted when a maximum transfer size is updated for a token
  event MaxTransferSizeUpdated(
    IRWAToken indexed token,
    uint256 newMaxTransferSize,
    uint256 timestamp
  );

  /// @notice An event emitted when a daily limit is updated for a token
  event DailyLimitUpdated(
    IRWAToken indexed token,
    uint256 newLimit,
    uint256 timestamp
  );

  /// @notice An event emitted when a bridge transaction is initiated
  event BridgeInitiated(
    address indexed sender,
    uint256 indexed nonce,
    uint256 indexed srcChainId,
    bytes32 version,
    uint256 amount
  );

  /**
   * @notice The constructor for the AxelarSourceBridge contract
   * @param _axelarGateway address - The address of the Axelar gateway contract on the source chain
   * @param _axelarGasService address - The address of the Axelar gas service contract on the source chain
   * @param _owner address - The address of the owner of the contract
   * @param _tokens address[] memory - The list of tokens to be initially supported by the bridge
   * @param _maxTransferSizes uint256[] memory - The list of maximum transfer sizes for each token
   * @param _dailyLimits uint256[] memory - The list of daily thresholds for each token
   * @dev The number of tokens, maximum transfer sizes, and daily limits must be the same
   * @dev Each token can't be the zero address
   * @dev Each maximum transfer size must be greater than zero
   * @dev Each daily limit must be greater than zero
   */
  constructor(
    address _axelarGateway,
    address _axelarGasService,
    address _owner,
    address[] memory _tokens,
    uint256[] memory _maxTransferSizes,
    uint256[] memory _dailyLimits
  ) Ownable(_owner) {
    require(
      _axelarGateway != address(0),
      "AxelarSourceBridge::constructor: Axelar gateway cannot be the zero address."
    );
    require(
      _axelarGasService != address(0),
      "AxelarSourceBridge::constructor: Axelar gas service cannot be the zero address."
    );
    require(_tokens.length > 0, "AxelarSourceBridge::constructor: The number of tokens must be greater than zero.");
    require(
      _tokens.length == _maxTransferSizes.length &&
        _tokens.length == _dailyLimits.length,
      "AxelarSourceBridge::constructor: The number of tokens, maximum transfer sizes, and daily limits must be the same."
    );

    axelarGateway = IAxelarGateway(_axelarGateway);
    axelarGasService = IAxelarGasService(_axelarGasService);

    CHAIN_ID = block.chainid;

    for (uint256 i = 0; i < _tokens.length; i++) {
      IRWAToken token = IRWAToken(_tokens[i]);
      uint256 maxTransferSize = _maxTransferSizes[i];
      uint256 dailyLimit = _dailyLimits[i];

      require(
        token != IRWAToken(address(0)),
        "AxelarSourceBridge::constructor: Token cannot be the zero address."
      );
      require(
        maxTransferSize > 0,
        "AxelarSourceBridge::constructor: Maximum transfer size must be greater than zero."
      );
      require(
        dailyLimit > 0,
        "AxelarSourceBridge::constructor: Daily limit must be greater than zero."
      );

      supportedTokens[token] = true;
      maxTransferSizes[token] = maxTransferSize;
      dailyLimits[token] = dailyLimit;

      emit TokenAdded(token, block.timestamp);
      emit MaxTransferSizeUpdated(token, maxTransferSize, block.timestamp);
      emit DailyLimitUpdated(token, dailyLimit, block.timestamp);
    }
  }

  /**
   * @notice Adds the specified destination chain to the list of supported destination chains by the bridge
   * @param _destinationChain string - The destination chain to be added
   * @param _bridgeAddress string - The address of the bridge contract on the destination chain
   * @dev Only the owner of the contract can call this function
   * @dev The destination chain cannot be the empty string
   * @dev The bridge address cannot be the empty string
   * @dev The destination chain must not be already supported by the bridge
   */
  function addDestinationChain(
    string calldata _destinationChain,
    address _bridgeAddress
  ) external onlyOwner {
    dstChainToBridge[_destinationChain] = AddressToString.toString(_bridgeAddress);
    emit DestinationChainAdded(_destinationChain, _bridgeAddress, block.timestamp);
  }

  /**
   * @notice Removes the specified destination chain from the list of supported destination chains by the bridge
   * @param _destinationChain string - The destination chain to be removed
   * @dev Only the owner of the contract can call this function
   * @dev The destination chain cannot be the empty string
   * @dev The destination chain must be already supported by the bridge
   */
  function removeDestinationChain(string calldata _destinationChain) external onlyOwner {
    delete dstChainToBridge[_destinationChain];
    emit DestinationChainRemoved(_destinationChain, block.timestamp);
  }

  /**
   * @notice Adds the specified token to the list of supported tokens by the bridge
   * @param _token address - The address of the token to be added
   * @param _maxTransferSize uint256 - The maximum transfer size for the token
   * @param _dailyLimit uint256 - The daily limit for the token
   * @dev Only the owner of the contract can call this function
   * @dev The token cannot be the zero address
   * @dev The daily limit must be greater than zero
   * @dev The token must not be already supported by the bridge
   * @dev Emits a {TokenAdded} and {DailyLimitUpdated} event
   */
  function addSupportedToken(
    address _token,
    uint256 _maxTransferSize,
    uint256 _dailyLimit
  ) external onlyOwner {
    IRWAToken token = IRWAToken(_token);

    require(
      token != IRWAToken(address(0)),
      "AxelarSourceBridge::addSupportedToken: Token cannot be the zero address."
    );
    require(
      _maxTransferSize > 0,
      "AxelarSourceBridge::addSupportedToken: Maximum transfer size must be greater than zero."
    );
    require(
      _dailyLimit > 0,
      "AxelarSourceBridge::addSupportedToken: Daily limit must be greater than zero."
    );
    require(
      supportedTokens[token] == false,
      "AxelarSourceBridge::addSupportedToken: Token is already supported by the bridge."
    );

    supportedTokens[token] = true;
    maxTransferSizes[token] = _maxTransferSize;
    dailyLimits[token] = _dailyLimit;

    emit TokenAdded(token, block.timestamp);
    emit MaxTransferSizeUpdated(token, _maxTransferSize, block.timestamp);
    emit DailyLimitUpdated(token, _dailyLimit, block.timestamp);
  }

  /**
   * @notice Removes the specified token from the list of supported tokens by the bridge
   * @param _token address - The address of the token to be removed
   * @dev Only the owner of the contract can call this function
   * @dev The token cannot be the zero address
   * @dev The token must be already supported by the bridge
   * @dev Emits a {TokenRemoved} and {DailyLimitUpdated} event
   */
  function removeSupportedToken(address _token) external onlyOwner {
    IRWAToken token = IRWAToken(_token);

    require(
      token != IRWAToken(address(0)),
      "AxelarSourceBridge::removeSupportedToken: Token cannot be the zero address."
    );
    require(
      supportedTokens[token] == true,
      "AxelarSourceBridge::removeSupportedToken: Token is not supported by the bridge."
    );

    supportedTokens[token] = false;
    maxTransferSizes[token] = 0;
    dailyLimits[token] = 0;

    emit TokenRemoved(token, block.timestamp);
    emit MaxTransferSizeUpdated(token, 0, block.timestamp);
    emit DailyLimitUpdated(token, 0, block.timestamp);
  }

  /**
   * @notice Updates the maximum transfer size for the specified token
   * @param _token address - The address of the token to be updated
   * @param _newMaxTransferSize uint256 - The new maximum transfer size for the token
   * @dev Only the owner of the contract can call this function
   * @dev The token cannot be the zero address
   * @dev The token must be already supported by the bridge
   * @dev The new maximum transfer size must be greater than zero
   * @dev Emits a {MaxTransferSizeUpdated} event
   */
  function updateMaxTransferSize(
    address _token,
    uint256 _newMaxTransferSize
  ) external onlyOwner {
    IRWAToken token = IRWAToken(_token);

    require(
      token != IRWAToken(address(0)),
      "AxelarSourceBridge::updateMaxTransferSize: Token cannot be the zero address."
    );
    require(
      supportedTokens[token] == true,
      "AxelarSourceBridge::updateMaxTransferSize: Token is not supported by the bridge."
    );
    require(
      _newMaxTransferSize > 0,
      "AxelarSourceBridge::updateMaxTransferSize: New maximum transfer size must be greater than zero."
    );

    maxTransferSizes[token] = _newMaxTransferSize;

    emit MaxTransferSizeUpdated(token, _newMaxTransferSize, block.timestamp);
  }

  /**
   * @notice Updates the daily limit for the specified token
   * @param _token address - The address of the token to be updated
   * @param _newLimit uint256 - The new daily limit for the token
   * @dev Only the owner of the contract can call this function
   * @dev The token cannot be the zero address
   * @dev The token must be already supported by the bridge
   * @dev The new daily limit must be greater than zero
   * @dev Emits a {DailyLimitUpdated} event
   */
  function updateDailyLimit(
    address _token,
    uint256 _newLimit
  ) external onlyOwner {
    IRWAToken token = IRWAToken(_token);

    require(
      token != IRWAToken(address(0)),
      "AxelarSourceBridge::updateDailyLimit: Token cannot be the zero address."
    );
    require(
      supportedTokens[token] == true,
      "AxelarSourceBridge::updateDailyLimit: Token is not supported by the bridge."
    );
    require(
      _newLimit > 0,
      "AxelarSourceBridge::updateDailyLimit: New daily limit must be greater than zero."
    );

    dailyLimits[token] = _newLimit;

    emit DailyLimitUpdated(token, _newLimit, block.timestamp);
  }

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
    require(IERC20(_token).transfer(owner(), balance), "AxelarSourceBridge::rescueTokens: ERC20 transfer failed");
  }

  /**
   * @notice Initiates a bridge transaction by burning tokens on the source chain and calling Axelar gateway contract
   * @param _token address - The address of the token to be transferred
   * @param _amount uint256 - The amount of tokens to be transferred
   * @param _destinationChain string - The destination chain of the bridge transaction
   * @dev The token cannot be the zero address
   * @dev The amount of tokens and gas value both must be greater than zero
   * @dev The token must be already supported by the bridge
   * @dev The amount must be less than or equal to the maximum transfer size for the token
   * @dev The destination chain must be supported by the bridge
   * @dev The daily limit for the token must not be exceeded
   * @dev User must approve the contract to spend at least the amount of tokens to be transferred
   * @dev Emits a {BridgeInitiated} event
   */
  function initiateBridge(address _token, uint256 _amount, string calldata _destinationChain) external payable whenNotPaused {
    IRWAToken token = IRWAToken(_token);

    require(
      supportedTokens[token] == true,
      "AxelarSourceBridge::initiateBridge: Token is not supported by the bridge."
    );
    require(
      msg.value > 0,
      "AxelarSourceBridge::initiateBridge: Cannot send zero gas."
    );
    require(
      _amount > 0,
      "AxelarSourceBridge::initiateBridge: Cannot transfer zero tokens."
    );
    require(
      _amount <= maxTransferSizes[token],
      "AxelarSourceBridge::initiateBridge: Amount to be transferred is greater than the maximum transfer size."
    );

    string memory destinationBridgeAddress = dstChainToBridge[_destinationChain];
    require(
      bytes(destinationBridgeAddress).length > 0,
      "AxelarSourceBridge::initiateBridge: Destination chain is not supported by the bridge."
    );

    if (block.timestamp > lastDailyReset[token] + 1 days) {
      dailyTransferred[token] = 0;
      lastDailyReset[token] = block.timestamp;
    }
    require(
      dailyTransferred[token] + _amount <= dailyLimits[token],
      "AxelarSourceBridge::initiateBridge: Daily limit reached."
    );

    dailyTransferred[token] += _amount;

    token.burnFrom(msg.sender, _amount);

    bytes memory payload = abi.encode(
      VERSION,
      CHAIN_ID,
      msg.sender,
      _amount,
      nonce++
    );

    _payGasAndCallContract(_destinationChain, destinationBridgeAddress, payload);
    
    emit BridgeInitiated(
      msg.sender, 
      nonce - 1,
      CHAIN_ID,
      VERSION,
      _amount
    );
  }

  /**
   * @notice A private helper function for paying gas and calling the AxelarGateway contract
    * @param _destinationChain string - The destination chain of the bridge transaction
    * @param _destinationBridgeAddress string - The address of the bridge contract on the destination chain
    * @param _payload bytes - The payload of the bridge transaction
   */
  function _payGasAndCallContract(string calldata _destinationChain, string memory _destinationBridgeAddress, bytes memory _payload) private {
    axelarGasService.payNativeGasForContractCall{value: msg.value}(
      address(this),
      _destinationChain,
      _destinationBridgeAddress,
      _payload,
      msg.sender
    );

    axelarGateway.callContract(_destinationChain, _destinationBridgeAddress, _payload);
  }
}
