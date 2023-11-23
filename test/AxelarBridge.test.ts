import { expect } from "chai";
import { ethers } from "hardhat";
import { Contract, Signer, Wallet } from "ethers";
import { delay } from "./utils";

describe("Axelar Bridge smart contract system", function () {
  let owner: any;
  let user1: any;
  let user2: any;
  let rwaTokenBsc: Contract;
  let rwaTokenArb: Contract;
  let additionalToken: Contract;
  let axelarSourceBridgeBsc: Contract;
  let axelarDestinationBridgeBsc: Contract;
  let axelarSourceBridgeArb: Contract;
  let axelarDestinationBridgeArb: Contract;
  let axelarGatewayBsc: Contract;
  let axelarGatewayArb: Contract;
  let axelarGasServiceBsc: Contract;
  let axelarGasServiceArb: Contract;

  before(async function () {
    [owner, user1, user2] = await ethers.getSigners();

    // @ts-ignore
    rwaTokenBsc = await ethers.deployContract("RWAToken", [
      owner.address,
      "RWA Token",
      "RWA",
    ]);
    await rwaTokenBsc.waitForDeployment();

    // @ts-ignore
    rwaTokenArb = await ethers.deployContract("RWAToken", [
      owner.address,
      "RWA Token",
      "RWA",
    ]);
    await rwaTokenArb.waitForDeployment();

    // @ts-ignore
    additionalToken = await ethers.deployContract("RWAToken", [
      owner.address,
      "RWA Token",
      "RWA",
    ]);
    await additionalToken.waitForDeployment();

    // @ts-ignore
    // axelarSourceBridgeBsc = await ethers.deployContract("AxelarSourceBridge", [
    //   axelarGatewayBsc.getAddress(),
    //   axelarGasServiceBsc.getAddress(),
    //   owner.address,
    //   [rwaTokenBsc.address],
    //   [ethers.parseEther("100000")],
    //   [ethers.parseEther("1000000")],
    // ]);
    // await axelarSourceBridgeBsc.waitForDeployment();

    // @ts-ignore
    // axelarDestinationBridgeBsc = await ethers.deployContract(
    //   "AxelarDestinationBridge",
    //   [],
    // );
    // await axelarDestinationBridgeBsc.waitForDeployment();

    // @ts-ignore
    // axelarSourceBridgeArb = await ethers.deployContract("AxelarSourceBridge", [
    //   axelarGatewayArb.getAddress(),
    //   axelarGasServiceArb.getAddress(),
    //   owner.address,
    //   [rwaTokenArb.address],
    //   [ethers.parseEther("100000")],
    //   [ethers.parseEther("1000000")],
    // ]);
    // await axelarSourceBridgeArb.waitForDeployment();

    // @ts-ignore
    // axelarDestinationBridgeArb = await ethers.deployContract(
    //   "AxelarDestinationBridge",
    //   [],
    // );
    // await axelarDestinationBridgeArb.waitForDeployment();
  });

  describe("RWAToken", function () {
    it("Should mint 1 million tokens to owner", async function () {
      await rwaTokenBsc.mint(ethers.parseEther("1000000"));

      expect(await rwaTokenBsc.balanceOf(owner.address)).to.equal(
        ethers.parseEther("1000000"),
      );
    });

    it("Should fail to mint tokens to user1", async function () {
      await expect(
        // @ts-ignore
        rwaTokenBsc.connect(user1).mint(ethers.parseEther("100000")),
      ).to.be.reverted;

      expect(await rwaTokenBsc.balanceOf(user1.address)).to.equal(
        ethers.parseEther("0"),
      );
    });

    it("Should send 1000 tokens from owner to user 1 and user 2", async function () {
      await rwaTokenBsc.transfer(user1.address, ethers.parseEther("1000"));
      await rwaTokenBsc.transfer(user2.address, ethers.parseEther("1000"));

      expect(await rwaTokenBsc.balanceOf(user1.address)).to.equal(
        ethers.parseEther("1000"),
      );
      expect(await rwaTokenBsc.balanceOf(user2.address)).to.equal(
        ethers.parseEther("1000"),
      );
    });
  });

  describe("AxelarSourceBridge", function () {});

  describe("AxelarDestinationBridge", function () {});
});

// npx hardhat test test/AxelarBridge.test.ts
