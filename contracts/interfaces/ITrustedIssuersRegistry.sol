// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IClaimIssuer.sol";

/**
 * @title ITrustedIssuersRegistry
 * @dev Interface for the registry that tracks which claim issuers are trusted
 * and for which claim topics they are authorized.
 */
interface ITrustedIssuersRegistry {
    /// @dev Emitted when a trusted issuer is added.
    event TrustedIssuerAdded(IClaimIssuer indexed trustedIssuer, uint256[] claimTopics);

    /// @dev Emitted when a trusted issuer is removed.
    event TrustedIssuerRemoved(IClaimIssuer indexed trustedIssuer);

    /// @dev Emitted when a trusted issuer's claim topics are updated.
    event ClaimTopicsUpdated(IClaimIssuer indexed trustedIssuer, uint256[] claimTopics);

    /**
     * @dev Adds a trusted claim issuer for specific claim topics.
     * @param trustedIssuer The ClaimIssuer contract address.
     * @param claimTopics The topics this issuer is trusted for.
     */
    function addTrustedIssuer(IClaimIssuer trustedIssuer, uint256[] calldata claimTopics) external;

    /**
     * @dev Removes a trusted claim issuer.
     * @param trustedIssuer The ClaimIssuer contract to remove.
     */
    function removeTrustedIssuer(IClaimIssuer trustedIssuer) external;

    /**
     * @dev Updates the claim topics for a trusted issuer.
     * @param trustedIssuer The ClaimIssuer contract to update.
     * @param claimTopics The new set of trusted claim topics.
     */
    function updateIssuerClaimTopics(IClaimIssuer trustedIssuer, uint256[] calldata claimTopics) external;

    /**
     * @dev Returns the list of trusted issuers.
     * @return Array of trusted ClaimIssuer addresses.
     */
    function getTrustedIssuers() external view returns (IClaimIssuer[] memory);

    /**
     * @dev Checks whether an issuer is trusted.
     * @param issuer The ClaimIssuer to check.
     * @return True if the issuer is trusted.
     */
    function isTrustedIssuer(IClaimIssuer issuer) external view returns (bool);

    /**
     * @dev Returns the claim topics a trusted issuer is authorized for.
     * @param trustedIssuer The ClaimIssuer to query.
     * @return Array of claim topics.
     */
    function getTrustedIssuerClaimTopics(IClaimIssuer trustedIssuer) external view returns (uint256[] memory);

    /**
     * @dev Returns all trusted issuers for a specific claim topic.
     * @param claimTopic The claim topic to query.
     * @return Array of ClaimIssuer addresses trusted for the topic.
     */
    function getTrustedIssuersForClaimTopic(uint256 claimTopic) external view returns (IClaimIssuer[] memory);
}
