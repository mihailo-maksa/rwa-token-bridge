import { ethers } from "hardhat";
import args from "./argsLayerZeroBridge";

async function main() {
  const layerZeroBridge = await ethers.deployContract("LayerZeroBridge", args);
  await layerZeroBridge.waitForDeployment();
  console.log(`LayerZeroBridge deployed to ${layerZeroBridge.target}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
