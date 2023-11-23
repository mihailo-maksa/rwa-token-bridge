import hre from "hardhat";

// BSC Testnet
// lzChainId: 10102
// lzEndpoint: 0x6Fcb97553D41516Cb228ac03FdC8B9a0a9df04A1
// RWATokenOFT: 0x4c74013f2dDd453D7bB7ae48ED8A8dfbacf69aBB
// LayerZeroBridge: 0x9804Ca3c7A9d2fD5Db3257c6Ed1f7c3eFeD253d4

// Arbitrum Goerli
// lzChainId: 10143
// lzEndpoint: 0x6aB5Ae6822647046626e83ee6dB8187151E1d5ab
// RWATokenOFT: 0x4c74013f2dDd453D7bB7ae48ED8A8dfbacf69aBB
// LayerZeroBridge: 0x9804Ca3c7A9d2fD5Db3257c6Ed1f7c3eFeD253d4

// Polygon Mumbai
// lzChainId: 10109
// lzEndpoint: 0xf69186dfBa60DdB133E91E9A4B5673624293d8F8
// RWATokenOFT: 0x4c74013f2dDd453D7bB7ae48ED8A8dfbacf69aBB
// LayerZeroBridge: 0x9804Ca3c7A9d2fD5Db3257c6Ed1f7c3eFeD253d4

const getLzEndpoint = (network: string) => {
  switch (network) {
    case "bscTestnet":
      return "0x6Fcb97553D41516Cb228ac03FdC8B9a0a9df04A1";
    case "arbitrumGoerli":
      return "0x6aB5Ae6822647046626e83ee6dB8187151E1d5ab";
    case "mumbai":
      return "0xf69186dfBa60DdB133E91E9A4B5673624293d8F8";
    default:
      throw new Error("LayerZero endpoint address not found for the network");
  }
};

export default [
  "0x2c16fF5e4de2F7B8c29593E9eb9FcfE5d9a10744", // owner
  "RWA Token", // token name
  "RWA", // token symbol
  getLzEndpoint(hre.network.name), // LayerZero endpoint
];
