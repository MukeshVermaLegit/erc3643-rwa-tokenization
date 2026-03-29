const { ethers } = require("hardhat");

/**
 * Full deployment script for the ERC-3643 Tokenized Real Estate platform.
 * Deploys all contracts in the correct order, links them together, configures
 * compliance modules, and registers two test investor identities with KYC claims.
 */
async function main() {
  const [deployer, investor1, investor2] = await ethers.getSigners();

  console.log("Deploying contracts with account:", deployer.address);
  console.log("Account balance:", (await ethers.provider.getBalance(deployer.address)).toString());
  console.log("");

  // ============================================================
  // 1. Deploy TrustedIssuersRegistry
  // ============================================================
  const TrustedIssuersRegistry = await ethers.getContractFactory("TrustedIssuersRegistry");
  const trustedIssuersRegistry = await TrustedIssuersRegistry.deploy();
  await trustedIssuersRegistry.waitForDeployment();
  console.log("TrustedIssuersRegistry deployed to:", await trustedIssuersRegistry.getAddress());

  // ============================================================
  // 2. Deploy ClaimIssuer (with deployer as management key)
  // ============================================================
  const ClaimIssuer = await ethers.getContractFactory("ClaimIssuer");
  const claimIssuer = await ClaimIssuer.deploy(deployer.address);
  await claimIssuer.waitForDeployment();
  console.log("ClaimIssuer deployed to:", await claimIssuer.getAddress());

  // ============================================================
  // 3. Add ClaimIssuer to TrustedIssuersRegistry for topic 1 (KYC)
  // ============================================================
  const KYC_TOPIC = 1;
  await trustedIssuersRegistry.addTrustedIssuer(await claimIssuer.getAddress(), [KYC_TOPIC]);
  console.log("ClaimIssuer added as trusted issuer for KYC topic");

  // ============================================================
  // 4. Deploy IdentityRegistryStorage
  // ============================================================
  const IdentityRegistryStorage = await ethers.getContractFactory("IdentityRegistryStorage");
  const identityRegistryStorage = await IdentityRegistryStorage.deploy();
  await identityRegistryStorage.waitForDeployment();
  console.log("IdentityRegistryStorage deployed to:", await identityRegistryStorage.getAddress());

  // ============================================================
  // 5. Deploy IdentityRegistry
  // ============================================================
  const IdentityRegistry = await ethers.getContractFactory("IdentityRegistry");
  const identityRegistry = await IdentityRegistry.deploy(
    await trustedIssuersRegistry.getAddress(),
    await identityRegistryStorage.getAddress()
  );
  await identityRegistry.waitForDeployment();
  console.log("IdentityRegistry deployed to:", await identityRegistry.getAddress());

  // ============================================================
  // 6. Bind IdentityRegistryStorage to IdentityRegistry
  // ============================================================
  await identityRegistryStorage.bindIdentityRegistry(await identityRegistry.getAddress());
  console.log("IdentityRegistryStorage bound to IdentityRegistry");

  // Add KYC as a required claim topic
  await identityRegistry.addRequiredClaimTopic(KYC_TOPIC);
  console.log("KYC (topic 1) added as required claim topic");

  // ============================================================
  // 7. Deploy compliance modules
  // ============================================================
  const CountryRestrictModule = await ethers.getContractFactory("CountryRestrictModule");
  const countryRestrict = await CountryRestrictModule.deploy();
  await countryRestrict.waitForDeployment();
  console.log("CountryRestrictModule deployed to:", await countryRestrict.getAddress());

  const MaxHoldersModule = await ethers.getContractFactory("MaxHoldersModule");
  const maxHolders = await MaxHoldersModule.deploy();
  await maxHolders.waitForDeployment();
  console.log("MaxHoldersModule deployed to:", await maxHolders.getAddress());

  const MaxBalanceModule = await ethers.getContractFactory("MaxBalanceModule");
  const maxBalance = await MaxBalanceModule.deploy();
  await maxBalance.waitForDeployment();
  console.log("MaxBalanceModule deployed to:", await maxBalance.getAddress());

  // ============================================================
  // 8. Deploy ModularCompliance and add modules
  // ============================================================
  const ModularCompliance = await ethers.getContractFactory("ModularCompliance");
  const compliance = await ModularCompliance.deploy();
  await compliance.waitForDeployment();
  console.log("ModularCompliance deployed to:", await compliance.getAddress());

  await compliance.addModule(await countryRestrict.getAddress());
  await compliance.addModule(await maxHolders.getAddress());
  await compliance.addModule(await maxBalance.getAddress());
  console.log("All compliance modules added");

  // ============================================================
  // 9. Deploy RealEstateToken
  // ============================================================
  const RealEstateToken = await ethers.getContractFactory("RealEstateToken");
  const token = await RealEstateToken.deploy(
    "Real Estate Token",
    "RET",
    await identityRegistry.getAddress(),
    await compliance.getAddress()
  );
  await token.waitForDeployment();
  console.log("RealEstateToken deployed to:", await token.getAddress());

  // Bind token to compliance
  await compliance.bindToken(await token.getAddress());
  console.log("Token bound to compliance");

  // Add deployer as agent
  await token.addAgent(deployer.address);
  console.log("Deployer added as token agent");

  // ============================================================
  // 10. Configure compliance modules
  // ============================================================
  const complianceAddress = await compliance.getAddress();

  // Max 100 holders
  await maxHolders.setMaxHolders(complianceAddress, 100);
  console.log("Max holders set to 100");

  // Max 10000 tokens per investor
  await maxBalance.setMaxBalance(complianceAddress, 10000);
  console.log("Max balance set to 10,000 tokens per investor");

  // Restrict country 999
  await countryRestrict.addCountryRestriction(complianceAddress, 999);
  console.log("Country 999 restricted");

  // ============================================================
  // 11. Create identities for 2 test investors and register them
  // ============================================================
  const Identity = await ethers.getContractFactory("Identity");

  // Investor 1 (country 1 = USA)
  const identity1 = await Identity.deploy(investor1.address);
  await identity1.waitForDeployment();
  console.log("\nInvestor 1 Identity deployed to:", await identity1.getAddress());

  // Investor 2 (country 44 = UK)
  const identity2 = await Identity.deploy(investor2.address);
  await identity2.waitForDeployment();
  console.log("Investor 2 Identity deployed to:", await identity2.getAddress());

  // Sign KYC claims for both investors
  const claimIssuerAddress = await claimIssuer.getAddress();

  // Create and sign KYC claim for investor 1
  const data1 = ethers.AbiCoder.defaultAbiCoder().encode(["address"], [investor1.address]);
  const hash1 = ethers.keccak256(
    ethers.AbiCoder.defaultAbiCoder().encode(
      ["address", "uint256", "bytes"],
      [await identity1.getAddress(), KYC_TOPIC, data1]
    )
  );
  const sig1 = await deployer.signMessage(ethers.getBytes(hash1));

  await identity1.connect(investor1).addClaim(KYC_TOPIC, 1, claimIssuerAddress, sig1, data1, "");
  console.log("KYC claim added for Investor 1");

  // Create and sign KYC claim for investor 2
  const data2 = ethers.AbiCoder.defaultAbiCoder().encode(["address"], [investor2.address]);
  const hash2 = ethers.keccak256(
    ethers.AbiCoder.defaultAbiCoder().encode(
      ["address", "uint256", "bytes"],
      [await identity2.getAddress(), KYC_TOPIC, data2]
    )
  );
  const sig2 = await deployer.signMessage(ethers.getBytes(hash2));

  await identity2.connect(investor2).addClaim(KYC_TOPIC, 1, claimIssuerAddress, sig2, data2, "");
  console.log("KYC claim added for Investor 2");

  // Register identities in the registry
  await identityRegistry.registerIdentity(investor1.address, await identity1.getAddress(), 1);
  console.log("Investor 1 registered (country: 1 - USA)");

  await identityRegistry.registerIdentity(investor2.address, await identity2.getAddress(), 44);
  console.log("Investor 2 registered (country: 44 - UK)");

  // ============================================================
  // 12. Log all deployed addresses
  // ============================================================
  console.log("\n========================================");
  console.log("      DEPLOYMENT COMPLETE");
  console.log("========================================");
  console.log("TrustedIssuersRegistry:", await trustedIssuersRegistry.getAddress());
  console.log("ClaimIssuer:           ", await claimIssuer.getAddress());
  console.log("IdentityRegistryStorage:", await identityRegistryStorage.getAddress());
  console.log("IdentityRegistry:      ", await identityRegistry.getAddress());
  console.log("CountryRestrictModule: ", await countryRestrict.getAddress());
  console.log("MaxHoldersModule:      ", await maxHolders.getAddress());
  console.log("MaxBalanceModule:      ", await maxBalance.getAddress());
  console.log("ModularCompliance:     ", await compliance.getAddress());
  console.log("RealEstateToken:       ", await token.getAddress());
  console.log("Investor 1 Identity:   ", await identity1.getAddress());
  console.log("Investor 2 Identity:   ", await identity2.getAddress());
  console.log("========================================");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
