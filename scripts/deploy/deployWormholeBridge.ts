import { ethers } from "hardhat";
import args from "../args/argsWormholeBridge";

async function main() {
  const wormholeBridge = await ethers.deployContract("WormholeBridge", args);
  await wormholeBridge.waitForDeployment();
  console.log(`WormholeBridge deployed to ${wormholeBridge.target}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
