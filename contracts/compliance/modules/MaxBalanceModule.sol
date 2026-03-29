// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../../interfaces/IComplianceModule.sol";
import "../../interfaces/IToken.sol";
import "../ModularCompliance.sol";

/**
 * @title MaxBalanceModule
 * @notice Limits the maximum token balance any single investor can hold.
 * @dev Rejects transfers where the receiver's resulting balance would exceed the limit.
 */
contract MaxBalanceModule is IComplianceModule, Ownable {
    /// @dev Mapping from compliance address to max balance limit.
    mapping(address => uint256) private _maxBalance;

    /// @dev Emitted when the max balance is set.
    event MaxBalanceSet(address indexed compliance, uint256 maxBalance);

    /**
     * @dev Sets the maximum token balance per investor.
     * @param compliance The compliance contract address.
     * @param max The maximum balance.
     */
    function setMaxBalance(address compliance, uint256 max) external onlyOwner {
        _maxBalance[compliance] = max;
        emit MaxBalanceSet(compliance, max);
    }

    /**
     * @dev Returns the max balance limit for a compliance contract.
     */
    function getMaxBalance(address compliance) external view returns (uint256) {
        return _maxBalance[compliance];
    }

    /// @inheritdoc IComplianceModule
    function moduleCheck(
        address /*from*/,
        address to,
        uint256 amount,
        address compliance
    ) external view override returns (bool) {
        // If no limit is set, allow
        if (_maxBalance[compliance] == 0) {
            return true;
        }

        address tokenAddr = ModularCompliance(compliance).getTokenAddress();
        uint256 receiverBalance = IToken(tokenAddr).balanceOf(to);

        return (receiverBalance + amount) <= _maxBalance[compliance];
    }

    /// @inheritdoc IComplianceModule
    function moduleTransferAction(address, address, uint256, address) external override {}

    /// @inheritdoc IComplianceModule
    function moduleMintAction(address, uint256, address) external override {}

    /// @inheritdoc IComplianceModule
    function moduleBurnAction(address, uint256, address) external override {}
}
