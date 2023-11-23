// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

/**
 * @title IRWAToken
 * @notice An interface for the RWAToken contract
 * @dev Used for the Axelar and Wormhole bridge demos
 */
interface IRWAToken is IERC20 {
  function mint(uint256 _amount) external;
  function mintTo(address _receiver, uint256 _amount) external;
  function burn(uint256 _amount) external;
  function burnFrom(address _spender, uint256 _amount) external;
}
