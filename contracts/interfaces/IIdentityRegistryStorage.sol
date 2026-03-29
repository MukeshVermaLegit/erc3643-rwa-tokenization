// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IIdentity.sol";

/**
 * @title IIdentityRegistryStorage
 * @dev Interface for the storage contract that holds identity-to-wallet mappings.
 * Separating storage from logic allows upgradeability of the registry logic.
 */
interface IIdentityRegistryStorage {
    /// @dev Emitted when an identity is stored.
    event IdentityStored(address indexed investorAddress, IIdentity indexed identity);

    /// @dev Emitted when an identity is removed.
    event IdentityRemoved(address indexed investorAddress, IIdentity indexed identity);

    /// @dev Emitted when an identity mapping is modified.
    event IdentityModified(IIdentity indexed oldIdentity, IIdentity indexed newIdentity);

    /// @dev Emitted when a country code is modified.
    event CountryModified(address indexed investorAddress, uint16 indexed country);

    /// @dev Emitted when an identity registry is bound to this storage.
    event IdentityRegistryBound(address indexed identityRegistry);

    /// @dev Emitted when an identity registry is unbound from this storage.
    event IdentityRegistryUnbound(address indexed identityRegistry);

    /**
     * @dev Adds an identity to storage.
     * @param userAddress The investor wallet address.
     * @param identity The investor's Identity contract.
     * @param country The investor's country code.
     */
    function addIdentityToStorage(address userAddress, IIdentity identity, uint16 country) external;

    /**
     * @dev Removes an identity from storage.
     * @param userAddress The investor wallet address to remove.
     */
    function removeIdentityFromStorage(address userAddress) external;

    /**
     * @dev Updates the Identity contract for a user.
     * @param userAddress The investor wallet address.
     * @param identity The new Identity contract.
     */
    function modifyStoredIdentity(address userAddress, IIdentity identity) external;

    /**
     * @dev Updates the country code for a user.
     * @param userAddress The investor wallet address.
     * @param country The new country code.
     */
    function modifyStoredInvestorCountry(address userAddress, uint16 country) external;

    /**
     * @dev Binds an identity registry to this storage.
     * @param identityRegistry The address of the identity registry.
     */
    function bindIdentityRegistry(address identityRegistry) external;

    /**
     * @dev Unbinds an identity registry from this storage.
     * @param identityRegistry The address of the identity registry.
     */
    function unbindIdentityRegistry(address identityRegistry) external;

    /**
     * @dev Returns the Identity contract linked to a wallet.
     * @param userAddress The investor wallet address.
     * @return The Identity contract.
     */
    function storedIdentity(address userAddress) external view returns (IIdentity);

    /**
     * @dev Returns the country code linked to a wallet.
     * @param userAddress The investor wallet address.
     * @return The country code.
     */
    function storedInvestorCountry(address userAddress) external view returns (uint16);
}
