// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IIdentity.sol";

/**
 * @title IClaimIssuer
 * @dev Interface for claim issuer contracts that can issue and verify identity claims.
 * A ClaimIssuer extends Identity and adds claim validation functionality.
 */
interface IClaimIssuer is IIdentity {
    /**
     * @dev Checks whether a claim is valid.
     * @param identity The identity contract holding the claim.
     * @param claimTopic The topic of the claim to verify.
     * @param sig The signature to verify.
     * @param data The data that was signed.
     * @return True if the claim is valid (signed by an authorized key of this issuer).
     */
    function isClaimValid(IIdentity identity, uint256 claimTopic, bytes calldata sig, bytes calldata data) external view returns (bool);
}
