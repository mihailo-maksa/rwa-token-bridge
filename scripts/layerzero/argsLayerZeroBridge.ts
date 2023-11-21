import hre, { ethers } from "hardhat";

export default [
  [hre.network.name === "goerli" ? "0x" : "0x"],
  [ethers.parseEther("100000")],
  [ethers.parseEther("1000000")],
];
