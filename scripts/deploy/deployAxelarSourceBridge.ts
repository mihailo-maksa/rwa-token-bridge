import { ethers } from "hardhat";
import args from "../args/argsAxelarSourceBridge";

async function main() {
  const axelarSourceBridge = await ethers.deployContract(
    "AxelarSourceBridge",
    args,
  );
  await axelarSourceBridge.waitForDeployment();
  console.log(`AxelarSourceBridge deployed to ${axelarSourceBridge.target}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
