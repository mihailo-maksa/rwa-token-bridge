import { ethers } from "hardhat";
import args from "../args/argsRWAToken";

async function main() {
  const rwaToken = await ethers.deployContract("RWAToken", args);
  await rwaToken.waitForDeployment();
  console.log(`RWAToken deployed to: ${rwaToken.target}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
