// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@layerzerolabs/solidity-examples/contracts/token/oft/v1/OFT.sol";

/**
 * @title RWAToken
 * @author Mihailo Maksa
 * @notice Simple ERC20 token representing a tokenized real world asset (RWA)
 */
contract RWAToken is Ownable, OFT, Pausable {
  /// @notice The boolean flag that indicates whether this is the main chain or not
  bool public isMain;

  /**
   * @notice The constructor for the RWAToken contract
   * @param _name string memory - Name of the token
   * @param _symbol string memory - Symbol of the token
   * @param _lzEndpoint address - The address of the LayerZero endpoint on the chain of deployment
   * @param _mainChainId uint16 - The chain ID of the main chain
   * @param _initialSupplyOnMainChain uint256 - The initial supply of the token on the main chain
   * @dev The LayerZero endpoint cannot be the zero address
   * @dev The main chain ID cannot be zero
   * @dev The initial supply on main chain must be greater than zero
   */
  constructor(
    string memory _name, 
    string memory _symbol, 
    address _lzEndpoint, 
    uint16 _mainChainId, 
    uint256 _initialSupplyOnMainChain
  )
  Ownable(msg.sender)
  OFT(_name, _symbol, _lzEndpoint) 
  {
    require(_lzEndpoint != address(0), "RWAToken::constructor: LayerZero endpoint cannot be the zero address.");
    require(_mainChainId != 0, "RWAToken::constructor: Main chain ID cannot be zero.");
    require(_initialSupplyOnMainChain > 0, "RWAToken::constructor: Initial supply of the token on the main chain must be greater than zero.");

    if (ILayerZeroEndpoint(_lzEndpoint).getChainId() == _mainChainId) {
      isMain = true;
      _mint(msg.sender, _initialSupplyOnMainChain);
    }
  }

  /**
   * @notice Mints the specified amount of tokens from the caller's balance
   * @param _amount uint256 - The amount of tokens to burn
   * @dev The caller cannot mint zero tokens
   */
  function mint(uint256 _amount) external whenNotPaused {
    require(_amount > 0, "RWAToken::mint: Cannot mint zero tokens.");

    _mint(msg.sender, _amount);
  }

  /**
   * @notice Burns the specified amount of tokens from the caller's balance
   * @param _amount uint256 - The amount of tokens to burn
   * @dev The caller cannot burn zero tokens
   * @dev The caller cannot burn more tokens than they have
   */
  function burn(uint256 _amount) external whenNotPaused {
    require(_amount > 0, "RWAToken::burn: Cannot burn zero tokens.");
    require(
      balanceOf(msg.sender) >= _amount,
      "RWAToken::burn: Burn amount exceeds balance."
    );

    _burn(msg.sender, _amount);
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
}
