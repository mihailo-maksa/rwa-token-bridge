import hre, { ethers } from "hardhat";
import { getAxelarGateway, getAxelarGasService } from "../../test/utils";

export default [
  getAxelarGateway(hre.network.name), // axelarGateway
  getAxelarGasService(hre.network.name), // axelarGasService
  "0x2c16fF5e4de2F7B8c29593E9eb9FcfE5d9a10744", // owner
  ["0x202AEa9fC1401cF9a1629103A2b140E350e09C24"], // initially supported tokens (RWAToken, which has the same address on all networks, thanks to using a fresh address to deploy it)
  [ethers.parseEther("100000")], // max transfer amounts
  [ethers.parseEther("1000000")], // daily transfer limits
];
