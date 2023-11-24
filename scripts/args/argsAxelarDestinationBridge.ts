import hre from "hardhat";
import { getAxelarGateway } from "../../test/utils";

export default [
  getAxelarGateway(hre.network.name), // axelarGateway
  "0x2c16fF5e4de2F7B8c29593E9eb9FcfE5d9a10744", // owner
];
