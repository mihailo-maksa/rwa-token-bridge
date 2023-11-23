// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@layerzerolabs/solidity-examples/contracts/token/oft/v1/interfaces/IOFT.sol";

/**
 * @title IRWATokenOFT
 * @notice An interface for the RWATokenOFT contract
 * @dev Used for the LayerZero bridge demo
 */
interface IRWATokenOFT is IOFT {
  function mint(uint256 _amount) external;
  function burn(uint256 _amount) external;
  function burnFrom(address _spender, uint256 _amount) external;
}
