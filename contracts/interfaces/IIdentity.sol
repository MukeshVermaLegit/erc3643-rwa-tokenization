// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title IIdentity
 * @dev Interface for ONCHAINID Identity contracts.
 * Each investor deploys an Identity contract that stores verifiable claims.
 */
interface IIdentity {
    /// @dev Emitted when a claim is added to the identity.
    event ClaimAdded(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);

    /// @dev Emitted when a claim is removed from the identity.
    event ClaimRemoved(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);

    /**
     * @dev Adds or updates a claim on this identity.
     * @param topic The claim topic (e.g., 1 = KYC).
     * @param scheme The scheme used for the claim signature (e.g., 1 = ECDSA).
     * @param issuer The address of the claim issuer.
     * @param signature The issuer's signature over the claim data.
     * @param data The claim data.
     * @param uri An optional URI for additional claim information.
     * @return claimId The unique identifier for this claim.
     */
    function addClaim(uint256 topic, uint256 scheme, address issuer, bytes calldata signature, bytes calldata data, string calldata uri) external returns (bytes32 claimId);

    /**
     * @dev Removes a claim from this identity.
     * @param claimId The unique identifier of the claim to remove.
     */
    function removeClaim(bytes32 claimId) external;

    /**
     * @dev Returns a claim by its ID.
     * @param claimId The unique identifier of the claim.
     * @return topic The claim topic.
     * @return scheme The signature scheme.
     * @return issuer The claim issuer address.
     * @return signature The issuer's signature.
     * @return data The claim data.
     * @return uri The claim URI.
     */
    function getClaim(bytes32 claimId) external view returns (uint256 topic, uint256 scheme, address issuer, bytes memory signature, bytes memory data, string memory uri);

    /**
     * @dev Returns the list of claim IDs for a given topic.
     * @param topic The claim topic to query.
     * @return An array of claim IDs.
     */
    function getClaimIdsByTopic(uint256 topic) external view returns (bytes32[] memory);
}
