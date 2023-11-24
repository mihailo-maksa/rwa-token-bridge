// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/**
 * @title RWAToken
 * @author Mihailo Maksa
 * @notice Simple ERC20 token representing a tokenized real world asset (RWA) for the Axelar and Wormhole bridge demos
 */
contract RWAToken is Ownable, ERC20Burnable {
  /// @notice Address of the bridge contract allowed to mint tokens
  address public bridge;

  /// @notice An event emitted when bridge contract address is set
  event BridgeSet(address indexed bridge);

  /**
   * @notice Modifier that only allows the bridge contract to call a function
   * @dev The caller must be the bridge contract
   */
  modifier onlyBridge() {
    require(
      msg.sender == bridge,
      "RWAToken::onlyBridge: Caller is not the bridge contract."
    );
    _;
  }

  /**
   * @notice The constructor for the RWAToken contract
   * @param _owner address - The address of the owner of the contract
   * @param _name string memory - Name of the token
   * @param _symbol string memory - Symbol of the token
   */
  constructor(
    address _owner,
    string memory _name,
    string memory _symbol
  ) Ownable(_owner) ERC20(_name, _symbol) {}

  /**
   * @notice Sets the address of the bridge contract
   * @param _bridge address - The address of the bridge contract
   * @dev Only the owner (token issuer) of the contract can set the bridge address
   */
  function setBridge(address _bridge) external onlyOwner {
    require(
      _bridge != address(0),
      "RWAToken::setBridge: Bridge cannot be the zero address."
    );

    bridge = _bridge;

    emit BridgeSet(_bridge);
  }

  /**
   * @notice Mints the specified amount of tokens to the owner of the contract
   * @param _amount uint256 - The amount of tokens to mint
   * @dev The caller cannot mint zero tokens
   * @dev Only the owner (token issuer) of the contract can mint tokens
   */
  function mint(uint256 _amount) external onlyOwner {
    require(_amount > 0, "RWAToken::mint: Cannot mint zero tokens.");

    _mint(owner(), _amount);
  }

  /**
   * @notice Mints the specified amount of tokens to the specified receiver
   * @param _receiver address - The address of the receiver of the tokens
   * @param _amount uint256 - The amount of tokens to mint
   * @dev The caller cannot mint zero tokens
   * @dev Internal function that is intended to only be called by the destination bridge contract
   */
  function mintTo(address _receiver, uint256 _amount) public onlyBridge {
    require(_amount > 0, "RWAToken::mint: Cannot mint zero tokens.");

    _mint(_receiver, _amount);
  }
}
