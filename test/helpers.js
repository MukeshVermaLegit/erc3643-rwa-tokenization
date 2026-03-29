const { expect } = require("chai");
const { ethers } = require("hardhat");

/**
 * Shared test helper: deploys the full ERC-3643 infrastructure, creates investor
 * identities with signed KYC claims, and returns all contracts and signers.
 */
async function deployFullSuite() {
  const [owner, agent, investor1, investor2, unverified, recoveryWallet] =
    await ethers.getSigners();

  const KYC_TOPIC = 1;

  // --- Deploy TrustedIssuersRegistry ---
  const TrustedIssuersRegistry = await ethers.getContractFactory("TrustedIssuersRegistry");
  const trustedIssuersRegistry = await TrustedIssuersRegistry.deploy();

  // --- Deploy ClaimIssuer (owner is the signing key) ---
  const ClaimIssuer = await ethers.getContractFactory("ClaimIssuer");
  const claimIssuer = await ClaimIssuer.deploy(owner.address);

  // Add ClaimIssuer as trusted for KYC topic
  await trustedIssuersRegistry.addTrustedIssuer(await claimIssuer.getAddress(), [KYC_TOPIC]);

  // --- Deploy IdentityRegistryStorage ---
  const IdentityRegistryStorage = await ethers.getContractFactory("IdentityRegistryStorage");
  const identityRegistryStorage = await IdentityRegistryStorage.deploy();

  // --- Deploy IdentityRegistry ---
  const IdentityRegistry = await ethers.getContractFactory("IdentityRegistry");
  const identityRegistry = await IdentityRegistry.deploy(
    await trustedIssuersRegistry.getAddress(),
    await identityRegistryStorage.getAddress()
  );

  // Bind storage to registry
  await identityRegistryStorage.bindIdentityRegistry(await identityRegistry.getAddress());

  // Add KYC as required claim topic
  await identityRegistry.addRequiredClaimTopic(KYC_TOPIC);

  // --- Deploy compliance modules ---
  const CountryRestrictModule = await ethers.getContractFactory("CountryRestrictModule");
  const countryRestrict = await CountryRestrictModule.deploy();

  const MaxHoldersModule = await ethers.getContractFactory("MaxHoldersModule");
  const maxHolders = await MaxHoldersModule.deploy();

  const MaxBalanceModule = await ethers.getContractFactory("MaxBalanceModule");
  const maxBalance = await MaxBalanceModule.deploy();

  // --- Deploy ModularCompliance ---
  const ModularCompliance = await ethers.getContractFactory("ModularCompliance");
  const compliance = await ModularCompliance.deploy();

  await compliance.addModule(await countryRestrict.getAddress());
  await compliance.addModule(await maxHolders.getAddress());
  await compliance.addModule(await maxBalance.getAddress());

  // --- Deploy RealEstateToken ---
  const RealEstateToken = await ethers.getContractFactory("RealEstateToken");
  const token = await RealEstateToken.deploy(
    "Real Estate Token",
    "RET",
    await identityRegistry.getAddress(),
    await compliance.getAddress()
  );

  // Bind token to compliance
  await compliance.bindToken(await token.getAddress());

  // Add agent
  await token.addAgent(agent.address);

  // Configure compliance modules
  const complianceAddress = await compliance.getAddress();
  await maxHolders.setMaxHolders(complianceAddress, 100);
  await maxBalance.setMaxBalance(complianceAddress, 10000);
  await countryRestrict.addCountryRestriction(complianceAddress, 999);

  // --- Create Identity for investor1 (country 1 = USA) ---
  const Identity = await ethers.getContractFactory("Identity");
  const identity1 = await Identity.deploy(investor1.address);
  const claimIssuerAddress = await claimIssuer.getAddress();

  // Sign and add KYC claim for investor1
  const data1 = ethers.AbiCoder.defaultAbiCoder().encode(["address"], [investor1.address]);
  const hash1 = ethers.keccak256(
    ethers.AbiCoder.defaultAbiCoder().encode(
      ["address", "uint256", "bytes"],
      [await identity1.getAddress(), KYC_TOPIC, data1]
    )
  );
  const sig1 = await owner.signMessage(ethers.getBytes(hash1));
  await identity1.connect(investor1).addClaim(KYC_TOPIC, 1, claimIssuerAddress, sig1, data1, "");

  // Register investor1
  await identityRegistry.registerIdentity(investor1.address, await identity1.getAddress(), 1);

  // --- Create Identity for investor2 (country 44 = UK) ---
  const identity2 = await Identity.deploy(investor2.address);

  const data2 = ethers.AbiCoder.defaultAbiCoder().encode(["address"], [investor2.address]);
  const hash2 = ethers.keccak256(
    ethers.AbiCoder.defaultAbiCoder().encode(
      ["address", "uint256", "bytes"],
      [await identity2.getAddress(), KYC_TOPIC, data2]
    )
  );
  const sig2 = await owner.signMessage(ethers.getBytes(hash2));
  await identity2.connect(investor2).addClaim(KYC_TOPIC, 1, claimIssuerAddress, sig2, data2, "");

  await identityRegistry.registerIdentity(investor2.address, await identity2.getAddress(), 44);

  return {
    owner,
    agent,
    investor1,
    investor2,
    unverified,
    recoveryWallet,
    token,
    identityRegistry,
    identityRegistryStorage,
    trustedIssuersRegistry,
    claimIssuer,
    compliance,
    countryRestrict,
    maxHolders,
    maxBalance,
    identity1,
    identity2,
    Identity,
    KYC_TOPIC,
  };
}

module.exports = { deployFullSuite };
