// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Identity.sol";
import "../interfaces/IClaimIssuer.sol";

/**
 * @title ClaimIssuer
 * @notice A trusted entity that issues and verifies identity claims.
 * @dev Extends Identity so the issuer itself has an on-chain identity.
 * Claim validation recovers the signer from the signature and checks
 * that it matches the issuer owner (management key).
 */
contract ClaimIssuer is Identity, IClaimIssuer {
    /**
     * @dev Initializes the ClaimIssuer with the given owner as its management key.
     * @param initialOwner The address that owns and signs claims for this issuer.
     */
    constructor(address initialOwner) Identity(initialOwner) {}

    /**
     * @inheritdoc IClaimIssuer
     * @dev Recovers the signer from the signature and verifies it is the issuer owner.
     * The signed message is: keccak256(abi.encode(address(identity), claimTopic, data)).
     */
    function isClaimValid(
        IIdentity identity,
        uint256 claimTopic,
        bytes calldata sig,
        bytes calldata data
    ) external view override returns (bool) {
        // Reconstruct the message that was signed
        bytes32 messageHash = keccak256(abi.encode(address(identity), claimTopic, data));

        // Create the Ethereum signed message hash (EIP-191)
        bytes32 ethSignedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
        );

        // Recover the signer from the signature
        address recovered = _recover(ethSignedHash, sig);

        // Valid if the signer is the owner of this ClaimIssuer
        return recovered == owner;
    }

    /**
     * @dev Recovers an address from a signature.
     * @param hash The hash that was signed.
     * @param sig The signature bytes.
     * @return The recovered address.
     */
    function _recover(bytes32 hash, bytes memory sig) internal pure returns (address) {
        require(sig.length == 65, "ClaimIssuer: invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28, "ClaimIssuer: invalid signature v value");

        return ecrecover(hash, v, r, s);
    }
}
