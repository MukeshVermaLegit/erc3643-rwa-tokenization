// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IToken.sol";
import "../interfaces/IIdentityRegistry.sol";
import "../interfaces/ICompliance.sol";

/**
 * @title RealEstateToken
 * @notice ERC-3643 compliant security token for tokenized real estate assets.
 * @dev Extends ERC-20 with identity verification and compliance checks on every transfer.
 * Supports agent-based operations: minting, burning, freezing, forced transfers, and
 * address recovery for lost-key scenarios.
 */
contract RealEstateToken is ERC20, Ownable, IToken {
    /// @dev The identity registry used to verify investors.
    IIdentityRegistry private _identityRegistry;

    /// @dev The compliance contract that enforces transfer restrictions.
    ICompliance private _compliance;

    /// @dev Mapping of agent addresses.
    mapping(address => bool) private _agents;

    /// @dev Mapping of frozen token amounts per address.
    mapping(address => uint256) private _frozenTokens;

    /// @dev Whether the token is paused.
    bool private _paused;

    /// @dev Emitted on forced transfer.
    event ForcedTransfer(address indexed from, address indexed to, uint256 amount, address indexed agent);

    /// @dev Modifier restricting access to agents.
    modifier onlyAgent() {
        require(_agents[msg.sender], "RealEstateToken: caller is not an agent");
        _;
    }

    /// @dev Modifier ensuring the token is not paused.
    modifier whenNotPaused() {
        require(!_paused, "RealEstateToken: token is paused");
        _;
    }

    /// @dev Modifier ensuring the token is paused.
    modifier whenPaused() {
        require(_paused, "RealEstateToken: token is not paused");
        _;
    }

    /**
     * @dev Initializes the token with its name, symbol, and linked contracts.
     * @param name_ The token name.
     * @param symbol_ The token symbol.
     * @param identityRegistry_ The identity registry address.
     * @param compliance_ The compliance contract address.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        address identityRegistry_,
        address compliance_
    ) ERC20(name_, symbol_) {
        require(identityRegistry_ != address(0), "RealEstateToken: zero identity registry");
        require(compliance_ != address(0), "RealEstateToken: zero compliance");

        _identityRegistry = IIdentityRegistry(identityRegistry_);
        _compliance = ICompliance(compliance_);
    }

    // ========================= Agent Operations =========================

    /// @inheritdoc IToken
    function mint(address to, uint256 amount) external override onlyAgent whenNotPaused {
        require(_identityRegistry.isVerified(to), "RealEstateToken: recipient is not verified");
        _mint(to, amount);
        _compliance.created(to, amount);
    }

    /// @inheritdoc IToken
    function burn(address from, uint256 amount) external override onlyAgent whenNotPaused {
        _burn(from, amount);
        _compliance.destroyed(from, amount);
    }

    /// @inheritdoc IToken
    function forcedTransfer(
        address from,
        address to,
        uint256 amount
    ) external override onlyAgent whenNotPaused {
        require(_identityRegistry.isVerified(to), "RealEstateToken: recipient is not verified");

        // Reduce frozen tokens if needed
        uint256 freeBalance = balanceOf(from) - _frozenTokens[from];
        if (amount > freeBalance) {
            uint256 tokensToUnfreeze = amount - freeBalance;
            _frozenTokens[from] -= tokensToUnfreeze;
            emit TokensUnfrozen(from, tokensToUnfreeze);
        }

        _transfer(from, to, amount);
        _compliance.transferred(from, to, amount);

        emit ForcedTransfer(from, to, amount, msg.sender);
    }

    /// @inheritdoc IToken
    function freezePartialTokens(address userAddress, uint256 amount) external override onlyAgent {
        require(
            amount + _frozenTokens[userAddress] <= balanceOf(userAddress),
            "RealEstateToken: amount exceeds balance"
        );
        _frozenTokens[userAddress] += amount;
        emit TokensFrozen(userAddress, amount);
    }

    /// @inheritdoc IToken
    function unfreezePartialTokens(address userAddress, uint256 amount) external override onlyAgent {
        require(amount <= _frozenTokens[userAddress], "RealEstateToken: amount exceeds frozen tokens");
        _frozenTokens[userAddress] -= amount;
        emit TokensUnfrozen(userAddress, amount);
    }

    /// @inheritdoc IToken
    function recoveryAddress(
        address lostWallet,
        address newWallet,
        address investorIdentity
    ) external override onlyAgent whenNotPaused {
        require(_identityRegistry.isVerified(newWallet), "RealEstateToken: new wallet is not verified");

        uint256 balance = balanceOf(lostWallet);
        uint256 frozen = _frozenTokens[lostWallet];

        // Transfer all tokens from lost wallet to new wallet
        _transfer(lostWallet, newWallet, balance);
        _compliance.transferred(lostWallet, newWallet, balance);

        // Move frozen tokens mapping
        if (frozen > 0) {
            _frozenTokens[lostWallet] = 0;
            _frozenTokens[newWallet] += frozen;
        }

        emit RecoverySuccess(lostWallet, newWallet, investorIdentity);
    }

    /// @inheritdoc IToken
    function pause() external override onlyAgent whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /// @inheritdoc IToken
    function unpause() external override onlyAgent whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    // ========================= Owner Operations =========================

    /// @inheritdoc IToken
    function setIdentityRegistry(address identityRegistry_) external override onlyOwner {
        require(identityRegistry_ != address(0), "RealEstateToken: zero address");
        _identityRegistry = IIdentityRegistry(identityRegistry_);
        emit IdentityRegistrySet(identityRegistry_);
    }

    /// @inheritdoc IToken
    function setCompliance(address compliance_) external override onlyOwner {
        require(compliance_ != address(0), "RealEstateToken: zero address");
        _compliance = ICompliance(compliance_);
        emit ComplianceSet(compliance_);
    }

    /// @inheritdoc IToken
    function addAgent(address agent) external override onlyOwner {
        require(agent != address(0), "RealEstateToken: zero address");
        _agents[agent] = true;
        emit AgentAdded(agent);
    }

    /// @inheritdoc IToken
    function removeAgent(address agent) external override onlyOwner {
        _agents[agent] = false;
        emit AgentRemoved(agent);
    }

    // ========================= View Functions =========================

    /// @inheritdoc IToken
    function getFrozenTokens(address userAddress) external view override returns (uint256) {
        return _frozenTokens[userAddress];
    }

    /// @inheritdoc IToken
    function isAgent(address agent) external view override returns (bool) {
        return _agents[agent];
    }

    /// @inheritdoc IToken
    function identityRegistry() external view override returns (IIdentityRegistry) {
        return _identityRegistry;
    }

    /// @inheritdoc IToken
    function compliance() external view override returns (ICompliance) {
        return _compliance;
    }

    /**
     * @dev Returns whether the token is currently paused.
     */
    function paused() external view returns (bool) {
        return _paused;
    }

    // ========================= Transfer Override =========================

    /**
     * @dev Overrides ERC-20 transfer to enforce identity verification and compliance.
     * Checks that the sender has sufficient unfrozen balance, the receiver is verified,
     * and all compliance modules approve the transfer.
     */
    function transfer(address to, uint256 amount) public override returns (bool) {
        require(!_paused, "RealEstateToken: token is paused");
        require(
            balanceOf(msg.sender) - _frozenTokens[msg.sender] >= amount,
            "RealEstateToken: insufficient unfrozen balance"
        );
        require(_identityRegistry.isVerified(to), "RealEstateToken: recipient is not verified");
        require(_compliance.canTransfer(msg.sender, to, amount), "RealEstateToken: transfer not compliant");

        _transfer(msg.sender, to, amount);
        _compliance.transferred(msg.sender, to, amount);

        return true;
    }

    /**
     * @dev Overrides ERC-20 transferFrom to enforce identity verification and compliance.
     */
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        require(!_paused, "RealEstateToken: token is paused");
        require(
            balanceOf(from) - _frozenTokens[from] >= amount,
            "RealEstateToken: insufficient unfrozen balance"
        );
        require(_identityRegistry.isVerified(to), "RealEstateToken: recipient is not verified");
        require(_compliance.canTransfer(from, to, amount), "RealEstateToken: transfer not compliant");

        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        _compliance.transferred(from, to, amount);

        return true;
    }

    /**
     * @dev Returns the number of decimals (0 for real estate tokens representing whole units).
     */
    function decimals() public pure override returns (uint8) {
        return 0;
    }

    /**
     * @notice Returns the balance of an address. Required by IToken's dependency via
     * compliance modules that call IToken(token).balanceOf().
     * @dev This is inherited from ERC20 but we mention it here for clarity.
     */
    function balanceOf(address account) public view override(ERC20, IToken) returns (uint256) {
        return super.balanceOf(account);
    }
}
