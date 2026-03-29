// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../../interfaces/IComplianceModule.sol";
import "../../interfaces/IToken.sol";
import "../ModularCompliance.sol";

/**
 * @title MaxHoldersModule
 * @notice Limits the total number of unique token holders.
 * @dev Tracks holder count via transfer/mint/burn actions. A transfer that would
 * create a new holder beyond the limit is rejected.
 */
contract MaxHoldersModule is IComplianceModule, Ownable {
    /// @dev Mapping from compliance address to maximum holder count.
    mapping(address => uint256) private _maxHolders;

    /// @dev Mapping from compliance address to current holder count.
    mapping(address => uint256) private _holderCount;

    /// @dev Mapping from compliance => investor => whether they hold tokens.
    mapping(address => mapping(address => bool)) private _isHolder;

    /// @dev Emitted when the max holder limit is set.
    event MaxHoldersSet(address indexed compliance, uint256 maxHolders);

    /**
     * @dev Sets the maximum number of token holders.
     * @param compliance The compliance contract address.
     * @param max The maximum number of holders.
     */
    function setMaxHolders(address compliance, uint256 max) external onlyOwner {
        _maxHolders[compliance] = max;
        emit MaxHoldersSet(compliance, max);
    }

    /**
     * @dev Returns the max holders limit for a compliance contract.
     */
    function getMaxHolders(address compliance) external view returns (uint256) {
        return _maxHolders[compliance];
    }

    /**
     * @dev Returns the current holder count for a compliance contract.
     */
    function getHolderCount(address compliance) external view returns (uint256) {
        return _holderCount[compliance];
    }

    /// @inheritdoc IComplianceModule
    function moduleCheck(
        address /*from*/,
        address to,
        uint256 /*amount*/,
        address compliance
    ) external view override returns (bool) {
        // If the receiver is already a holder, no new holder is created
        if (_isHolder[compliance][to]) {
            return true;
        }

        // If max holders is 0, no limit is set
        if (_maxHolders[compliance] == 0) {
            return true;
        }

        // Check if adding a new holder would exceed the limit
        return _holderCount[compliance] < _maxHolders[compliance];
    }

    /// @inheritdoc IComplianceModule
    function moduleTransferAction(
        address from,
        address to,
        uint256 /*amount*/,
        address compliance
    ) external override {
        address tokenAddr = ModularCompliance(compliance).getTokenAddress();
        _updateHolderStatus(from, to, tokenAddr, compliance);
    }

    /// @inheritdoc IComplianceModule
    function moduleMintAction(address to, uint256 /*amount*/, address compliance) external override {
        if (!_isHolder[compliance][to]) {
            _isHolder[compliance][to] = true;
            _holderCount[compliance]++;
        }
    }

    /// @inheritdoc IComplianceModule
    function moduleBurnAction(address from, uint256 /*amount*/, address compliance) external override {
        address tokenAddr = ModularCompliance(compliance).getTokenAddress();
        // If the holder's balance is now 0, remove them from the holder count
        if (IToken(tokenAddr).balanceOf(from) == 0 && _isHolder[compliance][from]) {
            _isHolder[compliance][from] = false;
            _holderCount[compliance]--;
        }
    }

    /**
     * @dev Updates holder tracking after a transfer.
     */
    function _updateHolderStatus(address from, address to, address token, address compliance) internal {
        // Add new holder
        if (!_isHolder[compliance][to]) {
            _isHolder[compliance][to] = true;
            _holderCount[compliance]++;
        }

        // Remove sender if balance is now 0
        if (IToken(token).balanceOf(from) == 0 && _isHolder[compliance][from]) {
            _isHolder[compliance][from] = false;
            _holderCount[compliance]--;
        }
    }
}
