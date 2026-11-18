// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AgentTipJar} from "../src/AgentTipJar.sol";

contract MockRegistry {
    mapping(address => uint256) public balanceOf;
    function set(address who, uint256 n) external { balanceOf[who] = n; }
}

/// Minimal hand-rolled test harness (no forge-std dependency).
contract AgentTipJarTest {
    MockRegistry reg;
    AgentTipJar jar;
    address alice = address(0xA11CE);
    address bob = address(0xB0B);
    address carol = address(0xCA401);

    function setUp() public {
        reg = new MockRegistry();
        jar = new AgentTipJar(address(reg));
        reg.set(alice, 1);
        reg.set(bob, 1);
        // carol holds no Agent ID
    }

    receive() external payable {}

    function _eq(uint256 a, uint256 b, string memory m) internal pure {
        require(a == b, m);
    }
    function _ok(bool c, string memory m) internal pure { require(c, m); }

    function testTipHappyPath() public {
        uint256 before_ = bob.balance;
        // this contract acts as alice via prank-free design: use low-level call from alice using vm cheat is unavailable;
        // instead the test contract itself is the tipper, so give it an Agent ID.
        reg.set(address(this), 1);
        jar.tip{value: 0.1 ether}(bob);
        _eq(jar.totalTips(), 1, "totalTips");
        _eq(jar.totalVolume(), 0.1 ether, "totalVolume");
        _eq(jar.tipsReceivedTotal(bob), 0.1 ether, "bob received");
        _eq(bob.balance - before_, 0.1 ether, "bob balance delta");
        _eq(jar.uniqueAgents(), 2, "uniqueAgents counts tipper+receiver");
    }

    function testNonHolderCannotTip() public {
        // test contract has no Agent ID in this test's fresh state? setUp grants none to this; use carol path via direct call simulation:
        // We emulate by revoking: reg default for address(this) is 0 here until set in other tests (each test re-runs setUp).
        bool reverted;
        try jar.tip{value: 0.01 ether}(bob) { } catch { reverted = true; }
        _ok(reverted, "non-holder tip must revert");
    }

    function testCannotTipNonHolder() public {
        reg.set(address(this), 1);
        bool reverted;
        try jar.tip{value: 0.01 ether}(carol) { } catch { reverted = true; }
        _ok(reverted, "tip to non-holder must revert");
    }

    function testMottoGateAndUnique() public {
        reg.set(address(this), 1);
        jar.setMotto("bnbmaxi on chain");
        _eq(jar.uniqueAgents(), 1, "motto counts as interaction");
        bool reverted;
        try jar.setMotto(string(new bytes(141))) { } catch { reverted = true; }
        // 141 zero bytes -> length check triggers only if >140; string of 141 NUL bytes has length 141
        _ok(reverted, "overlong motto must revert");
    }
}
