// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IIdentityRegistryStorage.sol";

/**
 * @title IdentityRegistryStorage
 * @notice Stores the mapping between investor wallets and their on-chain identities.
 * @dev Separating storage from registry logic enables upgradeable registry contracts.
 * Only bound identity registries can modify storage.
 */
contract IdentityRegistryStorage is IIdentityRegistryStorage, Ownable {
    /// @dev Mapping from investor wallet to Identity contract.
    mapping(address => IIdentity) private _identities;

    /// @dev Mapping from investor wallet to country code.
    mapping(address => uint16) private _countries;

    /// @dev Set of bound identity registries authorized to modify this storage.
    mapping(address => bool) private _boundRegistries;

    /// @dev Modifier that restricts access to bound identity registries.
    modifier onlyBoundRegistry() {
        require(_boundRegistries[msg.sender], "IdentityRegistryStorage: caller is not a bound registry");
        _;
    }

    /// @inheritdoc IIdentityRegistryStorage
    function addIdentityToStorage(
        address userAddress,
        IIdentity identity,
        uint16 country
    ) external override onlyBoundRegistry {
        require(userAddress != address(0), "IdentityRegistryStorage: zero address");
        require(address(identity) != address(0), "IdentityRegistryStorage: zero identity");
        require(address(_identities[userAddress]) == address(0), "IdentityRegistryStorage: identity already stored");

        _identities[userAddress] = identity;
        _countries[userAddress] = country;

        emit IdentityStored(userAddress, identity);
        emit CountryModified(userAddress, country);
    }

    /// @inheritdoc IIdentityRegistryStorage
    function removeIdentityFromStorage(address userAddress) external override onlyBoundRegistry {
        require(address(_identities[userAddress]) != address(0), "IdentityRegistryStorage: identity not found");

        IIdentity oldIdentity = _identities[userAddress];
        delete _identities[userAddress];
        delete _countries[userAddress];

        emit IdentityRemoved(userAddress, oldIdentity);
    }

    /// @inheritdoc IIdentityRegistryStorage
    function modifyStoredIdentity(address userAddress, IIdentity identity) external override onlyBoundRegistry {
        require(address(_identities[userAddress]) != address(0), "IdentityRegistryStorage: identity not found");
        require(address(identity) != address(0), "IdentityRegistryStorage: zero identity");

        IIdentity oldIdentity = _identities[userAddress];
        _identities[userAddress] = identity;

        emit IdentityModified(oldIdentity, identity);
    }

    /// @inheritdoc IIdentityRegistryStorage
    function modifyStoredInvestorCountry(address userAddress, uint16 country) external override onlyBoundRegistry {
        require(address(_identities[userAddress]) != address(0), "IdentityRegistryStorage: identity not found");

        _countries[userAddress] = country;

        emit CountryModified(userAddress, country);
    }

    /// @inheritdoc IIdentityRegistryStorage
    function bindIdentityRegistry(address identityRegistry) external override onlyOwner {
        require(identityRegistry != address(0), "IdentityRegistryStorage: zero address");
        require(!_boundRegistries[identityRegistry], "IdentityRegistryStorage: already bound");

        _boundRegistries[identityRegistry] = true;

        emit IdentityRegistryBound(identityRegistry);
    }

    /// @inheritdoc IIdentityRegistryStorage
    function unbindIdentityRegistry(address identityRegistry) external override onlyOwner {
        require(_boundRegistries[identityRegistry], "IdentityRegistryStorage: not bound");

        _boundRegistries[identityRegistry] = false;

        emit IdentityRegistryUnbound(identityRegistry);
    }

    /// @inheritdoc IIdentityRegistryStorage
    function storedIdentity(address userAddress) external view override returns (IIdentity) {
        return _identities[userAddress];
    }

    /// @inheritdoc IIdentityRegistryStorage
    function storedInvestorCountry(address userAddress) external view override returns (uint16) {
        return _countries[userAddress];
    }
}
