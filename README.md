# ERC-3643 Tokenized Real Estate

A compliant security token project implementing the **ERC-3643 standard (T-REX protocol)** for tokenizing real estate assets. All contracts are written from scratch in Solidity to demonstrate the full architecture of regulated token issuance, identity-bound transfers, and modular compliance enforcement.

> **Deployed & Verified on Sepolia Testnet** --- All 11 contracts are live and source-verified on Etherscan.

---

## Deployed Contracts (Sepolia Testnet)

| Contract | Address | Etherscan |
|---|---|---|
| TrustedIssuersRegistry | `0xC48D61bbD621513F30f568a8194219f768d62aAF` | [View](https://sepolia.etherscan.io/address/0xC48D61bbD621513F30f568a8194219f768d62aAF#code) |
| ClaimIssuer | `0x72Cd0B9BAd1BEAdE58a7369c86523573A6127DD5` | [View](https://sepolia.etherscan.io/address/0x72Cd0B9BAd1BEAdE58a7369c86523573A6127DD5#code) |
| IdentityRegistryStorage | `0x448219f0f860899f409248Ab66ae3912E1a12D2e` | [View](https://sepolia.etherscan.io/address/0x448219f0f860899f409248Ab66ae3912E1a12D2e#code) |
| IdentityRegistry | `0xd8583E1e2E5e14902A00B899E857258D2D318f39` | [View](https://sepolia.etherscan.io/address/0xd8583E1e2E5e14902A00B899E857258D2D318f39#code) |
| CountryRestrictModule | `0x3702C213f15228a0e4d0097a7bF15719fe736ef3` | [View](https://sepolia.etherscan.io/address/0x3702C213f15228a0e4d0097a7bF15719fe736ef3#code) |
| MaxHoldersModule | `0x3769b7085cF45DB971aaF5a1f79e5c0DFb00fa4c` | [View](https://sepolia.etherscan.io/address/0x3769b7085cF45DB971aaF5a1f79e5c0DFb00fa4c#code) |
| MaxBalanceModule | `0x5b2c7445dDA24e48E4B7172001696B5ec804E6a8` | [View](https://sepolia.etherscan.io/address/0x5b2c7445dDA24e48E4B7172001696B5ec804E6a8#code) |
| ModularCompliance | `0xE0796AB044621259e565A85bE3066E95291b6983` | [View](https://sepolia.etherscan.io/address/0xE0796AB044621259e565A85bE3066E95291b6983#code) |
| **RealEstateToken** | `0x22CbE1A5A8af36D0f77e339E473dD468969434a4` | [View](https://sepolia.etherscan.io/address/0x22CbE1A5A8af36D0f77e339E473dD468969434a4#code) |
| Investor 1 Identity | `0x1384b449b30A58AF95463969e394D2cDeB6aF882` | [View](https://sepolia.etherscan.io/address/0x1384b449b30A58AF95463969e394D2cDeB6aF882#code) |
| Investor 2 Identity | `0xcc33b74Ff94Eed2779EE95C9a1cA541FE262d867` | [View](https://sepolia.etherscan.io/address/0xcc33b74Ff94Eed2779EE95C9a1cA541FE262d867#code) |

**Network:** Sepolia (Chain ID: 11155111) | **Deployer:** `0x49D730c95f70206b49ecC146C30BD4950369F8a9`

---

## What is ERC-3643?

**ERC-3643** (also known as the T-REX protocol --- Token for Regulated EXchanges) is an Ethereum standard for compliant security tokens. Unlike utility tokens (ERC-20), security tokens represent ownership of real-world assets and must comply with securities regulations.

ERC-3643 solves this by enforcing compliance at the smart contract level:

- **Identity Binding** --- Every token holder must have an on-chain identity (ONCHAINID) with verifiable claims (e.g., KYC/AML approval)
- **Transfer Restrictions** --- Every transfer is checked against a modular compliance framework before execution
- **Claim Verification** --- Claims are cryptographically signed by trusted issuers and verified on-chain
- **Regulatory Actions** --- Agents can freeze tokens, force transfers, and recover lost wallets

---

## Architecture

```
+---------------------------------------------------------------+
|                   RealEstateToken (ERC-20)                     |
|  mint / burn / transfer / forcedTransfer / freeze / recover   |
|                                                               |
|   Every transfer checks:                                      |
|   1. identityRegistry.isVerified(to)                          |
|   2. compliance.canTransfer(from, to, amount)                 |
+---------------+-------------------------------+---------------+
                |                               |
                v                               v
+---------------------------+    +---------------------------------+
|    IdentityRegistry       |    |      ModularCompliance          |
|                           |    |                                 |
|  wallet --> Identity      |    |  Iterates over modules:         |
|  wallet --> country code  |    |  +---------------------------+  |
|                           |    |  | CountryRestrictModule     |  |
|  isVerified() checks:    |    |  | MaxHoldersModule          |  |
|  - identity exists        |    |  | MaxBalanceModule          |  |
|  - valid KYC claim        |    |  +---------------------------+  |
|    from trusted issuer    |    |                                 |
+-------------+-------------+    +---------------------------------+
              |
              v
+----------------------------------------------+
|        TrustedIssuersRegistry                |
|                                              |
|  ClaimIssuer A --> trusted for [KYC]         |
|  ClaimIssuer B --> trusted for [KYC, AML]    |
+--------------+-------------------------------+
               |
               v
+----------------------------------------------+
|  Identity (ONCHAINID)         ClaimIssuer    |
|                                              |
|  Stores claims:                              |
|  claimId --> { topic, scheme, issuer,        |
|               signature, data, uri }         |
|                                              |
|  ClaimIssuer.isClaimValid() recovers         |
|  signer from ECDSA signature                |
+----------------------------------------------+
```

---

## Contracts

| Contract | Location | Purpose |
|---|---|---|
| `RealEstateToken` | `contracts/token/` | Main ERC-3643 token --- ERC-20 with compliance hooks on every transfer. Decimals = 0 (whole units). |
| `Identity` | `contracts/identity/` | ONCHAINID identity contract storing verifiable claims for each investor |
| `ClaimIssuer` | `contracts/identity/` | Extends Identity --- issues and cryptographically verifies KYC/AML claims via ECDSA |
| `IdentityRegistry` | `contracts/identity/` | Maps wallets to Identity contracts, verifies investor eligibility |
| `IdentityRegistryStorage` | `contracts/identity/` | Separated storage layer for identity mappings (upgradeability pattern) |
| `TrustedIssuersRegistry` | `contracts/registry/` | Maintains the list of trusted claim issuers and their authorized topics |
| `ModularCompliance` | `contracts/compliance/` | Aggregates compliance modules --- all must pass for a transfer to succeed |
| `CountryRestrictModule` | `contracts/compliance/modules/` | Blocks transfers involving restricted jurisdictions |
| `MaxHoldersModule` | `contracts/compliance/modules/` | Enforces a cap on total unique token holders |
| `MaxBalanceModule` | `contracts/compliance/modules/` | Enforces a maximum token balance per investor |

---

## How It All Connects

```
RealEstateToken
    |
    |-- references --> IdentityRegistry
    |       |-- references --> IdentityRegistryStorage
    |       |       |-- stores --> mapping(wallet => Identity contract)
    |       |       |-- stores --> mapping(wallet => country code)
    |       |
    |       |-- references --> TrustedIssuersRegistry
    |       |       |-- stores --> array of trusted ClaimIssuer contracts
    |       |       |-- stores --> mapping(issuer => authorized topics)
    |       |
    |       |-- isVerified(wallet) flow:
    |               1. Look up wallet's Identity from storage
    |               2. For each required claim topic (e.g., KYC):
    |                  a. Get trusted issuers for that topic
    |                  b. Check if wallet's Identity has a valid claim
    |                  c. Verify ECDSA signature via ClaimIssuer
    |
    |-- references --> ModularCompliance
            |-- iterates --> [CountryRestrictModule, MaxHoldersModule, MaxBalanceModule]
            |-- canTransfer() = ALL modules must return true
            |-- transferred() = notify ALL modules to update state
```

---

## Transaction Flows

### 1. Token Minting (Agent mints tokens to a verified investor)

```
Agent calls token.mint(investor, 1000)
    |
    +---> Is caller an agent?  --> NO --> REVERT
    |
    +---> Is token paused?  --> YES --> REVERT
    |
    +---> identityRegistry.isVerified(investor)?
    |         |
    |         +---> Investor has registered Identity?  --> NO --> REVERT
    |         |
    |         +---> Identity has valid KYC claim
    |                from a trusted issuer?  --> NO --> REVERT
    |
    +---> MINT EXECUTES (ERC-20 _mint)
    |
    +---> compliance.created(investor, 1000)
              |
              +---> MaxHoldersModule: track new holder
              +---> MaxBalanceModule: no-op (stateless)
              +---> CountryRestrictModule: no-op (stateless)
```

### 2. Token Transfer (Investor-to-investor transfer)

```
Investor A calls token.transfer(Investor B, 1000)
    |
    +---> Is token paused?  --> YES --> REVERT
    |
    +---> Does A have enough unfrozen balance?
    |     (balanceOf(A) - frozenTokens(A) >= 1000)  --> NO --> REVERT
    |
    +---> identityRegistry.isVerified(B)?
    |         |
    |         +---> B has registered Identity?  --> NO --> REVERT
    |         +---> B has valid KYC claim?  --> NO --> REVERT
    |
    +---> compliance.canTransfer(A, B, 1000)?
    |         |
    |         +---> CountryRestrictModule:
    |         |       A or B in restricted country?  --> YES --> REVERT
    |         |
    |         +---> MaxHoldersModule:
    |         |       B is new holder and count >= max?  --> YES --> REVERT
    |         |
    |         +---> MaxBalanceModule:
    |                 B's balance + 1000 > max?  --> YES --> REVERT
    |
    +---> TRANSFER EXECUTES (ERC-20 _transfer)
    |
    +---> compliance.transferred(A, B, 1000)
              |
              +---> MaxHoldersModule: add B as holder, remove A if balance = 0
              +---> MaxBalanceModule: no-op
              +---> CountryRestrictModule: no-op
```

### 3. Forced Transfer (Agent overrides normal transfer)

```
Agent calls token.forcedTransfer(from, to, 1000)
    |
    +---> Is caller an agent?  --> NO --> REVERT
    +---> Is token paused?  --> YES --> REVERT
    +---> Is recipient verified?  --> NO --> REVERT
    |
    +---> If amount > free balance:
    |         Automatically unfreeze the needed portion
    |
    +---> TRANSFER EXECUTES
    +---> compliance.transferred(from, to, 1000)
```

### 4. Address Recovery (Lost wallet scenario)

```
Agent calls token.recoveryAddress(lostWallet, newWallet, investorIdentity)
    |
    +---> Is newWallet verified?  --> NO --> REVERT
    |
    +---> Transfer ALL tokens from lostWallet to newWallet
    +---> Move frozen tokens mapping to newWallet
    +---> Notify compliance
    +---> Emit RecoverySuccess
```

### 5. Claim Verification (How KYC is checked)

```
identityRegistry.isVerified(wallet)
    |
    +---> identityStorage.storedIdentity(wallet) --> Identity contract
    |
    +---> For each requiredClaimTopic (e.g., topic 1 = KYC):
    |         |
    |         +---> trustedIssuersRegistry.getTrustedIssuersForClaimTopic(1)
    |         |         --> [ClaimIssuer_A, ClaimIssuer_B, ...]
    |         |
    |         +---> For each trusted issuer:
    |                   |
    |                   +---> claimId = keccak256(issuer, topic)
    |                   +---> identity.getClaim(claimId) --> {signature, data, ...}
    |                   +---> claimIssuer.isClaimValid(identity, topic, sig, data)
    |                            |
    |                            +---> Reconstruct signed hash
    |                            +---> ecrecover(hash, signature) == issuer.owner?
    |                            +---> YES --> Wallet is VERIFIED for this topic
    |
    +---> All required topics verified?  --> YES --> return true
```

---

## Deployment Flow

The deploy script (`scripts/deploy.js`) executes these steps in order:

| Step | Action | Dependencies |
|---|---|---|
| 1 | Deploy `TrustedIssuersRegistry` | None |
| 2 | Deploy `ClaimIssuer` | Deployer address (constructor arg) |
| 3 | Register ClaimIssuer as trusted for KYC (topic 1) | Steps 1, 2 |
| 4 | Deploy `IdentityRegistryStorage` | None |
| 5 | Deploy `IdentityRegistry` | Steps 1, 4 (constructor args) |
| 6 | Bind storage to registry + add KYC as required claim | Steps 4, 5 |
| 7 | Deploy compliance modules (3 contracts) | None |
| 8 | Deploy `ModularCompliance` + add all modules | Step 7 |
| 9 | Deploy `RealEstateToken` + bind to compliance | Steps 5, 8 |
| 10 | Configure compliance rules | Step 8 |
| 11 | Create investor identities, sign KYC claims, register | Steps 2, 5, 9 |
| 12 | Log all deployed addresses | All steps |

**Current configuration:**
- Max holders: 100
- Max balance per investor: 10,000 tokens
- Restricted country: 999 (placeholder)
- Required claim: KYC (topic 1)
- Token decimals: 0 (whole units for real estate)

---

## Setup

### Prerequisites

- Node.js >= 16
- npm

### Install

```bash
npm install
```

### Compile

```bash
npx hardhat compile
```

### Test

```bash
npx hardhat test
```

### Deploy (local)

```bash
npx hardhat node
# In a separate terminal:
npx hardhat run scripts/deploy.js --network localhost
```

### Deploy (Sepolia)

1. Create a `.env` file with your private keys and API keys:
   ```
   INFURA_API_KEY=your_infura_key
   DEPLOYER_PRIVATE_KEY=your_64_hex_char_key
   INVESTOR1_PRIVATE_KEY=your_64_hex_char_key
   INVESTOR2_PRIVATE_KEY=your_64_hex_char_key
   ETHERSCAN_API_KEY=your_etherscan_key
   ```

2. Deploy:
   ```bash
   npx hardhat run scripts/deploy.js --network sepolia
   ```

3. Verify contracts on Etherscan:
   ```bash
   # Contracts with no constructor args
   npx hardhat verify --network sepolia <CONTRACT_ADDRESS>

   # Contracts with constructor args
   npx hardhat verify --network sepolia <CONTRACT_ADDRESS> "arg1" "arg2"
   ```

---

## Test Output

```
  Compliance Modules
    CountryRestrictModule
      ✔ Should block transfer to restricted country
      ✔ Should allow transfer to non-restricted country
    MaxHoldersModule
      ✔ Should enforce max holder limit
    MaxBalanceModule
      ✔ Should enforce max balance per investor
    Module Management
      ✔ Should allow removing a compliance module

  Identity & Claim Verification
    Identity Registry
      ✔ Should register an identity in the registry
      ✔ Should verify an investor with valid KYC claim
      ✔ Should fail verification without KYC claim
      ✔ Should update investor country code
    Trusted Issuers Registry
      ✔ Should add and remove trusted issuers

  RealEstateToken
    Minting
      ✔ Should mint tokens to a verified investor
    Transfers
      ✔ Should transfer tokens between verified investors
      ✔ Should block transfer to unverified wallet
    Forced Transfer
      ✔ Should allow agent to force transfer
    Freezing
      ✔ Should freeze partial tokens and block transfer of frozen amount
      ✔ Should unfreeze tokens
    Recovery
      ✔ Should recover tokens to new wallet (lost key scenario)
    Pause / Unpause
      ✔ Should pause and unpause token

  18 passing
```

---

## Key Concepts Demonstrated

1. **Compliant Token Issuance** --- Tokens can only be minted to verified (KYC-approved) investors
2. **Identity-Bound Transfers** --- Every transfer verifies the recipient has a valid on-chain identity with required claims
3. **Modular Compliance** --- Transfer rules are enforced through composable modules that can be added/removed at runtime
4. **Cryptographic Claim Verification** --- KYC claims are ECDSA-signed by trusted issuers and verified on-chain via `ecrecover`
5. **Regulatory Agent Actions** --- Authorized agents can freeze tokens, force transfers, and recover lost wallets
6. **Country-Based Restrictions** --- Transfers can be blocked based on investor jurisdiction
7. **Holder Caps** --- Total number of token holders can be limited for regulatory compliance
8. **Balance Limits** --- Maximum per-investor token holdings can be enforced
9. **Separated Storage Pattern** --- Identity registry uses a separate storage contract for upgradeability
10. **Address Recovery** --- Lost wallet scenarios are handled by transferring all tokens and frozen state to a new address

---

## Project Structure

```
contracts/
├── interfaces/          # All contract interfaces (IToken, IIdentity, ICompliance, etc.)
├── identity/            # Identity, ClaimIssuer, IdentityRegistry, IdentityRegistryStorage
├── registry/            # TrustedIssuersRegistry
├── compliance/
│   ├── ModularCompliance.sol
│   └── modules/         # CountryRestrictModule, MaxHoldersModule, MaxBalanceModule
└── token/               # RealEstateToken
scripts/
└── deploy.js            # Full deployment & configuration script
test/
├── helpers.js           # Shared test setup (deployFullSuite)
├── token.test.js        # Token minting, transfer, freeze, recovery, pause tests
├── compliance.test.js   # Compliance module tests
└── identity.test.js     # Identity registry & trusted issuer tests
```

---

## Tech Stack

- **Solidity** ^0.8.17
- **Hardhat** --- Development framework
- **OpenZeppelin** --- ERC-20 and Ownable base contracts
- **Ethers.js** --- Contract interaction
- **Chai** --- Testing assertions
- **Sepolia** --- Testnet deployment
- **Etherscan** --- Contract verification

## License

MIT
