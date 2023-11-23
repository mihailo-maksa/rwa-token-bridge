import { ethers } from "hardhat";
import args from "../args/argsRWATokenOFT";

async function main() {
  const rwaTokenOFT = await ethers.deployContract("RWATokenOFT", args);
  await rwaTokenOFT.waitForDeployment();
  console.log(`LayerZero RWATokenOFT deployed to ${rwaTokenOFT.target}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
