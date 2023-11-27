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

  /// @notice Address of the Axelar Gateway contract
  IAxelarGateway public immutable axelarGateway;

  /// @notice The mapping of supported tokens by the bridge
  mapping(IRWAToken => bool) public supportedTokens;

  /// @notice Mapping of supported chains to the address of the source bridge contract on that chain
  mapping(string => string) public srcChainToSrcBridge;

  /// @notice Mapping of spent nonces for a given sender (i.e. source bridge contract address)
  mapping(string => mapping(uint256 => bool)) public isSpentNonce;

  /// events: ChainAdded, ChainRemoved, MessageReceived, BridgeCompleted

  /// @notice An event emitted when a new chain is added to the bridge
  event ChainSupportAdded(
    string indexed srcChain,
    string indexed srcContractAddress,
    uint256 timestamp
  );

  /// @notice An event emitted when a chain is removed from the bridge
  event ChainSupportRemoved(string indexed srcChain, uint256 timestamp);

  /// @notice An even emitted when a supported token is added to the bridge
  event TokenSupportAdded(address indexed token, uint256 timestamp);

  /// @notice An event emitted when a supported token is removed from the bridge
  event TokenSupportRemoved(address indexed token, uint256 timestamp);

  /// @notice An event emitted when a bridge transfer is completed
  event BridgeCompleted(
    address indexed token,
    address indexed sender,
    uint256 amount,
    uint256 nonce,
    uint256 timestamp
  );

  /**
   * @notice Constructor function
   * @param _axelarGateway address - The address of the Axelar Gateway contract
   * @param _owner address - The address of the owner of the contract
   * @dev Axelar gateway address cannot be the zero address
   */
  constructor(
    address _axelarGateway,
    address _owner
  ) AxelarExecutable(_axelarGateway) Ownable(_owner) {
    require(
      _axelarGateway != address(0),
      "AxelarDestinationBridge::constructor: Axelar gateway cannot be the zero address."
    );

    CHAIN_ID = block.chainid;
    axelarGateway = IAxelarGateway(_axelarGateway);
  }

  /**
   * @notice Internal overriden function that is executed when contract is called by Axelar Relayer
   * @param srcChain string calldata - The string of the source chain eg: arbitrum
   * @param srcAddr string calldata - The string of the address of the source contract
   * @param payload string calldata - The payload to pass cross chain
   */
  function _execute(
    string calldata srcChain,
    string calldata srcAddr,
    bytes calldata payload
  ) internal override whenNotPaused {
    (
      address _token,
      bytes32 version,
      ,
      address srcSender,
      uint256 amount,
      uint256 nonce
    ) = abi.decode(
        payload,
        (address, bytes32, uint256, address, uint256, uint256)
      );

    IRWAToken token = IRWAToken(_token);
    string memory srcBridge = srcChainToSrcBridge[srcChain];

    require(
      supportedTokens[token],
      "AxelarDestinationBridge::_execute: Unsupported token."
    );
    require(
      version == VERSION,
      "AxelarDestinationBridge::_execute: Invalid version."
    );
    require(
      areStringsEqual(srcBridge, srcAddr),
      "AxelarDestinationBridge::_execute: Source bridge address does not match."
    );
    require(
      !isSpentNonce[srcBridge][nonce],
      "AxelarDestinationBridge::_execute: Nonce already spent."
    );

    isSpentNonce[srcBridge][nonce] = true;

    token.mintTo(srcSender, amount);

    emit BridgeCompleted(_token, srcSender, amount, nonce, block.timestamp);
  }

  /**
   * @notice Admin function that will add support for a new token
   * @param srcChain string calldata - The address of the token to add
   * @param srcContractAddress string calldata - The address of the token to add
   * @dev Source chain cannot be empty
   * @dev Source contract address cannot be empty
   */
  function addChainSupport(
    string calldata srcChain,
    string calldata srcContractAddress
  ) external onlyOwner {
    require(
      !areStringsEqual(srcChain, ""),
      "AxelarDestinationBridge::addChainSupport: Source chain cannot be empty."
    );
    require(
      !areStringsEqual(srcContractAddress, ""),
      "AxelarDestinationBridge::addChainSupport: Source contract address cannot be empty."
    );

    srcChainToSrcBridge[srcChain] = srcContractAddress;

    emit ChainSupportAdded(srcChain, srcContractAddress, block.timestamp);
  }

  /**
   * @notice Admin function that will remove support for a token
   * @param srcChain string calldata - The address of the token to remove
   */
  function removeChainSupport(string calldata srcChain) external onlyOwner {
    delete srcChainToSrcBridge[srcChain];
    emit ChainSupportRemoved(srcChain, block.timestamp);
  }

  /**
   * @notice Admin function that will add support for a new token
   * @param _token address - The address of the token to add
   * @dev Token address cannot be the zero address
   * @dev Token cannot already be supported by the bridge
   */
  function addSupportedToken(address _token) external onlyOwner {
    IRWAToken token = IRWAToken(_token);

    require(
      token != IRWAToken(address(0)),
      "AxelarDestinationBridge::addSupportedToken: Token cannot be the zero address."
    );
    require(
      !supportedTokens[token],
      "AxelarDestinationBridge::addSupportedToken: Token already supported by the bridge."
    );

    supportedTokens[token] = true;

    emit TokenSupportAdded(_token, block.timestamp);
  }

  /**
   * @notice Admin function that will remove support for a token
   * @param _token address - The address of the token to remove
   * @dev Token address cannot be the zero address
   * @dev Token must be supported by the bridge
   */
  function removeSupportedToken(address _token) external onlyOwner {
    IRWAToken token = IRWAToken(_token);

    require(
      token != IRWAToken(address(0)),
      "AxelarDestinationBridge::removeSupportedToken: Token cannot be the zero address."
    );
    require(
      supportedTokens[token],
      "AxelarDestinationBridge::removeSupportedToken: Token not supported by the bridge."
    );

    supportedTokens[token] = false;

    emit TokenSupportRemoved(_token, block.timestamp);
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
   * @param _token address - The address of the token to rescue
   */
  function rescueTokens(address _token) external onlyOwner {
    uint256 balance = IERC20(_token).balanceOf(address(this));
    require(
      IERC20(_token).transfer(owner(), balance),
      "AxelarDestinationBridge::rescueTokens: ERC20 transfer failed"
    );
  }

  /**
   * @notice Internal function used to check if two strings are equal
   * @param str1 string memory - The first string to compare
   * @param str2 string memory - The second string to compare
   * @return bool - Whether the two strings are equal
   */
  function areStringsEqual(
    string memory str1,
    string memory str2
  ) internal pure returns (bool) {
    return
      keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2));
  }
}
