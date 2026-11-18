// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Minimal interface of the official Agent ID registry
///         (SPACE ID Agent ID, ERC-721, non-transferable) on BNB Chain.
interface IAgentIdRegistry {
    function balanceOf(address owner) external view returns (uint256);
}

/// @title AgentTipJar
/// @notice A tip jar that only Agent ID (.ai) holders can use.
///         Both the tipper and the receiver must hold an Agent ID in the
///         official registry — Agent ID is the access control, the identity
///         layer and the anti-spam gate of the product, not a decoration.
/// @dev    Non-custodial: tips are forwarded to the receiver in the same
///         transaction. The contract never holds funds, has no owner, no
///         admin keys, no pause and no withdrawal function.
contract AgentTipJar {
    /// @notice Official Agent ID registry on BNB Chain:
    ///         0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F
    IAgentIdRegistry public immutable registry;

    uint256 public totalTips;
    uint256 public totalVolume;
    /// @notice Distinct Agent ID addresses that have interacted (sent,
    ///         received or set a motto). This is the ecosystem metric the
    ///         product is built to grow.
    uint256 public uniqueAgents;

    mapping(address => bool) public hasInteracted;
    mapping(address => uint256) public tipsSentCount;
    mapping(address => uint256) public tipsSentTotal;
    mapping(address => uint256) public tipsReceivedCount;
    mapping(address => uint256) public tipsReceivedTotal;
    mapping(address => string) public mottoOf;

    event Tipped(address indexed from, address indexed to, uint256 amount);
    event MottoSet(address indexed user, string motto);

    error NotAgent(address who);
    error ZeroAmount();
    error ZeroAddress();
    error SelfTip();
    error TransferFailed();
    error MottoTooLong();

    constructor(address registry_) {
        require(registry_ != address(0), "registry=0");
        registry = IAgentIdRegistry(registry_);
    }

    /// @notice True when `who` holds at least one Agent ID.
    function isAgent(address who) public view returns (bool) {
        return registry.balanceOf(who) > 0;
    }

    function _requireAgent(address who) internal view {
        if (!isAgent(who)) revert NotAgent(who);
    }

    function _touch(address who) internal {
        if (!hasInteracted[who]) {
            hasInteracted[who] = true;
            uniqueAgents++;
        }
    }

    /// @notice Send a BNB tip to another Agent ID holder.
    /// @dev    Checks-effects-interactions: all accounting is written before
    ///         the value transfer; if the transfer fails the whole
    ///         transaction reverts and the tipper keeps the funds.
    function tip(address to) external payable {
        _requireAgent(msg.sender);
        if (msg.value == 0) revert ZeroAmount();
        if (to == address(0)) revert ZeroAddress();
        if (to == msg.sender) revert SelfTip();
        _requireAgent(to);

        _touch(msg.sender);
        _touch(to);
        tipsSentCount[msg.sender] += 1;
        tipsSentTotal[msg.sender] += msg.value;
        tipsReceivedCount[to] += 1;
        tipsReceivedTotal[to] += msg.value;
        totalTips += 1;
        totalVolume += msg.value;

        emit Tipped(msg.sender, to, msg.value);

        (bool ok, ) = to.call{value: msg.value}("");
        if (!ok) revert TransferFailed();
    }

    /// @notice Set a short public motto shown next to your Agent ID address
    ///         on the leaderboard. Agent ID holders only.
    function setMotto(string calldata motto) external {
        _requireAgent(msg.sender);
        if (bytes(motto).length > 140) revert MottoTooLong();
        _touch(msg.sender);
        mottoOf[msg.sender] = motto;
        emit MottoSet(msg.sender, motto);
    }

    /// @notice Aggregated stats for one address.
    function statsOf(address who)
        external
        view
        returns (
            uint256 sentCount,
            uint256 sentTotal,
            uint256 receivedCount,
            uint256 receivedTotal,
            bool interacted
        )
    {
        return (
            tipsSentCount[who],
            tipsSentTotal[who],
            tipsReceivedCount[who],
            tipsReceivedTotal[who],
            hasInteracted[who]
        );
    }
}
