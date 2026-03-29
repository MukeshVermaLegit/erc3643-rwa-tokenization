// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ITrustedIssuersRegistry.sol";

/**
 * @title TrustedIssuersRegistry
 * @notice Manages the list of trusted claim issuers and their authorized claim topics.
 * @dev Only trusted issuers can provide claims that are recognized during investor verification.
 */
contract TrustedIssuersRegistry is ITrustedIssuersRegistry, Ownable {
    /// @dev Array of all trusted issuers.
    IClaimIssuer[] private _trustedIssuers;

    /// @dev Mapping to check if an issuer is trusted.
    mapping(address => bool) private _isTrusted;

    /// @dev Mapping from issuer address to its trusted claim topics.
    mapping(address => uint256[]) private _issuerClaimTopics;

    /// @dev Mapping from claim topic to issuers trusted for that topic.
    mapping(uint256 => IClaimIssuer[]) private _topicToIssuers;

    /// @inheritdoc ITrustedIssuersRegistry
    function addTrustedIssuer(IClaimIssuer trustedIssuer, uint256[] calldata claimTopics) external override onlyOwner {
        require(address(trustedIssuer) != address(0), "TrustedIssuersRegistry: zero address");
        require(!_isTrusted[address(trustedIssuer)], "TrustedIssuersRegistry: issuer already trusted");
        require(claimTopics.length > 0, "TrustedIssuersRegistry: no claim topics provided");

        _trustedIssuers.push(trustedIssuer);
        _isTrusted[address(trustedIssuer)] = true;
        _issuerClaimTopics[address(trustedIssuer)] = claimTopics;

        for (uint256 i = 0; i < claimTopics.length; i++) {
            _topicToIssuers[claimTopics[i]].push(trustedIssuer);
        }

        emit TrustedIssuerAdded(trustedIssuer, claimTopics);
    }

    /// @inheritdoc ITrustedIssuersRegistry
    function removeTrustedIssuer(IClaimIssuer trustedIssuer) external override onlyOwner {
        require(_isTrusted[address(trustedIssuer)], "TrustedIssuersRegistry: issuer not trusted");

        // Remove from topics mapping
        uint256[] memory topics = _issuerClaimTopics[address(trustedIssuer)];
        for (uint256 i = 0; i < topics.length; i++) {
            _removeIssuerFromTopic(trustedIssuer, topics[i]);
        }

        // Remove from trusted issuers array
        for (uint256 i = 0; i < _trustedIssuers.length; i++) {
            if (address(_trustedIssuers[i]) == address(trustedIssuer)) {
                _trustedIssuers[i] = _trustedIssuers[_trustedIssuers.length - 1];
                _trustedIssuers.pop();
                break;
            }
        }

        _isTrusted[address(trustedIssuer)] = false;
        delete _issuerClaimTopics[address(trustedIssuer)];

        emit TrustedIssuerRemoved(trustedIssuer);
    }

    /// @inheritdoc ITrustedIssuersRegistry
    function updateIssuerClaimTopics(IClaimIssuer trustedIssuer, uint256[] calldata claimTopics) external override onlyOwner {
        require(_isTrusted[address(trustedIssuer)], "TrustedIssuersRegistry: issuer not trusted");
        require(claimTopics.length > 0, "TrustedIssuersRegistry: no claim topics provided");

        // Remove old topic mappings
        uint256[] memory oldTopics = _issuerClaimTopics[address(trustedIssuer)];
        for (uint256 i = 0; i < oldTopics.length; i++) {
            _removeIssuerFromTopic(trustedIssuer, oldTopics[i]);
        }

        // Set new topics
        _issuerClaimTopics[address(trustedIssuer)] = claimTopics;
        for (uint256 i = 0; i < claimTopics.length; i++) {
            _topicToIssuers[claimTopics[i]].push(trustedIssuer);
        }

        emit ClaimTopicsUpdated(trustedIssuer, claimTopics);
    }

    /// @inheritdoc ITrustedIssuersRegistry
    function getTrustedIssuers() external view override returns (IClaimIssuer[] memory) {
        return _trustedIssuers;
    }

    /// @inheritdoc ITrustedIssuersRegistry
    function isTrustedIssuer(IClaimIssuer issuer) external view override returns (bool) {
        return _isTrusted[address(issuer)];
    }

    /// @inheritdoc ITrustedIssuersRegistry
    function getTrustedIssuerClaimTopics(IClaimIssuer trustedIssuer) external view override returns (uint256[] memory) {
        require(_isTrusted[address(trustedIssuer)], "TrustedIssuersRegistry: issuer not trusted");
        return _issuerClaimTopics[address(trustedIssuer)];
    }

    /// @inheritdoc ITrustedIssuersRegistry
    function getTrustedIssuersForClaimTopic(uint256 claimTopic) external view override returns (IClaimIssuer[] memory) {
        return _topicToIssuers[claimTopic];
    }

    /**
     * @dev Removes an issuer from a specific topic's issuer array.
     * @param issuer The issuer to remove.
     * @param topic The topic to remove the issuer from.
     */
    function _removeIssuerFromTopic(IClaimIssuer issuer, uint256 topic) internal {
        IClaimIssuer[] storage issuers = _topicToIssuers[topic];
        for (uint256 i = 0; i < issuers.length; i++) {
            if (address(issuers[i]) == address(issuer)) {
                issuers[i] = issuers[issuers.length - 1];
                issuers.pop();
                break;
            }
        }
    }
}
