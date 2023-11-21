import { ethers } from "hardhat";
import args from "./argsAxelarBridge";

async function main() {
  const axelarBridge = await ethers.deployContract("AxelarBridge", args);
  await axelarBridge.waitForDeployment();
  console.log(`AxelarBridge deployed to ${axelarBridge.target}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
