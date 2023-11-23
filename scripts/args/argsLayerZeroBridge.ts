import { ethers } from "hardhat";

export default [
  "0x2c16fF5e4de2F7B8c29593E9eb9FcfE5d9a10744", // owner
  ["0x4c74013f2dDd453D7bB7ae48ED8A8dfbacf69aBB"], // initially supported tokens (RWATokenOFT, which has the same address on all networks, thanks to using a fresh address to deploy it)
  [ethers.parseEther("100000")], // max transfer amounts
  [ethers.parseEther("1000000")], // daily transfer limits
];
