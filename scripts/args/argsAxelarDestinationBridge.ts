import hre from "hardhat";
import { getAxelarGateway } from "../../test/utils";

export default [
  getAxelarGateway(hre.network.name), // axelarGateway
  "0x2c16fF5e4de2F7B8c29593E9eb9FcfE5d9a10744", // owner
];

// npx hardhat verify 0x9d9eEaC5Db74d596A40036Ba72CEe5c1c6EfA6b1 --network bscTestnet --constructor-args scripts/args/argsAxelarDestinationBridge.ts
// npx hardhat verify 0xE72a76a5A8310a3613c4d6A59dBaCcd2fA387CAD --network arbitrumGoerli --constructor-args scripts/args/argsAxelarDestinationBridge.ts
// npx hardhat verify 0xc47Cc7d83A74693E60117bD0000fb76DFC3FDe3A --network mumbai --constructor-args scripts/args/argsAxelarDestinationBridge.ts
