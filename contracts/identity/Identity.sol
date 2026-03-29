// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../interfaces/IIdentity.sol";

/**
 * @title Identity
 * @notice ONCHAINID-style identity contract that stores verifiable claims.
 * @dev Each investor deploys one Identity contract. Claims are added by claim issuers
 * and identified by keccak256(abi.encode(issuer, topic)).
 */
contract Identity is IIdentity {
    /// @dev Struct representing a verifiable claim.
    struct Claim {
        uint256 topic;
        uint256 scheme;
        address issuer;
        bytes signature;
        bytes data;
        string uri;
    }

    /// @dev Owner of this identity (typically the investor or a management key).
    address public owner;

    /// @dev Mapping from claimId to Claim struct.
    mapping(bytes32 => Claim) internal _claims;

    /// @dev Mapping from claim topic to array of claimIds for that topic.
    mapping(uint256 => bytes32[]) internal _claimsByTopic;

    /// @dev Modifier restricting access to the identity owner or the claim issuer.
    modifier onlyOwnerOrIssuer(bytes32 claimId) {
        require(
            msg.sender == owner || msg.sender == _claims[claimId].issuer,
            "Identity: caller is not owner or issuer"
        );
        _;
    }

    /// @dev Modifier restricting access to the identity owner.
    modifier onlyOwner() {
        require(msg.sender == owner, "Identity: caller is not owner");
        _;
    }

    /**
     * @dev Initializes the identity with the given owner.
     * @param initialOwner The address that will own this identity.
     */
    constructor(address initialOwner) {
        require(initialOwner != address(0), "Identity: owner is zero address");
        owner = initialOwner;
    }

    /// @inheritdoc IIdentity
    function addClaim(
        uint256 topic,
        uint256 scheme,
        address issuer,
        bytes calldata signature,
        bytes calldata data,
        string calldata uri
    ) external override returns (bytes32 claimId) {
        // Only the owner or the issuer itself can add claims
        require(
            msg.sender == owner || msg.sender == issuer,
            "Identity: caller not authorized to add claim"
        );

        claimId = keccak256(abi.encode(issuer, topic));

        // If claim already exists, update it
        if (_claims[claimId].issuer != address(0)) {
            _claims[claimId] = Claim(topic, scheme, issuer, signature, data, uri);
            emit ClaimAdded(claimId, topic, scheme, issuer, signature, data, uri);
            return claimId;
        }

        _claims[claimId] = Claim(topic, scheme, issuer, signature, data, uri);
        _claimsByTopic[topic].push(claimId);

        emit ClaimAdded(claimId, topic, scheme, issuer, signature, data, uri);
    }

    /// @inheritdoc IIdentity
    function removeClaim(bytes32 claimId) external override onlyOwnerOrIssuer(claimId) {
        Claim memory c = _claims[claimId];
        require(c.issuer != address(0), "Identity: claim does not exist");

        uint256 topic = c.topic;

        // Remove from _claimsByTopic array
        bytes32[] storage topicClaims = _claimsByTopic[topic];
        for (uint256 i = 0; i < topicClaims.length; i++) {
            if (topicClaims[i] == claimId) {
                topicClaims[i] = topicClaims[topicClaims.length - 1];
                topicClaims.pop();
                break;
            }
        }

        delete _claims[claimId];

        emit ClaimRemoved(claimId, c.topic, c.scheme, c.issuer, c.signature, c.data, c.uri);
    }

    /// @inheritdoc IIdentity
    function getClaim(bytes32 claimId)
        external
        view
        override
        returns (
            uint256 topic,
            uint256 scheme,
            address issuer,
            bytes memory signature,
            bytes memory data,
            string memory uri
        )
    {
        Claim memory c = _claims[claimId];
        return (c.topic, c.scheme, c.issuer, c.signature, c.data, c.uri);
    }

    /// @inheritdoc IIdentity
    function getClaimIdsByTopic(uint256 topic) external view override returns (bytes32[] memory) {
        return _claimsByTopic[topic];
    }
}
