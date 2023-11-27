import { expect } from "chai";
import { ethers } from "hardhat";
import { Contract, Signer, Wallet } from "ethers";
import { delay, getAxelarGateway, getAxelarGasService } from "./utils";

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
    axelarSourceBridgeBsc = await ethers.deployContract("AxelarSourceBridge", [
      getAxelarGateway("bscTestnet"),
      getAxelarGasService("bscTestnet"),
      owner.address,
      [rwaTokenBsc.getAddress()],
      [ethers.parseEther("100000")],
      [ethers.parseEther("1000000")],
    ]);
    await axelarSourceBridgeBsc.waitForDeployment();

    // @ts-ignore
    axelarDestinationBridgeBsc = await ethers.deployContract(
      "AxelarDestinationBridge",
      [getAxelarGateway("bscTestnet"), owner.address],
    );
    await axelarDestinationBridgeBsc.waitForDeployment();

    // @ts-ignore
    axelarSourceBridgeArb = await ethers.deployContract("AxelarSourceBridge", [
      getAxelarGateway("arbitrumGoerli"),
      getAxelarGasService("arbitrumGoerli"),
      owner.address,
      [rwaTokenArb.getAddress()],
      [ethers.parseEther("100000")],
      [ethers.parseEther("1000000")],
    ]);
    await axelarSourceBridgeArb.waitForDeployment();

    // @ts-ignore
    axelarDestinationBridgeArb = await ethers.deployContract(
      "AxelarDestinationBridge",
      [getAxelarGateway("arbitrumGoerli"), owner.address],
    );
    await axelarDestinationBridgeArb.waitForDeployment();
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

    it("Should fail to set the bridge address to zero address", async function () {
      await expect(rwaTokenBsc.setBridge(ethers.ZeroAddress)).to.be.reverted;
    });

    it("Should add destination bridge address as minter for the token and verify it's been added", async function () {
      await rwaTokenBsc.setBridge(axelarDestinationBridgeBsc.getAddress());

      expect(await rwaTokenBsc.bridge()).to.be.not.equal(ethers.ZeroAddress);
    });

    it("Should fail to mintTo when the caller is not the destination bridge for the chain", async function () {
      await expect(
        rwaTokenBsc.mintTo(user2.address, ethers.parseEther("100000")),
      ).to.be.reverted;

      expect(await rwaTokenBsc.balanceOf(user2.address)).to.equal(
        ethers.parseEther("0"),
      );
    });

    it("Should fail to both mint and mintTo zero tokens", async function () {
      await expect(rwaTokenBsc.mint(ethers.parseEther("0"))).to.be.reverted;
      await expect(rwaTokenBsc.mintTo(user2.address, ethers.parseEther("0"))).to
        .be.reverted;
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

  describe("AxelarSourceBridge", function () {
    it("Should add destination chain for bsc source bridge to arb", async function () {
      await axelarSourceBridgeBsc.addDestinationChain(
        "arbitrum",
        axelarDestinationBridgeArb.getAddress(),
      );

      expect(
        await axelarSourceBridgeBsc.dstChainToBridge("arbitrum"),
      ).to.be.not.equal(ethers.ZeroAddress);
    });

    it("Should also add polygon as destination chain for bsc source bridge", async function () {
      await axelarSourceBridgeBsc.addDestinationChain(
        "Polygon",
        axelarDestinationBridgeArb.getAddress(),
      );

      expect(
        await axelarSourceBridgeBsc.dstChainToBridge("Polygon"),
      ).to.be.not.equal(ethers.ZeroAddress);
    });

    it("Should remove polygon as destination chain for bsc source bridge", async function () {
      await axelarSourceBridgeBsc.removeDestinationChain("Polygon");

      expect(
        await axelarSourceBridgeBsc.dstChainToBridge("Polygon"),
      ).to.be.equal("");
    });

    it("Should add additional supported token and then remove the support for it", async function () {
      await axelarSourceBridgeBsc.addSupportedToken(
        additionalToken.getAddress(),
        ethers.parseEther("100000"),
        ethers.parseEther("1000000"),
      );

      expect(
        await axelarSourceBridgeBsc.supportedTokens(
          additionalToken.getAddress(),
        ),
      ).to.be.equal(true);

      await axelarSourceBridgeBsc.removeSupportedToken(
        additionalToken.getAddress(),
      );

      expect(
        await axelarSourceBridgeBsc.supportedTokens(
          additionalToken.getAddress(),
        ),
      ).to.be.equal(false);
    });

    it("Should update max transfer size for a token", async function () {
      await axelarSourceBridgeBsc.updateMaxTransferSize(
        rwaTokenBsc.getAddress(),
        ethers.parseEther("200000"),
      );

      expect(
        await axelarSourceBridgeBsc.maxTransferSizes(rwaTokenBsc.getAddress()),
      ).to.be.equal(ethers.parseEther("200000"));
    });

    it("Should update the daily limit for a token", async function () {
      await axelarSourceBridgeBsc.updateDailyLimit(
        rwaTokenBsc.getAddress(),
        ethers.parseEther("2000000"),
      );

      expect(
        await axelarSourceBridgeBsc.dailyLimits(rwaTokenBsc.getAddress()),
      ).to.be.equal(ethers.parseEther("2000000"));
    });

    it("Should pause the bridge and then unpause it", async function () {
      await axelarSourceBridgeBsc.pause();

      expect(await axelarSourceBridgeBsc.paused()).to.be.equal(true);

      await axelarSourceBridgeBsc.unpause();

      expect(await axelarSourceBridgeBsc.paused()).to.be.equal(false);
    });

    it("Should some tokens to the bridge and then rescue them", async function () {
      await rwaTokenBsc.transfer(
        axelarSourceBridgeBsc.getAddress(),
        ethers.parseEther("10000"),
      );

      expect(
        await rwaTokenBsc.balanceOf(axelarSourceBridgeBsc.getAddress()),
      ).to.be.equal(ethers.parseEther("10000"));

      await axelarSourceBridgeBsc.rescueTokens(rwaTokenBsc.getAddress());

      expect(
        await rwaTokenBsc.balanceOf(axelarSourceBridgeBsc.getAddress()),
      ).to.be.equal(ethers.parseEther("0"));
    });

    // initiateBridge test is done on the actual public testnet (Examples can be found in the "Transactions tab" here: https://testnet.bscscan.com/address/0x91C0bFfD5451132ceb8156f32f935581B5F1B78F)
  });

  describe("AxelarDestinationBridge", function () {
    it("Should add chain support for bsc on arb destination bridge", async function () {
      await axelarDestinationBridgeArb.addChainSupport(
        "binance",
        axelarSourceBridgeBsc.getAddress().toString(),
      );

      expect(
        await axelarDestinationBridgeArb.srcChainToSrcBridge("binance"),
      ).to.be.not.equal(ethers.ZeroAddress);
    });

    it("Should also add polygon as chain support for arb destination bridge", async function () {
      await axelarDestinationBridgeArb.addChainSupport(
        "Polygon",
        axelarSourceBridgeBsc.getAddress().toString(),
      );

      expect(
        await axelarDestinationBridgeArb.srcChainToSrcBridge("Polygon"),
      ).to.be.not.equal(ethers.ZeroAddress);
    });

    it("Should remove polygon as chain support for arb destination bridge", async function () {
      await axelarDestinationBridgeArb.removeChainSupport("Polygon");

      expect(
        await axelarDestinationBridgeArb.srcChainToSrcBridge("Polygon"),
      ).to.be.equal("");
    });

    it("Should pause the bridge and then unpause it", async function () {
      await axelarDestinationBridgeArb.pause();

      expect(await axelarDestinationBridgeArb.paused()).to.be.equal(true);

      await axelarDestinationBridgeArb.unpause();

      expect(await axelarDestinationBridgeArb.paused()).to.be.equal(false);
    });

    it("Should add support for the bsc token on the arb destination bridge", async function () {
      await axelarDestinationBridgeArb.addSupportedToken(
        rwaTokenBsc.getAddress(),
      );

      expect(
        await axelarDestinationBridgeArb.supportedTokens(
          rwaTokenBsc.getAddress(),
        ),
      ).to.be.equal(true);
    });

    it("Should add support for an additional token on the arb destination bridge and then remove it", async function () {
      await axelarDestinationBridgeArb.addSupportedToken(
        additionalToken.getAddress(),
      );

      expect(
        await axelarDestinationBridgeArb.supportedTokens(
          additionalToken.getAddress(),
        ),
      ).to.be.equal(true);

      await axelarDestinationBridgeArb.removeSupportedToken(
        additionalToken.getAddress(),
      );

      expect(
        await axelarDestinationBridgeArb.supportedTokens(
          additionalToken.getAddress(),
        ),
      ).to.be.equal(false);
    });

    it("Should mint some rwa tokens on arb tokens to owner for testing", async function () {
      await rwaTokenArb.mint(ethers.parseEther("1000000"));
    });

    it("Should send some tokens to the bridge and then rescue them", async function () {
      await rwaTokenArb.transfer(
        axelarDestinationBridgeArb.getAddress(),
        ethers.parseEther("10000"),
      );

      expect(
        await rwaTokenArb.balanceOf(axelarDestinationBridgeArb.getAddress()),
      ).to.be.equal(ethers.parseEther("10000"));

      await axelarDestinationBridgeArb.rescueTokens(rwaTokenArb.getAddress());

      expect(
        await rwaTokenArb.balanceOf(axelarDestinationBridgeArb.getAddress()),
      ).to.be.equal(ethers.parseEther("0"));
    });

    // _execute was also only able to be tested on the actual public testnet (Examples can be found in the transaction history here: https://testnet.arbiscan.io/address/0xE72a76a5A8310a3613c4d6A59dBaCcd2fA387CAD)
  });
});
