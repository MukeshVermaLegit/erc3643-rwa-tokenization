const { expect } = require("chai");
const { ethers } = require("hardhat");
const { deployFullSuite } = require("./helpers");

describe("Compliance Modules", function () {
  let suite;

  beforeEach(async function () {
    suite = await deployFullSuite();
  });

  describe("CountryRestrictModule", function () {
    it("Should block transfer to restricted country", async function () {
      const {
        token,
        agent,
        investor1,
        investor2,
        identityRegistry,
        compliance,
        countryRestrict,
      } = suite;

      // Mint tokens to investor1
      await token.connect(agent).mint(investor1.address, 5000);

      // Restrict country 44 (UK — investor2's country)
      await countryRestrict.addCountryRestriction(await compliance.getAddress(), 44);

      // Transfer to investor2 (UK) should fail
      await expect(
        token.connect(investor1).transfer(investor2.address, 100)
      ).to.be.revertedWith("RealEstateToken: transfer not compliant");
    });

    it("Should allow transfer to non-restricted country", async function () {
      const { token, agent, investor1, investor2 } = suite;

      // Investor2 is in country 44 (UK) which is NOT restricted (only 999 is)
      await token.connect(agent).mint(investor1.address, 5000);

      await token.connect(investor1).transfer(investor2.address, 1000);

      expect(await token.balanceOf(investor2.address)).to.equal(1000);
    });
  });

  describe("MaxHoldersModule", function () {
    it("Should enforce max holder limit", async function () {
      const {
        token,
        agent,
        investor1,
        investor2,
        owner,
        compliance,
        maxHolders,
        identityRegistry,
        claimIssuer,
        Identity,
        KYC_TOPIC,
      } = suite;

      // Set max holders to 2
      await maxHolders.setMaxHolders(await compliance.getAddress(), 2);

      // Mint to investor1 and investor2 — that's 2 holders
      await token.connect(agent).mint(investor1.address, 1000);
      await token.connect(agent).mint(investor2.address, 1000);

      // Create a third verified investor
      const signers = await ethers.getSigners();
      const investor3 = signers[6];
      const identity3 = await Identity.deploy(investor3.address);

      const claimIssuerAddress = await claimIssuer.getAddress();
      const data3 = ethers.AbiCoder.defaultAbiCoder().encode(["address"], [investor3.address]);
      const hash3 = ethers.keccak256(
        ethers.AbiCoder.defaultAbiCoder().encode(
          ["address", "uint256", "bytes"],
          [await identity3.getAddress(), KYC_TOPIC, data3]
        )
      );
      const sig3 = await owner.signMessage(ethers.getBytes(hash3));
      await identity3.connect(investor3).addClaim(KYC_TOPIC, 1, claimIssuerAddress, sig3, data3, "");
      await identityRegistry.registerIdentity(investor3.address, await identity3.getAddress(), 1);

      // Transfer to investor3 should fail — exceeds max holders
      await expect(
        token.connect(investor1).transfer(investor3.address, 100)
      ).to.be.revertedWith("RealEstateToken: transfer not compliant");
    });
  });

  describe("MaxBalanceModule", function () {
    it("Should enforce max balance per investor", async function () {
      const { token, agent, investor1, investor2, compliance, maxBalance } = suite;

      // Set max balance to 5000
      await maxBalance.setMaxBalance(await compliance.getAddress(), 5000);

      // Mint 5000 to investor1
      await token.connect(agent).mint(investor1.address, 5000);

      // Mint 4000 to investor2
      await token.connect(agent).mint(investor2.address, 4000);

      // Transfer 1001 from investor1 to investor2 should fail (4000 + 1001 > 5000)
      await expect(
        token.connect(investor1).transfer(investor2.address, 1001)
      ).to.be.revertedWith("RealEstateToken: transfer not compliant");

      // Transfer 1000 should succeed (4000 + 1000 = 5000)
      await token.connect(investor1).transfer(investor2.address, 1000);
      expect(await token.balanceOf(investor2.address)).to.equal(5000);
    });
  });

  describe("Module Management", function () {
    it("Should allow removing a compliance module", async function () {
      const { token, agent, investor1, investor2, compliance, maxBalance } = suite;

      // Set max balance to 100
      await maxBalance.setMaxBalance(await compliance.getAddress(), 100);

      await token.connect(agent).mint(investor1.address, 5000);

      // Should fail with max balance module active
      await expect(
        token.connect(investor1).transfer(investor2.address, 200)
      ).to.be.revertedWith("RealEstateToken: transfer not compliant");

      // Remove the max balance module
      await compliance.removeModule(await maxBalance.getAddress());

      // Now the transfer should succeed
      await token.connect(investor1).transfer(investor2.address, 200);
      expect(await token.balanceOf(investor2.address)).to.equal(200);
    });
  });
});
