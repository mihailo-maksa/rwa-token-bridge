import hre, { ethers } from "hardhat";

export default [
  "RWA Token",
  "RWA",
  hre.network.name === "goerli" ? "0x" : "0x",
  ethers.parseEther("10000000"),
];
