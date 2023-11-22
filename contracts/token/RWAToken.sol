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
   * @notice Mints the specified amount of tokens to the owner of the contract
   * @param _amount uint256 - The amount of tokens to mint
   * @dev The caller cannot mint zero tokens
   * @dev Only the owner (token issuer) of the contract can mint tokens
   */
  function mint(uint256 _amount) external onlyOwner {
    require(_amount > 0, "RWAToken::mint: Cannot mint zero tokens.");

    _mint(owner(), _amount);
  }
}
