import { ethers } from "hardhat";
import args from "./argsRWAToken";

async function main() {
  const rwaToken = await ethers.deployContract("RWAToken", args);
  await rwaToken.waitForDeployment();
  console.log(`LayerZero RWAToken deployed to ${rwaToken.target}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
