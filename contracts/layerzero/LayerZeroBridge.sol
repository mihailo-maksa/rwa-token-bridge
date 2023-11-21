// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@layerzerolabs/solidity-examples/contracts/token/oft/v1/interfaces/IOFT.sol";

contract LayerZeroBridge is Ownable, Pausable {
  /// @notice The mapping of supported tokens by the bridge
  mapping(IOFT => bool) public supportedTokens;

  /// @notice The mapping of the maximum transfer sizes for each token
  mapping(IOFT => uint256) public maxTransferSizes;

  /// @notice The mapping of the daily limits for each token
  mapping(IOFT => uint256) public dailyLimits;

  /// @notice The mapping of the daily transferred amounts for each token in the last 24 hours
  mapping(IOFT => uint256) private dailyTransferred;

  /// @notice The mapping of the last daily reset for each token
  mapping(IOFT => uint256) private lastDailyReset;

  /// @notice An event emitted when a token is added to the list of supported tokens by the bridge
  event TokenAdded(IOFT indexed token, uint256 timestamp);

  /// @notice An event emitted when a token is removed from the list of supported tokens by the bridge
  event TokenRemoved(IOFT indexed token, uint256 timestamp);

  /// @notice An event emitted when a maximum transfer size is updated for a token
  event MaxTransferSizeUpdated(
    IOFT indexed token,
    uint256 newMaxTransferSize,
    uint256 timestamp
  );

  /// @notice An event emitted when a daily limit is updated for a token
  event DailyLimitUpdated(
    IOFT indexed token,
    uint256 newLimit,
    uint256 timestamp
  );

  /// @notice An event emitted when a token is transferred from one chain to another
  event BridgeTransfer(
    IOFT indexed token,
    address indexed sender,
    address indexed recipient,
    uint16 dstChainId,
    uint256 amount,
    uint256 timestamp
  );

  /**
   * @notice The constructor for the LayerZeroBridge contract
   * @param _tokens address[] memory - The list of tokens to be initially supported by the bridge
   * @param _maxTransferSizes uint256[] memory - The list of maximum transfer sizes for each token
   * @param _dailyLimits uint256[] memory - The list of daily thresholds for each token
   * @dev The number of tokens, maximum transfer sizes, and daily limits must be the same
   * @dev Each token can't be the zero address
   * @dev Each maximum transfer size must be greater than zero
   * @dev Each daily limit must be greater than zero
   */
  constructor(
    address[] memory _tokens,
    uint256[] memory _maxTransferSizes,
    uint256[] memory _dailyLimits
  ) Ownable(msg.sender) {
    require(
      _tokens.length == _maxTransferSizes.length &&
        _tokens.length == _dailyLimits.length,
      "LayerZeroBridge::constructor: The number of tokens, maximum transfer sizes, and daily limits must be the same."
    );

    for (uint256 i = 0; i < _tokens.length; i++) {
      IOFT token = IOFT(_tokens[i]);
      uint256 maxTransferSize = _maxTransferSizes[i];
      uint256 dailyLimit = _dailyLimits[i];

      require(
        token != IOFT(address(0)),
        "LayerZeroBridge::constructor: Token cannot be the zero address."
      );
      require(
        maxTransferSize > 0,
        "LayerZeroBridge::constructor: Maximum transfer size must be greater than zero."
      );
      require(
        dailyLimit > 0,
        "LayerZeroBridge::constructor: Daily limit must be greater than zero."
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
   * @notice Adds the specified token to the list of supported tokens by the bridge
   * @param _token address - The address of the token to be added
   * @param _dailyLimit uint256 - The daily limit for the token
   * @dev Only the owner of the contract can call this function
   * @dev The token cannot be the zero address
   * @dev The daily limit must be greater than zero
   * @dev The token must not be already supported by the bridge
   * @dev Emits a {TokenAdded} and {DailyLimitUpdated} event
   */
  function addSupportedToken(
    address _token,
    uint256 _dailyLimit
  ) external onlyOwner {
    IOFT token = IOFT(_token);

    require(
      token != IOFT(address(0)),
      "LayerZeroBridge::addSupportedToken: Token cannot be the zero address."
    );
    require(
      _dailyLimit > 0,
      "LayerZeroBridge::addSupportedToken: Daily limit must be greater than zero."
    );
    require(
      supportedTokens[token] == false,
      "LayerZeroBridge::addSupportedToken: Token is already supported by the bridge."
    );

    supportedTokens[token] = true;
    dailyLimits[token] = _dailyLimit;

    emit TokenAdded(token, block.timestamp);
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
    IOFT token = IOFT(_token);

    require(
      token != IOFT(address(0)),
      "LayerZeroBridge::removeSupportedToken: Token cannot be the zero address."
    );
    require(
      supportedTokens[token] == true,
      "LayerZeroBridge::removeSupportedToken: Token is not supported by the bridge."
    );

    supportedTokens[token] = false;
    dailyLimits[token] = 0;

    emit TokenRemoved(token, block.timestamp);
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
    IOFT token = IOFT(_token);

    require(
      token != IOFT(address(0)),
      "LayerZeroBridge::updateMaxTransferSize: Token cannot be the zero address."
    );
    require(
      supportedTokens[token] == true,
      "LayerZeroBridge::updateMaxTransferSize: Token is not supported by the bridge."
    );
    require(
      _newMaxTransferSize > 0,
      "LayerZeroBridge::updateMaxTransferSize: New maximum transfer size must be greater than zero."
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
    IOFT token = IOFT(_token);

    require(
      token != IOFT(address(0)),
      "LayerZeroBridge::updateDailyLimit: Token cannot be the zero address."
    );
    require(
      supportedTokens[token] == true,
      "LayerZeroBridge::updateDailyLimit: Token is not supported by the bridge."
    );
    require(
      _newLimit > 0,
      "LayerZeroBridge::updateDailyLimit: New daily limit must be greater than zero."
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
   * @notice Transfers the specified amount of tokens from the caller's balance to the recipient's balance from one chain to another
   * @param _token address - The address of the token to be transferred
   * @param _recipient address - The address of the recipient
   * @param _dstChainId uint16 - The chain ID of the destination chain
   * @param _amount uint256 - The amount of tokens to be transferred
   * @dev The token must be supported by the bridge and cannot be the zero address
   * @dev The caller cannot transfer tokens if the daily limit is met
   * @dev The caller cannot transfer tokens if the bridge is paused
   * @dev The caller cannot transfer tokens to the zero address
   * @dev The caller cannot transfer tokens to the zero or invalid chain ID
   * @dev The caller cannot transfer zero tokens
   * @dev Token allowance must be greater than or equal to the amount of tokens to be transferred
   */
  function bridge(
    address _token,
    address _recipient,
    uint16 _dstChainId,
    uint256 _amount
  ) external payable whenNotPaused {
    IOFT token = IOFT(_token);

    require(
      supportedTokens[token] == true,
      "LayerZeroBridge::bridge: Token is not supported by the bridge."
    );
    require(
      _recipient != address(0),
      "LayerZeroBridge::bridge: Recipient cannot be the zero address."
    );
    require(
      _dstChainId != 0,
      "LayerZeroBridge::bridge: Chain ID cannot be zero."
    );
    require(
      _amount > 0,
      "LayerZeroBridge::bridge: Cannot transfer zero tokens."
    );
    require(
      token.allowance(msg.sender, address(this)) >= _amount,
      "LayerZeroBridge::bridge: Token allowance is less than the amount to be transferred."
    );
    require(
      _amount <= maxTransferSizes[token],
      "LayerZeroBridge::bridge: Amount to be transferred is greater than the maximum transfer size."
    );

    if (block.timestamp > lastDailyReset[token] + 1 days) {
      dailyTransferred[token] = 0;
      lastDailyReset[token] = block.timestamp;
    }
    require(
      dailyTransferred[token] + _amount <= dailyLimits[token],
      "LayerZeroBridge::bridge: Daily limit reached."
    );

    dailyTransferred[token] += _amount;

    token.sendFrom{value: msg.value}(
      msg.sender,
      _dstChainId,
      abi.encodePacked(_recipient),
      _amount,
      payable(msg.sender),
      address(0),
      bytes("")
    );

    emit BridgeTransfer(
      token,
      msg.sender,
      _recipient,
      _dstChainId,
      _amount,
      block.timestamp
    );
  }

  /**
   * @notice Estimates the LayerZero protocol fees for transferring the specified amount of tokens from the caller's balance to the recipient's balance from one chain to another
   * @param _token address - The address of the token to be transferred
   * @param _dstChainId uint16 - The chain ID of the destination chain
   * @param _recipient address - The address of the recipient
   * @param _amount uint256 - The amount of tokens to be transferred
   * @param _useZro bool - Whether to use ZRO tokens for the transfer fee
   * @param _adapterParams bytes memory - The adapter parameters (specifying variables such as version, gas limit, native token airdrop on the destination chain, etc.)
   */
  function estimateSendFee(
    address _token,
    uint16 _dstChainId,
    address _recipient,
    uint256 _amount,
    bool _useZro,
    bytes memory _adapterParams
  ) public view returns (uint256, uint256) {
    IOFT token = IOFT(_token);
    bytes memory recipient = abi.encodePacked(_recipient);

    (uint256 nativeFee, uint256 zroFee) = token.estimateSendFee(
      _dstChainId,
      recipient,
      _amount,
      _useZro,
      _adapterParams
    );
    return (nativeFee, zroFee);
  }
}
