// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ICompliance.sol";
import "../interfaces/IComplianceModule.sol";

/**
 * @title ModularCompliance
 * @notice Aggregates multiple compliance modules to enforce transfer restrictions.
 * @dev Each transfer is checked against all active modules. A transfer is only
 * allowed if every module approves it. After a successful transfer, each module
 * is notified so it can update its internal state.
 */
contract ModularCompliance is ICompliance, Ownable {
    /// @dev Array of active compliance modules.
    address[] private _modules;

    /// @dev Quick lookup for module membership.
    mapping(address => bool) private _isModule;

    /// @dev The token bound to this compliance contract.
    address private _tokenAddress;

    /// @dev Modifier restricting calls to the bound token.
    modifier onlyToken() {
        require(msg.sender == _tokenAddress, "ModularCompliance: caller is not the token");
        _;
    }

    /// @inheritdoc ICompliance
    function bindToken(address token) external override onlyOwner {
        require(token != address(0), "ModularCompliance: zero address");
        _tokenAddress = token;
        emit TokenBound(token);
    }

    /// @inheritdoc ICompliance
    function addModule(address module) external override onlyOwner {
        require(module != address(0), "ModularCompliance: zero address");
        require(!_isModule[module], "ModularCompliance: module already added");

        _modules.push(module);
        _isModule[module] = true;

        emit ModuleAdded(module);
    }

    /// @inheritdoc ICompliance
    function removeModule(address module) external override onlyOwner {
        require(_isModule[module], "ModularCompliance: module not found");

        for (uint256 i = 0; i < _modules.length; i++) {
            if (_modules[i] == module) {
                _modules[i] = _modules[_modules.length - 1];
                _modules.pop();
                break;
            }
        }

        _isModule[module] = false;

        emit ModuleRemoved(module);
    }

    /// @inheritdoc ICompliance
    function canTransfer(address from, address to, uint256 amount) external view override returns (bool) {
        for (uint256 i = 0; i < _modules.length; i++) {
            if (!IComplianceModule(_modules[i]).moduleCheck(from, to, amount, address(this))) {
                return false;
            }
        }
        return true;
    }

    /// @inheritdoc ICompliance
    function transferred(address from, address to, uint256 amount) external override onlyToken {
        for (uint256 i = 0; i < _modules.length; i++) {
            IComplianceModule(_modules[i]).moduleTransferAction(from, to, amount, address(this));
        }
    }

    /// @inheritdoc ICompliance
    function created(address to, uint256 amount) external override onlyToken {
        for (uint256 i = 0; i < _modules.length; i++) {
            IComplianceModule(_modules[i]).moduleMintAction(to, amount, address(this));
        }
    }

    /// @inheritdoc ICompliance
    function destroyed(address from, uint256 amount) external override onlyToken {
        for (uint256 i = 0; i < _modules.length; i++) {
            IComplianceModule(_modules[i]).moduleBurnAction(from, amount, address(this));
        }
    }

    /// @inheritdoc ICompliance
    function getModules() external view override returns (address[] memory) {
        return _modules;
    }

    /**
     * @dev Returns the bound token address.
     */
    function getTokenAddress() external view returns (address) {
        return _tokenAddress;
    }
}
