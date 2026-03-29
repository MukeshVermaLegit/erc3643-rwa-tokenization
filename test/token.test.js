const { expect } = require("chai");
const { ethers } = require("hardhat");
const { deployFullSuite } = require("./helpers");

describe("RealEstateToken", function () {
  let suite;

  beforeEach(async function () {
    suite = await deployFullSuite();
  });

  describe("Minting", function () {
    it("Should mint tokens to a verified investor", async function () {
      const { token, agent, investor1 } = suite;

      await token.connect(agent).mint(investor1.address, 1000);

      expect(await token.balanceOf(investor1.address)).to.equal(1000);
    });
  });

  describe("Transfers", function () {
    beforeEach(async function () {
      const { token, agent, investor1 } = suite;
      await token.connect(agent).mint(investor1.address, 5000);
    });

    it("Should transfer tokens between verified investors", async function () {
      const { token, investor1, investor2 } = suite;

      await token.connect(investor1).transfer(investor2.address, 1000);

      expect(await token.balanceOf(investor1.address)).to.equal(4000);
      expect(await token.balanceOf(investor2.address)).to.equal(1000);
    });

    it("Should block transfer to unverified wallet", async function () {
      const { token, investor1, unverified } = suite;

      await expect(
        token.connect(investor1).transfer(unverified.address, 100)
      ).to.be.revertedWith("RealEstateToken: recipient is not verified");
    });
  });

  describe("Forced Transfer", function () {
    it("Should allow agent to force transfer", async function () {
      const { token, agent, investor1, investor2 } = suite;

      await token.connect(agent).mint(investor1.address, 5000);

      await token.connect(agent).forcedTransfer(investor1.address, investor2.address, 2000);

      expect(await token.balanceOf(investor1.address)).to.equal(3000);
      expect(await token.balanceOf(investor2.address)).to.equal(2000);
    });
  });

  describe("Freezing", function () {
    beforeEach(async function () {
      const { token, agent, investor1 } = suite;
      await token.connect(agent).mint(investor1.address, 5000);
    });

    it("Should freeze partial tokens and block transfer of frozen amount", async function () {
      const { token, agent, investor1, investor2 } = suite;

      // Freeze 3000 tokens, leaving 2000 free
      await token.connect(agent).freezePartialTokens(investor1.address, 3000);

      expect(await token.getFrozenTokens(investor1.address)).to.equal(3000);

      // Should be able to transfer 2000 (unfrozen)
      await token.connect(investor1).transfer(investor2.address, 2000);

      // Should not be able to transfer more than unfrozen balance
      await expect(
        token.connect(investor1).transfer(investor2.address, 1)
      ).to.be.revertedWith("RealEstateToken: insufficient unfrozen balance");
    });

    it("Should unfreeze tokens", async function () {
      const { token, agent, investor1, investor2 } = suite;

      await token.connect(agent).freezePartialTokens(investor1.address, 3000);
      expect(await token.getFrozenTokens(investor1.address)).to.equal(3000);

      await token.connect(agent).unfreezePartialTokens(investor1.address, 3000);
      expect(await token.getFrozenTokens(investor1.address)).to.equal(0);

      // Now should be able to transfer full balance
      await token.connect(investor1).transfer(investor2.address, 5000);
      expect(await token.balanceOf(investor2.address)).to.equal(5000);
    });
  });

  describe("Recovery", function () {
    it("Should recover tokens to new wallet (lost key scenario)", async function () {
      const {
        token,
        agent,
        investor1,
        recoveryWallet,
        identityRegistry,
        identity1,
        owner,
        claimIssuer,
        Identity,
        KYC_TOPIC,
      } = suite;

      // Mint tokens to investor1
      await token.connect(agent).mint(investor1.address, 5000);

      // Create identity for recovery wallet and register it
      const recoveryIdentity = await Identity.deploy(recoveryWallet.address);

      const claimIssuerAddress = await claimIssuer.getAddress();
      const data = ethers.AbiCoder.defaultAbiCoder().encode(["address"], [recoveryWallet.address]);
      const hash = ethers.keccak256(
        ethers.AbiCoder.defaultAbiCoder().encode(
          ["address", "uint256", "bytes"],
          [await recoveryIdentity.getAddress(), KYC_TOPIC, data]
        )
      );
      const sig = await owner.signMessage(ethers.getBytes(hash));
      await recoveryIdentity.connect(recoveryWallet).addClaim(KYC_TOPIC, 1, claimIssuerAddress, sig, data, "");

      await identityRegistry.registerIdentity(
        recoveryWallet.address,
        await recoveryIdentity.getAddress(),
        1
      );

      // Recover tokens from investor1 to recovery wallet
      await token.connect(agent).recoveryAddress(
        investor1.address,
        recoveryWallet.address,
        await identity1.getAddress()
      );

      expect(await token.balanceOf(investor1.address)).to.equal(0);
      expect(await token.balanceOf(recoveryWallet.address)).to.equal(5000);
    });
  });

  describe("Pause / Unpause", function () {
    it("Should pause and unpause token", async function () {
      const { token, agent, investor1, investor2 } = suite;

      await token.connect(agent).mint(investor1.address, 5000);

      // Pause
      await token.connect(agent).pause();
      expect(await token.paused()).to.equal(true);

      // Transfers should fail when paused
      await expect(
        token.connect(investor1).transfer(investor2.address, 100)
      ).to.be.revertedWith("RealEstateToken: token is paused");

      // Unpause
      await token.connect(agent).unpause();
      expect(await token.paused()).to.equal(false);

      // Transfers should work again
      await token.connect(investor1).transfer(investor2.address, 100);
      expect(await token.balanceOf(investor2.address)).to.equal(100);
    });
  });
});
