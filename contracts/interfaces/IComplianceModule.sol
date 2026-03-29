// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title IComplianceModule
 * @dev Interface for individual compliance modules that enforce specific transfer rules.
 * Each module checks one aspect of regulatory compliance.
 */
interface IComplianceModule {
    /**
     * @dev Checks whether a transfer is compliant according to this module's rules.
     * @param from The sender address.
     * @param to The receiver address.
     * @param amount The amount being transferred.
     * @param compliance The address of the calling compliance contract.
     * @return True if the transfer is compliant.
     */
    function moduleCheck(address from, address to, uint256 amount, address compliance) external view returns (bool);

    /**
     * @dev Called after a compliant transfer to update module state.
     * @param from The sender address.
     * @param to The receiver address.
     * @param amount The amount transferred.
     * @param compliance The address of the calling compliance contract.
     */
    function moduleTransferAction(address from, address to, uint256 amount, address compliance) external;

    /**
     * @dev Called after a mint to update module state.
     * @param to The receiver address.
     * @param amount The amount minted.
     * @param compliance The address of the calling compliance contract.
     */
    function moduleMintAction(address to, uint256 amount, address compliance) external;

    /**
     * @dev Called after a burn to update module state.
     * @param from The address tokens were burned from.
     * @param amount The amount burned.
     * @param compliance The address of the calling compliance contract.
     */
    function moduleBurnAction(address from, uint256 amount, address compliance) external;
}
