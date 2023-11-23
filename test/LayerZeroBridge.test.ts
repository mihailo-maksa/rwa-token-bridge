import { expect } from "chai";
import hre, { ethers } from "hardhat";
import { Contract, Signer, Wallet } from "ethers";

// npx hardhat test test/LayerZeroBridge.test.ts

describe("LayerZero bridge implementation", function () {
  let owner: any;
  let user1: any;
  let user2: any;
  let bscLzEndpointMock: Contract;
  let arbLzEndpointMock: Contract;
  let rwaTokenOFTBsc: Contract;
  let rwaTokenOFTArb: Contract;
  let layerZeroBridgeBsc: Contract;
  let layerZeroBridgeArb: Contract;

  before(async function () {
    [owner, user1, user2] = await ethers.getSigners();

    // @ts-ignore
    bscLzEndpointMock = await ethers.deployContract("LzEndpointMock", [1]);
    await bscLzEndpointMock.waitForDeployment();

    // @ts-ignore
    arbLzEndpointMock = await ethers.deployContract("LzEndpointMock", [2]);
    await arbLzEndpointMock.waitForDeployment();

    // @ts-ignore
    rwaTokenOFTBsc = await ethers.deployContract("RWATokenOFT", [
      owner.address,
      "RWA Token",
      "RWA",
      bscLzEndpointMock.getAddress(),
    ]);
    await rwaTokenOFTBsc.waitForDeployment();

    // @ts-ignore
    rwaTokenOFTArb = await ethers.deployContract("RWATokenOFT", [
      owner.address,
      "RWA Token",
      "RWA",
      arbLzEndpointMock.getAddress(),
    ]);
    await rwaTokenOFTArb.waitForDeployment();

    // @ts-ignore
    layerZeroBridgeBsc = await ethers.deployContract("LayerZeroBridge", [
      owner.address,
      [rwaTokenOFTBsc.getAddress()],
      [ethers.parseEther("100000")],
      [ethers.parseEther("1000000")],
    ]);
    await layerZeroBridgeBsc.waitForDeployment();

    // @ts-ignore
    layerZeroBridgeArb = await ethers.deployContract("LayerZeroBridge", [
      owner.address,
      [rwaTokenOFTArb.getAddress()],
      [ethers.parseEther("100000")],
      [ethers.parseEther("1000000")],
    ]);
    await layerZeroBridgeArb.waitForDeployment();

    await bscLzEndpointMock.setDestLzEndpoint(
      rwaTokenOFTArb.getAddress(),
      arbLzEndpointMock.getAddress(),
    );
    await arbLzEndpointMock.setDestLzEndpoint(
      rwaTokenOFTBsc.getAddress(),
      bscLzEndpointMock.getAddress(),
    );
  });

  describe("RWATokenOFT", function () {
    it("Should mint 1 million tokens to the owner", async function () {
      await rwaTokenOFTBsc.mint(owner.address, ethers.parseEther("1000000"));

      expect(await rwaTokenOFTBsc.balanceOf(owner.address)).to.equal(
        ethers.parseEther("1000000"),
      );

      await rwaTokenOFTBsc.transfer(user1.address, ethers.parseEther("10000"));
      await rwaTokenOFTBsc.transfer(user2.address, ethers.parseEther("10000"));
    });

    it("Should fail to mint tokens to the user1", async function () {
      await expect(
        rwaTokenOFTBsc.mint(user1.address, ethers.parseEther("1000000")),
      ).to.be.reverted;
    });

    it("Should burn 10k tokens from the owner", async function () {
      await rwaTokenOFTBsc.burn(owner.address, ethers.parseEther("10000"));

      expect(await rwaTokenOFTBsc.balanceOf(owner.address)).to.equal(
        ethers.parseEther("970000"),
      );
    });

    it("Should fail to burn tokens from the user1 when allowance is not set", async function () {
      await expect(rwaTokenOFTBsc.burn(user1.address, ethers.parseEther("500")))
        .to.be.reverted;
    });

    it("Should set allowance for user1 and burn 500 tokens", async function () {
      await rwaTokenOFTBsc.approve(user1.address, ethers.parseEther("500"));

      expect(
        await rwaTokenOFTBsc.allowance(owner.address, user1.address),
      ).to.equal(ethers.parseEther("500"));

      await rwaTokenOFTBsc.burn(user1.address, ethers.parseEther("500"));
      expect(await rwaTokenOFTBsc.balanceOf(user1.address)).to.equal(
        ethers.parseEther("9500"),
      );
    });
  });

  describe("LayerZeroBridge", function () {});
});
