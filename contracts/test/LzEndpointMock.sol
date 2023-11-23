// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@layerzerolabs/solidity-examples/contracts/lzApp/mocks/LZEndpointMock.sol";

/**
 * @title LzEndpointMock
 * @notice A mock contract for the LayerZero endpoint
 * @dev Used for the LayerZero bridge demo to simulate the LayerZero endpoint
 */
contract LzEndpointMock is LZEndpointMock {
  /**
   * @notice The constructor for the LzEndpointMock contract
   * @param _chainId uint16 - The chain ID of the mock endpoint
   * @dev The chain ID can be any integer value valid for uint16 type
   */
  constructor(uint16 _chainId) LZEndpointMock(_chainId) {}
}
