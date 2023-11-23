// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@layerzerolabs/solidity-examples/contracts/token/oft/v1/OFT.sol";

/**
 * @title RWAToken
 * @author Mihailo Maksa
 * @notice Simple OFT (omnichain fungible token) ERC20 token representing a tokenized real world asset (RWA) for the LayerZero bridge demo
 */
contract RWATokenOFT is Ownable, OFT {
  /**
   * @notice The constructor for the RWAToken contract
   * @param _name string memory - Name of the token
   * @param _symbol string memory - Symbol of the token
   * @param _lzEndpoint address - The address of the LayerZero endpoint on the chain of deployment
   * @param _owner address - The address of the owner of the contract
   * @dev The LayerZero endpoint cannot be the zero address
   * @dev The main chain ID cannot be zero
   * @dev The initial supply on main chain must be greater than zero
   */
  constructor(
    address _owner,
    string memory _name,
    string memory _symbol,
    address _lzEndpoint
  ) Ownable(_owner) OFT(_name, _symbol, _lzEndpoint) {}

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
   * @notice Burns the specified amount of tokens from the caller's balance
   * @param _amount uint256 - The amount of tokens to burn
   * @dev The caller cannot burn zero tokens
   * @dev The caller cannot burn more tokens than they have
   */
  function burn(uint256 _amount) external {
    require(_amount > 0, "RWAToken::burn: Cannot burn zero tokens.");
    require(
      balanceOf(msg.sender) >= _amount,
      "RWAToken::burn: Burn amount exceeds balance."
    );

    _burn(msg.sender, _amount);
  }

  /**
   * @notice Burns the specified amount of tokens from the caller's allowance
   * @param _spender address - The address of the account to spend from
   * @param _amount uint256 - The amount of tokens to burn
   * @dev The caller cannot burn zero tokens
   * @dev The caller cannot burn more tokens than they have
   * @dev The caller cannot burn more tokens than the allowance
   */
  function burnFrom(address _spender, uint256 _amount) external {
    require(_amount > 0, "RWAToken::burnFrom: Cannot burn zero tokens.");
    require(
      balanceOf(_spender) >= _amount,
      "RWAToken::burnFrom: Burn amount exceeds balance."
    );
    require(
      allowance(_spender, msg.sender) >= _amount,
      "RWAToken::burnFrom: Burn amount exceeds allowance."
    );

    _burn(_spender, _amount);
  }
}
