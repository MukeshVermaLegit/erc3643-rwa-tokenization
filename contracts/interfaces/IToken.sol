// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IIdentityRegistry.sol";
import "./ICompliance.sol";

/**
 * @title IToken
 * @dev Interface for the ERC-3643 compliant security token.
 * Extends standard ERC-20 with identity verification, compliance checks,
 * token freezing, forced transfers, and address recovery.
 */
interface IToken {
    /// @dev Emitted when tokens are frozen for an address.
    event TokensFrozen(address indexed userAddress, uint256 amount);

    /// @dev Emitted when tokens are unfrozen for an address.
    event TokensUnfrozen(address indexed userAddress, uint256 amount);

    /// @dev Emitted when the token is paused.
    event Paused(address indexed account);

    /// @dev Emitted when the token is unpaused.
    event Unpaused(address indexed account);

    /// @dev Emitted when tokens are recovered from a lost wallet.
    event RecoverySuccess(address indexed lostWallet, address indexed newWallet, address indexed investorIdentity);

    /// @dev Emitted when an agent is added.
    event AgentAdded(address indexed agent);

    /// @dev Emitted when an agent is removed.
    event AgentRemoved(address indexed agent);

    /// @dev Emitted when the identity registry is set.
    event IdentityRegistrySet(address indexed identityRegistry);

    /// @dev Emitted when the compliance contract is set.
    event ComplianceSet(address indexed compliance);

    /**
     * @dev Mints tokens to a verified address. Only callable by agents.
     * @param to The recipient address.
     * @param amount The amount to mint.
     */
    function mint(address to, uint256 amount) external;

    /**
     * @dev Burns tokens from an address. Only callable by agents.
     * @param from The address to burn from.
     * @param amount The amount to burn.
     */
    function burn(address from, uint256 amount) external;

    /**
     * @dev Force-transfers tokens between addresses. Only callable by agents.
     * Bypasses compliance checks for regulatory actions.
     * @param from The sender address.
     * @param to The receiver address.
     * @param amount The amount to transfer.
     */
    function forcedTransfer(address from, address to, uint256 amount) external;

    /**
     * @dev Freezes a partial amount of tokens for an address. Only callable by agents.
     * @param userAddress The address to freeze tokens for.
     * @param amount The amount to freeze.
     */
    function freezePartialTokens(address userAddress, uint256 amount) external;

    /**
     * @dev Unfreezes a partial amount of tokens for an address. Only callable by agents.
     * @param userAddress The address to unfreeze tokens for.
     * @param amount The amount to unfreeze.
     */
    function unfreezePartialTokens(address userAddress, uint256 amount) external;

    /**
     * @dev Recovers tokens from a lost wallet to a new wallet. Only callable by agents.
     * @param lostWallet The wallet that lost access.
     * @param newWallet The replacement wallet.
     * @param investorIdentity The investor's identity contract address.
     */
    function recoveryAddress(address lostWallet, address newWallet, address investorIdentity) external;

    /**
     * @dev Pauses all token transfers. Only callable by agents.
     */
    function pause() external;

    /**
     * @dev Resumes token transfers. Only callable by agents.
     */
    function unpause() external;

    /**
     * @dev Sets the identity registry contract. Only callable by owner.
     * @param identityRegistry The new identity registry.
     */
    function setIdentityRegistry(address identityRegistry) external;

    /**
     * @dev Sets the compliance contract. Only callable by owner.
     * @param compliance The new compliance contract.
     */
    function setCompliance(address compliance) external;

    /**
     * @dev Adds an agent. Only callable by owner.
     * @param agent The agent address to add.
     */
    function addAgent(address agent) external;

    /**
     * @dev Removes an agent. Only callable by owner.
     * @param agent The agent address to remove.
     */
    function removeAgent(address agent) external;

    /**
     * @dev Returns the token balance of an address (inherited from ERC-20).
     * @param account The address to query.
     * @return The token balance.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the frozen token amount for an address.
     * @param userAddress The address to query.
     * @return The frozen amount.
     */
    function getFrozenTokens(address userAddress) external view returns (uint256);

    /**
     * @dev Returns whether an address is an agent.
     * @param agent The address to check.
     * @return True if the address is an agent.
     */
    function isAgent(address agent) external view returns (bool);

    /**
     * @dev Returns the identity registry.
     */
    function identityRegistry() external view returns (IIdentityRegistry);

    /**
     * @dev Returns the compliance contract.
     */
    function compliance() external view returns (ICompliance);
}
