const { expect } = require("chai");
const { ethers } = require("hardhat");
const { deployFullSuite } = require("./helpers");

describe("Identity & Claim Verification", function () {
  let suite;

  beforeEach(async function () {
    suite = await deployFullSuite();
  });

  describe("Identity Registry", function () {
    it("Should register an identity in the registry", async function () {
      const { identityRegistry, investor1, identity1 } = suite;

      expect(await identityRegistry.contains(investor1.address)).to.equal(true);
      expect(await identityRegistry.identity(investor1.address)).to.equal(
        await identity1.getAddress()
      );
    });

    it("Should verify an investor with valid KYC claim", async function () {
      const { identityRegistry, investor1 } = suite;

      expect(await identityRegistry.isVerified(investor1.address)).to.equal(true);
    });

    it("Should fail verification without KYC claim", async function () {
      const { identityRegistry, unverified } = suite;

      // Unverified address is not in the registry at all
      expect(await identityRegistry.isVerified(unverified.address)).to.equal(false);

      // Also test: register an identity without any claims
      const { owner, Identity } = suite;
      const emptyIdentity = await Identity.deploy(unverified.address);
      await identityRegistry.registerIdentity(
        unverified.address,
        await emptyIdentity.getAddress(),
        1
      );

      // Should still fail — no KYC claim
      expect(await identityRegistry.isVerified(unverified.address)).to.equal(false);
    });

    it("Should update investor country code", async function () {
      const { identityRegistry, investor1 } = suite;

      expect(await identityRegistry.investorCountry(investor1.address)).to.equal(1);

      await identityRegistry.updateCountry(investor1.address, 33);

      expect(await identityRegistry.investorCountry(investor1.address)).to.equal(33);
    });
  });

  describe("Trusted Issuers Registry", function () {
    it("Should add and remove trusted issuers", async function () {
      const { trustedIssuersRegistry, claimIssuer, owner, KYC_TOPIC } = suite;

      // ClaimIssuer is already trusted
      expect(
        await trustedIssuersRegistry.isTrustedIssuer(await claimIssuer.getAddress())
      ).to.equal(true);

      // Remove it
      await trustedIssuersRegistry.removeTrustedIssuer(await claimIssuer.getAddress());

      expect(
        await trustedIssuersRegistry.isTrustedIssuer(await claimIssuer.getAddress())
      ).to.equal(false);

      // Issuers list should be empty
      const issuers = await trustedIssuersRegistry.getTrustedIssuers();
      expect(issuers.length).to.equal(0);

      // Re-add it
      await trustedIssuersRegistry.addTrustedIssuer(await claimIssuer.getAddress(), [KYC_TOPIC]);

      expect(
        await trustedIssuersRegistry.isTrustedIssuer(await claimIssuer.getAddress())
      ).to.equal(true);
    });
  });
});
