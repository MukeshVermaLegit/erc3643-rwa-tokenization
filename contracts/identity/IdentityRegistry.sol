// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IIdentityRegistry.sol";
import "../interfaces/IClaimIssuer.sol";

/**
 * @title IdentityRegistry
 * @notice Maps investor wallets to on-chain identities and verifies investor eligibility.
 * @dev Verification checks that the investor has a valid claim from a trusted issuer
 * for every required claim topic. Uses a separate storage contract for data.
 */
contract IdentityRegistry is IIdentityRegistry, Ownable {
    /// @dev The storage contract holding identity mappings.
    IIdentityRegistryStorage private _identityStorage;

    /// @dev The trusted issuers registry.
    ITrustedIssuersRegistry private _issuersRegistry;

    /// @dev Required claim topics that investors must have for verification.
    uint256[] private _requiredClaimTopics;

    /// @dev Agents authorized to register/update identities.
    mapping(address => bool) private _agents;

    /// @dev Modifier restricting access to agents or owner.
    modifier onlyAgentOrOwner() {
        require(msg.sender == owner() || _agents[msg.sender], "IdentityRegistry: caller is not agent or owner");
        _;
    }

    /**
     * @dev Initializes the registry with its dependencies.
     * @param trustedIssuersRegistry The trusted issuers registry address.
     * @param identityStorage_ The identity registry storage address.
     */
    constructor(
        address trustedIssuersRegistry,
        address identityStorage_
    ) {
        require(trustedIssuersRegistry != address(0), "IdentityRegistry: zero issuers registry");
        require(identityStorage_ != address(0), "IdentityRegistry: zero storage");

        _issuersRegistry = ITrustedIssuersRegistry(trustedIssuersRegistry);
        _identityStorage = IIdentityRegistryStorage(identityStorage_);
    }

    /**
     * @dev Adds a required claim topic for investor verification.
     * @param claimTopic The claim topic to require.
     */
    function addRequiredClaimTopic(uint256 claimTopic) external onlyOwner {
        _requiredClaimTopics.push(claimTopic);
    }

    /**
     * @dev Removes a required claim topic.
     * @param claimTopic The claim topic to remove.
     */
    function removeRequiredClaimTopic(uint256 claimTopic) external onlyOwner {
        uint256 length = _requiredClaimTopics.length;
        for (uint256 i = 0; i < length; i++) {
            if (_requiredClaimTopics[i] == claimTopic) {
                _requiredClaimTopics[i] = _requiredClaimTopics[length - 1];
                _requiredClaimTopics.pop();
                break;
            }
        }
    }

    /**
     * @dev Returns the array of required claim topics.
     */
    function getRequiredClaimTopics() external view returns (uint256[] memory) {
        return _requiredClaimTopics;
    }

    /**
     * @dev Adds an agent.
     * @param agent The agent address.
     */
    function addAgent(address agent) external onlyOwner {
        _agents[agent] = true;
    }

    /**
     * @dev Removes an agent.
     * @param agent The agent address.
     */
    function removeAgent(address agent) external onlyOwner {
        _agents[agent] = false;
    }

    /// @inheritdoc IIdentityRegistry
    function registerIdentity(
        address userAddress,
        IIdentity _identity,
        uint16 country
    ) external override onlyAgentOrOwner {
        _identityStorage.addIdentityToStorage(userAddress, _identity, country);
        emit IdentityRegistered(userAddress, _identity);
    }

    /// @inheritdoc IIdentityRegistry
    function deleteIdentity(address userAddress) external override onlyAgentOrOwner {
        IIdentity oldIdentity = _identityStorage.storedIdentity(userAddress);
        _identityStorage.removeIdentityFromStorage(userAddress);
        emit IdentityRemoved(userAddress, oldIdentity);
    }

    /// @inheritdoc IIdentityRegistry
    function updateIdentity(address userAddress, IIdentity _identity) external override onlyAgentOrOwner {
        IIdentity oldIdentity = _identityStorage.storedIdentity(userAddress);
        _identityStorage.modifyStoredIdentity(userAddress, _identity);
        emit IdentityUpdated(oldIdentity, _identity);
    }

    /// @inheritdoc IIdentityRegistry
    function updateCountry(address userAddress, uint16 country) external override onlyAgentOrOwner {
        _identityStorage.modifyStoredInvestorCountry(userAddress, country);
        emit CountryUpdated(userAddress, country);
    }

    /// @inheritdoc IIdentityRegistry
    function isVerified(address userAddress) external view override returns (bool) {
        // Must have an identity registered
        IIdentity userIdentity = _identityStorage.storedIdentity(userAddress);
        if (address(userIdentity) == address(0)) {
            return false;
        }

        // If no required claim topics, the investor is verified by default
        if (_requiredClaimTopics.length == 0) {
            return true;
        }

        // Check each required claim topic
        for (uint256 i = 0; i < _requiredClaimTopics.length; i++) {
            uint256 topic = _requiredClaimTopics[i];

            // Get trusted issuers for this topic
            IClaimIssuer[] memory trustedIssuers = _issuersRegistry.getTrustedIssuersForClaimTopic(topic);
            if (trustedIssuers.length == 0) {
                return false;
            }

            bool validClaimFound = false;

            // Check if the investor has a valid claim from any trusted issuer for this topic
            for (uint256 j = 0; j < trustedIssuers.length; j++) {
                bytes32 claimId = keccak256(abi.encode(address(trustedIssuers[j]), topic));
                (uint256 claimTopic, , address issuer, bytes memory sig, bytes memory data, ) = userIdentity.getClaim(claimId);

                if (issuer == address(0)) {
                    continue;
                }

                if (claimTopic == topic) {
                    // Verify the claim signature with the issuer
                    bool isValid = trustedIssuers[j].isClaimValid(userIdentity, claimTopic, sig, data);
                    if (isValid) {
                        validClaimFound = true;
                        break;
                    }
                }
            }

            if (!validClaimFound) {
                return false;
            }
        }

        return true;
    }

    /// @inheritdoc IIdentityRegistry
    function contains(address userAddress) external view override returns (bool) {
        return address(_identityStorage.storedIdentity(userAddress)) != address(0);
    }

    /// @inheritdoc IIdentityRegistry
    function identity(address userAddress) external view override returns (IIdentity) {
        return _identityStorage.storedIdentity(userAddress);
    }

    /// @inheritdoc IIdentityRegistry
    function investorCountry(address userAddress) external view override returns (uint16) {
        return _identityStorage.storedInvestorCountry(userAddress);
    }

    /// @inheritdoc IIdentityRegistry
    function identityStorage() external view override returns (IIdentityRegistryStorage) {
        return _identityStorage;
    }

    /// @inheritdoc IIdentityRegistry
    function issuersRegistry() external view override returns (ITrustedIssuersRegistry) {
        return _issuersRegistry;
    }

    /// @inheritdoc IIdentityRegistry
    function setIdentityRegistryStorage(address identityRegistryStorage) external override onlyOwner {
        require(identityRegistryStorage != address(0), "IdentityRegistry: zero address");
        _identityStorage = IIdentityRegistryStorage(identityRegistryStorage);
        emit IdentityStorageSet(identityRegistryStorage);
    }

    /// @inheritdoc IIdentityRegistry
    function setTrustedIssuersRegistry(address trustedIssuersRegistry) external override onlyOwner {
        require(trustedIssuersRegistry != address(0), "IdentityRegistry: zero address");
        _issuersRegistry = ITrustedIssuersRegistry(trustedIssuersRegistry);
        emit TrustedIssuersRegistrySet(trustedIssuersRegistry);
    }
}
