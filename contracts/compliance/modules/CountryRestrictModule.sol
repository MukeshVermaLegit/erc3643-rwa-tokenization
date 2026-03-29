// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../../interfaces/IComplianceModule.sol";
import "../../interfaces/IIdentityRegistry.sol";
import "../../interfaces/IToken.sol";
import "../ModularCompliance.sol";

/**
 * @title CountryRestrictModule
 * @notice Blocks transfers to/from investors in restricted countries.
 * @dev The module owner maintains a set of restricted country codes.
 * During moduleCheck, it looks up each party's country via the identity registry.
 */
contract CountryRestrictModule is IComplianceModule, Ownable {
    /// @dev Mapping from compliance address to mapping of restricted country codes.
    mapping(address => mapping(uint16 => bool)) private _restrictedCountries;

    /// @dev Emitted when a country is added to the restricted list.
    event CountryRestricted(address indexed compliance, uint16 indexed country);

    /// @dev Emitted when a country is removed from the restricted list.
    event CountryUnrestricted(address indexed compliance, uint16 indexed country);

    /**
     * @dev Adds a country to the restricted list for a compliance contract.
     * @param compliance The compliance contract address.
     * @param country The country code to restrict.
     */
    function addCountryRestriction(address compliance, uint16 country) external onlyOwner {
        _restrictedCountries[compliance][country] = true;
        emit CountryRestricted(compliance, country);
    }

    /**
     * @dev Removes a country from the restricted list.
     * @param compliance The compliance contract address.
     * @param country The country code to unrestrict.
     */
    function removeCountryRestriction(address compliance, uint16 country) external onlyOwner {
        _restrictedCountries[compliance][country] = false;
        emit CountryUnrestricted(compliance, country);
    }

    /**
     * @dev Checks if a country is restricted for a compliance contract.
     * @param compliance The compliance contract address.
     * @param country The country code to check.
     * @return True if the country is restricted.
     */
    function isCountryRestricted(address compliance, uint16 country) external view returns (bool) {
        return _restrictedCountries[compliance][country];
    }

    /// @inheritdoc IComplianceModule
    function moduleCheck(
        address from,
        address to,
        uint256 /*amount*/,
        address compliance
    ) external view override returns (bool) {
        address tokenAddr = ModularCompliance(compliance).getTokenAddress();
        IIdentityRegistry registry = IToken(tokenAddr).identityRegistry();

        // Check sender country (skip zero address for minting)
        if (from != address(0)) {
            uint16 fromCountry = registry.investorCountry(from);
            if (_restrictedCountries[compliance][fromCountry]) {
                return false;
            }
        }

        // Check receiver country (skip zero address for burning)
        if (to != address(0)) {
            uint16 toCountry = registry.investorCountry(to);
            if (_restrictedCountries[compliance][toCountry]) {
                return false;
            }
        }

        return true;
    }

    /// @inheritdoc IComplianceModule
    function moduleTransferAction(address, address, uint256, address) external override {}

    /// @inheritdoc IComplianceModule
    function moduleMintAction(address, uint256, address) external override {}

    /// @inheritdoc IComplianceModule
    function moduleBurnAction(address, uint256, address) external override {}
}
