import hre from "hardhat";
import { getLzEndpoint } from "../../test/utils";

// BSC Testnet
// lzChainId: 10102
// RWATokenOFT: 0x4c74013f2dDd453D7bB7ae48ED8A8dfbacf69aBB
// LayerZeroBridge: 0x9804Ca3c7A9d2fD5Db3257c6Ed1f7c3eFeD253d4

// Arbitrum Goerli
// lzChainId: 10143
// RWATokenOFT: 0x4c74013f2dDd453D7bB7ae48ED8A8dfbacf69aBB
// LayerZeroBridge: 0x9804Ca3c7A9d2fD5Db3257c6Ed1f7c3eFeD253d4

// Polygon Mumbai
// lzChainId: 10109
// RWATokenOFT: 0x4c74013f2dDd453D7bB7ae48ED8A8dfbacf69aBB
// LayerZeroBridge: 0x9804Ca3c7A9d2fD5Db3257c6Ed1f7c3eFeD253d4

export default [
  "0x2c16fF5e4de2F7B8c29593E9eb9FcfE5d9a10744", // owner
  "RWA Token", // token name
  "RWA", // token symbol
  getLzEndpoint(hre.network.name), // LayerZero endpoint
];
