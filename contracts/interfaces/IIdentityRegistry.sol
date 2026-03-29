// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IIdentity.sol";
import "./IIdentityRegistryStorage.sol";
import "./ITrustedIssuersRegistry.sol";

/**
 * @title IIdentityRegistry
 * @dev Interface for the identity registry that maps investor wallets to their
 * on-chain identities and verifies investor eligibility for token transfers.
 */
interface IIdentityRegistry {
    /// @dev Emitted when an identity is registered.
    event IdentityRegistered(address indexed investorAddress, IIdentity indexed identity);

    /// @dev Emitted when an identity is removed.
    event IdentityRemoved(address indexed investorAddress, IIdentity indexed identity);

    /// @dev Emitted when an identity is updated.
    event IdentityUpdated(IIdentity indexed oldIdentity, IIdentity indexed newIdentity);

    /// @dev Emitted when a country code is updated.
    event CountryUpdated(address indexed investorAddress, uint16 indexed country);

    /// @dev Emitted when the identity storage is set.
    event IdentityStorageSet(address indexed identityStorage);

    /// @dev Emitted when the trusted issuers registry is set.
    event TrustedIssuersRegistrySet(address indexed trustedIssuersRegistry);

    /**
     * @dev Registers an investor identity.
     * @param userAddress The investor's wallet address.
     * @param identity The investor's Identity contract.
     * @param country The investor's country code.
     */
    function registerIdentity(address userAddress, IIdentity identity, uint16 country) external;

    /**
     * @dev Deletes an investor identity.
     * @param userAddress The investor's wallet address.
     */
    function deleteIdentity(address userAddress) external;

    /**
     * @dev Updates the Identity contract for an investor.
     * @param userAddress The investor's wallet address.
     * @param identity The new Identity contract.
     */
    function updateIdentity(address userAddress, IIdentity identity) external;

    /**
     * @dev Updates the country code for an investor.
     * @param userAddress The investor's wallet address.
     * @param country The new country code.
     */
    function updateCountry(address userAddress, uint16 country) external;

    /**
     * @dev Checks whether an investor is verified (has valid claims from trusted issuers).
     * @param userAddress The investor's wallet address.
     * @return True if the investor is verified.
     */
    function isVerified(address userAddress) external view returns (bool);

    /**
     * @dev Checks whether an address is registered in the registry.
     * @param userAddress The address to check.
     * @return True if the address is registered.
     */
    function contains(address userAddress) external view returns (bool);

    /**
     * @dev Returns the Identity contract for an investor.
     * @param userAddress The investor's wallet address.
     * @return The Identity contract.
     */
    function identity(address userAddress) external view returns (IIdentity);

    /**
     * @dev Returns the country code for an investor.
     * @param userAddress The investor's wallet address.
     * @return The country code.
     */
    function investorCountry(address userAddress) external view returns (uint16);

    /**
     * @dev Returns the identity registry storage contract.
     */
    function identityStorage() external view returns (IIdentityRegistryStorage);

    /**
     * @dev Returns the trusted issuers registry contract.
     */
    function issuersRegistry() external view returns (ITrustedIssuersRegistry);

    /**
     * @dev Sets the identity registry storage contract.
     * @param identityRegistryStorage The new storage contract address.
     */
    function setIdentityRegistryStorage(address identityRegistryStorage) external;

    /**
     * @dev Sets the trusted issuers registry contract.
     * @param trustedIssuersRegistry The new registry address.
     */
    function setTrustedIssuersRegistry(address trustedIssuersRegistry) external;
}
