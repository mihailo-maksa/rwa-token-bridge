import { ethers } from "hardhat";
import args from "../args/argsAxelarDestinationBridge";

async function main() {
  const axelarDestinationBridge = await ethers.deployContract(
    "AxelarDestinationBridge",
    args,
  );
  await axelarDestinationBridge.waitForDeployment();
  console.log(
    `AxelarDestinationBridge deployed to ${axelarDestinationBridge.target}`,
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
