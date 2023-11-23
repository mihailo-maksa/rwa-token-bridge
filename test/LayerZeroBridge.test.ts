import { expect } from "chai";
import { ethers } from "hardhat";
import { Contract, Signer, Wallet } from "ethers";
import { delay } from "./utils";

describe("LayerZero bridge smart contract system", function () {
  let owner: any;
  let user1: any;
  let user2: any;
  let bscLzEndpointMock: Contract;
  let arbLzEndpointMock: Contract;
  let rwaTokenOFTBsc: Contract;
  let rwaTokenOFTArb: Contract;
  let additionalToken: Contract;
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
    additionalToken = await ethers.deployContract("RWATokenOFT", [
      owner.address,
      "RWA Token",
      "RWA",
      arbLzEndpointMock.getAddress(),
    ]);

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

    await rwaTokenOFTBsc.setTrustedRemoteAddress(
      2,
      rwaTokenOFTArb.getAddress(),
    );
    await rwaTokenOFTArb.setTrustedRemoteAddress(
      1,
      rwaTokenOFTBsc.getAddress(),
    );
  });

  describe("RWATokenOFT", function () {
    it("Should mint 1 million tokens to the owner", async function () {
      await rwaTokenOFTBsc.mint(ethers.parseEther("1000000"));

      expect(await rwaTokenOFTBsc.balanceOf(owner.address)).to.equal(
        ethers.parseEther("1000000"),
      );

      await rwaTokenOFTBsc.transfer(user1.address, ethers.parseEther("10000"));
      await rwaTokenOFTBsc.transfer(user2.address, ethers.parseEther("10000"));
    });

    it("Should fail to mint tokens to the user1", async function () {
      await expect(
        // @ts-ignore
        rwaTokenOFTBsc.connect(user1).mint(ethers.parseEther("1000000")),
      ).to.be.reverted;
    });

    it("Should burn 10k tokens from the owner", async function () {
      await rwaTokenOFTBsc.burn(ethers.parseEther("10000"));

      expect(await rwaTokenOFTBsc.balanceOf(owner.address)).to.equal(
        ethers.parseEther("970000"),
      );
    });

    it("Should fail to burn tokens from the user1 when allowance is not set", async function () {
      await expect(
        rwaTokenOFTBsc.burnFrom(user1.address, ethers.parseEther("500")),
      ).to.be.reverted;
    });

    it("Should set allowance for user1 and burn 500 tokens", async function () {
      await rwaTokenOFTBsc
        .connect(user1)
        // @ts-ignore
        .approve(owner.address, ethers.parseEther("500"));

      expect(
        await rwaTokenOFTBsc.allowance(user1.address, owner.address),
      ).to.equal(ethers.parseEther("500"));

      await rwaTokenOFTBsc.burnFrom(user1.address, ethers.parseEther("500"));
      expect(await rwaTokenOFTBsc.balanceOf(user1.address)).to.equal(
        ethers.parseEther("9500"),
      );
    });
  });

  describe("LayerZeroBridge", function () {
    it("Should add supported token", async function () {
      await layerZeroBridgeBsc.addSupportedToken(
        additionalToken.getAddress(),
        ethers.parseEther("100000"),
        ethers.parseEther("1000000"),
      );
      expect(
        await layerZeroBridgeBsc.supportedTokens(additionalToken.getAddress()),
      ).to.equal(true);
    });

    it("Should fail to add supported token when not called by the owner", async function () {
      await expect(
        layerZeroBridgeBsc
          .connect(user1)
          // @ts-ignore
          .addSupportedToken(
            additionalToken.getAddress(),
            ethers.parseEther("200000"),
            ethers.parseEther("2000000"),
          ),
      ).to.be.reverted;
    });

    it("Should fail to add invalid token", async function () {
      await expect(
        layerZeroBridgeBsc.addSupportedToken(
          ethers.ZeroAddress,
          ethers.parseEther("100000"),
          ethers.parseEther("1000000"),
        ),
      ).to.be.reverted;
    });

    it("Should fail to add supported token when already added", async function () {
      await expect(
        layerZeroBridgeBsc.addSupportedToken(
          additionalToken.getAddress(),
          ethers.parseEther("100000"),
          ethers.parseEther("1000000"),
        ),
      ).to.be.reverted;
    });

    it("Should remove supported token", async function () {
      await layerZeroBridgeBsc.removeSupportedToken(
        additionalToken.getAddress(),
      );
      expect(
        await layerZeroBridgeBsc.supportedTokens(additionalToken.getAddress()),
      ).to.equal(false);
    });

    it("Should update max transfer amount", async function () {
      await layerZeroBridgeBsc.updateMaxTransferSize(
        rwaTokenOFTBsc.getAddress(),
        ethers.parseEther("200000"),
      );
      expect(
        await layerZeroBridgeBsc.maxTransferSizes(rwaTokenOFTBsc.getAddress()),
      ).to.equal(ethers.parseEther("200000"));
    });

    it("Should fail to update max transfer amount to 0", async function () {
      await expect(
        layerZeroBridgeBsc.updateMaxTransferSize(
          rwaTokenOFTBsc.getAddress(),
          0,
        ),
      ).to.be.reverted;
    });

    it("Should update the daily transfer limit", async function () {
      await layerZeroBridgeBsc.updateDailyLimit(
        rwaTokenOFTBsc.getAddress(),
        ethers.parseEther("2000000"),
      );
      expect(
        await layerZeroBridgeBsc.dailyLimits(rwaTokenOFTBsc.getAddress()),
      ).to.equal(ethers.parseEther("2000000"));
    });

    it("Should fail to update daily transfer limit to 0", async function () {
      await expect(
        layerZeroBridgeBsc.updateDailyLimit(rwaTokenOFTBsc.getAddress(), 0),
      ).to.be.reverted;
    });

    it("Should fail to update the daily transfer limit for an unsupported token", async function () {
      await expect(
        layerZeroBridgeBsc.updateDailyLimit(
          additionalToken.getAddress(),
          ethers.parseEther("2000000"),
        ),
      ).to.be.reverted;
    });

    it("Should pause the bridge", async function () {
      await layerZeroBridgeBsc.pause();
      expect(await layerZeroBridgeBsc.paused()).to.equal(true);
    });

    it("Should fail to pause the bridge when already paused", async function () {
      await expect(layerZeroBridgeBsc.pause()).to.be.reverted;
    });

    it("Should unpause the bridge", async function () {
      await layerZeroBridgeBsc.unpause();
      expect(await layerZeroBridgeBsc.paused()).to.equal(false);
    });

    it("Should send some tokens to the bridge contract and rescue them", async function () {
      await rwaTokenOFTBsc.transfer(
        layerZeroBridgeBsc.getAddress(),
        ethers.parseEther("10000"),
      );
      expect(
        await rwaTokenOFTBsc.balanceOf(layerZeroBridgeBsc.getAddress()),
      ).to.equal(ethers.parseEther("10000"));
      await layerZeroBridgeBsc.rescueTokens(rwaTokenOFTBsc.getAddress());
      expect(
        await rwaTokenOFTBsc.balanceOf(layerZeroBridgeBsc.getAddress()),
      ).to.equal(0);
    });

    it("Should fail to rescue tokens when not called by the owner", async function () {
      await expect(
        layerZeroBridgeBsc
          .connect(user1)
          // @ts-ignore
          .rescueTokens(rwaTokenOFTBsc.getAddress()),
      ).to.be.reverted;
    });

    //       function bridge(
    //     address _token,
    //     address _recipient,
    //     uint16 _dstChainId,
    //     uint256 _amount
    //   ) external payable whenNotPaused {

    it("Should fail to bridge tokens when paused", async function () {
      await layerZeroBridgeBsc.pause();
      await expect(
        layerZeroBridgeBsc.bridge(
          rwaTokenOFTBsc.getAddress(),
          user1.address,
          2,
          ethers.parseEther("100"),
        ),
      ).to.be.reverted;

      await layerZeroBridgeBsc.unpause();
    });

    it("Should fail to bridge tokens when the token is not supported", async function () {
      await expect(
        layerZeroBridgeBsc.bridge(
          additionalToken.getAddress(),
          user1.address,
          2,
          ethers.parseEther("100"),
        ),
      ).to.be.reverted;
    });

    // fail when: zero msg.value, zero amount, zero address as recipient, chain id is zero, allowance less than amount transferred,
    // amount larger than max transfer size, surpassing the daily transfer limit,

    it("Should approve the bridge to spend 1000 tokens", async function () {
      await rwaTokenOFTBsc.approve(
        layerZeroBridgeBsc.getAddress(),
        ethers.parseEther("1000"),
      );
      expect(
        await rwaTokenOFTBsc.allowance(
          owner.address,
          layerZeroBridgeBsc.getAddress(),
        ),
      ).to.equal(ethers.parseEther("1000"));
    });

    it("Should fail to bridge the tokens when zero ms.value is sent", async function () {
      await expect(
        layerZeroBridgeBsc.bridge(
          rwaTokenOFTBsc.getAddress(),
          user1.address,
          2,
          ethers.parseEther("100"),
          { value: 0 },
        ),
      ).to.be.reverted;
    });

    it("Should fail to bridge tokens when the amount is zero", async function () {
      await expect(
        layerZeroBridgeBsc.bridge(
          rwaTokenOFTBsc.getAddress(),
          user1.address,
          2,
          0,
          {
            value: ethers.parseEther("1"),
          },
        ),
      ).to.be.reverted;
    });

    it("Should fail to bridge tokens when the recipient is zero address", async function () {
      await expect(
        layerZeroBridgeBsc.bridge(
          rwaTokenOFTBsc.getAddress(),
          ethers.ZeroAddress,
          2,
          ethers.parseEther("100"),
          {
            value: ethers.parseEther("1"),
          },
        ),
      ).to.be.reverted;
    });

    it("Should fail to bridge tokens when the chain id is zero", async function () {
      await expect(
        layerZeroBridgeBsc.bridge(
          rwaTokenOFTBsc.getAddress(),
          user1.address,
          0,
          ethers.parseEther("100"),
          {
            value: ethers.parseEther("1"),
          },
        ),
      ).to.be.reverted;
    });

    it("Should fail to bridge tokens when the allowance is less than the amount transferred", async function () {
      await expect(
        layerZeroBridgeBsc.bridge(
          rwaTokenOFTBsc.getAddress(),
          user1.address,
          2,
          ethers.parseEther("1001"),
          {
            value: ethers.parseEther("1"),
          },
        ),
      ).to.be.reverted;
    });

    it("Should fail to bridge tokens when the amount is larger than the max transfer size", async function () {
      await expect(
        layerZeroBridgeBsc.bridge(
          rwaTokenOFTBsc.getAddress(),
          user1.address,
          2,
          ethers.parseEther("100001"),
          {
            value: ethers.parseEther("1"),
          },
        ),
      ).to.be.reverted;
    });

    // it("Should fail to bridge tokens when the daily transfer limit is surpassed", async function () {
    //   await expect(
    //     layerZeroBridgeBsc.bridge(
    //       rwaTokenOFTBsc.getAddress(),
    //       user1.address,
    //       2,
    //       ethers.parseEther("1000"),
    //       {
    //         value: ethers.parseEther("1"),
    //       },
    //     ),
    //   ).to.be.reverted;
    // });

    it("Should estimate the send fee", async function () {
      const [nativeFee, zroFee] = await layerZeroBridgeBsc.estimateSendFee(
        rwaTokenOFTBsc.getAddress(),
        2,
        user1.address,
        ethers.parseEther("100"),
        false,
        "0x",
      );

      expect(nativeFee).to.be.gt(0);
      expect(zroFee).to.equal(0);
    });

    it("Should bridge 1000 tokens to the user1 from bsc to arb", async function () {
      const [nativeFee] = await layerZeroBridgeBsc.estimateSendFee(
        rwaTokenOFTBsc.getAddress(),
        2,
        user1.address,
        ethers.parseEther("1000"),
        false,
        "0x",
      );

      await layerZeroBridgeBsc.bridge(
        rwaTokenOFTBsc.getAddress(),
        user1.address,
        2,
        ethers.parseEther("1000"),
        {
          value: nativeFee,
        },
      );

      await delay(1000);

      expect(await rwaTokenOFTArb.balanceOf(user1.address)).to.equal(
        ethers.parseEther("1000"),
      );
      expect(await rwaTokenOFTBsc.balanceOf(owner.address)).to.equal(
        ethers.parseEther("969000"),
      );
    });

    it("Should bridge 500 tokens from user 1 to user 2 from arb to bsc", async function () {
      await rwaTokenOFTArb
        .connect(user1)
        // @ts-ignore
        .approve(layerZeroBridgeArb.getAddress(), ethers.parseEther("500"));

      const [nativeFee] = await layerZeroBridgeArb.estimateSendFee(
        rwaTokenOFTArb.getAddress(),
        1,
        user2.address,
        ethers.parseEther("500"),
        false,
        "0x",
      );

      await layerZeroBridgeArb
        .connect(user1)
        // @ts-ignore
        .bridge(
          rwaTokenOFTArb.getAddress(),
          user2.address,
          1,
          ethers.parseEther("500"),
          {
            value: nativeFee,
          },
        );

      await delay(1000);

      expect(await rwaTokenOFTBsc.balanceOf(user2.address)).to.equal(
        ethers.parseEther("10500"),
      );
      expect(await rwaTokenOFTArb.balanceOf(user1.address)).to.equal(
        ethers.parseEther("500"),
      );
    });
  });
});
