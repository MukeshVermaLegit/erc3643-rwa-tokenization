// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IComplianceModule.sol";

/**
 * @title ICompliance
 * @dev Interface for the modular compliance contract that aggregates
 * multiple compliance modules to enforce transfer restrictions.
 */
interface ICompliance {
    /// @dev Emitted when a compliance module is added.
    event ModuleAdded(address indexed module);

    /// @dev Emitted when a compliance module is removed.
    event ModuleRemoved(address indexed module);

    /// @dev Emitted when the token is bound to this compliance contract.
    event TokenBound(address indexed token);

    /**
     * @dev Adds a compliance module.
     * @param module The module contract address.
     */
    function addModule(address module) external;

    /**
     * @dev Removes a compliance module.
     * @param module The module contract address.
     */
    function removeModule(address module) external;

    /**
     * @dev Checks whether a transfer is compliant across all modules.
     * @param from The sender address.
     * @param to The receiver address.
     * @param amount The transfer amount.
     * @return True if the transfer passes all module checks.
     */
    function canTransfer(address from, address to, uint256 amount) external view returns (bool);

    /**
     * @dev Called after a compliant transfer to update all module states.
     * @param from The sender address.
     * @param to The receiver address.
     * @param amount The amount transferred.
     */
    function transferred(address from, address to, uint256 amount) external;

    /**
     * @dev Called after a mint to update all module states.
     * @param to The receiver address.
     * @param amount The amount minted.
     */
    function created(address to, uint256 amount) external;

    /**
     * @dev Called after a burn to update all module states.
     * @param from The address tokens were burned from.
     * @param amount The amount burned.
     */
    function destroyed(address from, uint256 amount) external;

    /**
     * @dev Binds a token to this compliance contract.
     * @param token The token address.
     */
    function bindToken(address token) external;

    /**
     * @dev Returns the list of compliance modules.
     * @return Array of module addresses.
     */
    function getModules() external view returns (address[] memory);
}
