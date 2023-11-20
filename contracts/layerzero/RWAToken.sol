// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@layerzerolabs/solidity-examples/contracts/token/oft/OFT.sol";

/**
 * @title RWAToken
 * @author Mihailo Maksa
 * @notice Simple ERC20 token representing a real world asset (RWA)
 */
contract RWAToken is Ownable, OFT, Pausable {
  /**
   * @notice The constructor for the RWAToken contract
   * @param _name string memory - Name of the token
   * @param _symbol string memory - Symbol of the token
   * @param _lzEndpoint address - The address of the LayerZero endpoint on the chain of deployment
   * @param _mainChainId uint16 - The chain ID of the main chain
   * @param _initialSupplyOnMainChain uint256 - The initial supply of the token on the main chain
   * @dev The LayerZero endpoint cannot be the zero address
   * @dev The main chain ID cannot be zero
   * @dev The initial supply value must be greater than zero
  */
  constructor(
    string memory _name,
    string memory _symbol,
    uint256 _maxSupply, 
    address _owner
  ) ERC20(_name, _symbol) {
    require(_maxSupply > 0, "MyERC20: Max supply must be greater than zero.");
    require(_owner != address(0), "MyERC20: Owner cannot be the zero address.");

    maxSupply = _maxSupply;

    _mint(_owner, maxSupply);

    transferOwnership(_owner);
  }

  /**
   * @notice Burns the specified `amount` of tokens from the caller's balance
   * @param _amount uint256 - The amount of tokens to burn
   * @dev The caller cannot burn zero tokens
   * @dev The caller must have at least the `_amount` of tokens in their balance
   * @dev The total supply of tokens will be reduced by the `_amount`
   */
  function mint(uint256 _amount) external whenNotPaused {
    require(_amount > 0, "RWAToken: Cannot mint zero tokens.");

    _mint(msg.sender, _amount);
  }

  /**
   * @notice Burns the specified `amount` of tokens from the caller's balance
   * @param _amount uint256 - The amount of tokens to burn
   * @dev The caller cannot burn zero tokens
   * @dev The caller must have at least the `_amount` of tokens in their balance
   * @dev The total supply of tokens will be reduced by the `_amount`
   */
  function burn(uint256 _amount) external whenNotPaused {
    require(_amount > 0, "MyERC20: Cannot burn zero tokens.");
    require(
      balanceOf(msg.sender) >= _amount,
      "MyERC20: Burn amount exceeds balance."
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
