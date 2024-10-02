// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {Test} from "forge-std/Test.sol";
import {MockClearinghouseInternals} from "./utils/MockClearinghouseInternals.sol";
import {IClearinghouse} from "synthetix-v3/markets/perps-market/contracts/interfaces/IClearinghouse.sol";

contract HashesTest is Test {
    MockClearinghouseInternals clearinghouse;

    function setUp() public {
        clearinghouse = new MockClearinghouseInternals();
    }

    // test typehashes

    function testOrderTypehash() public {
        bytes32 typeHash = keccak256(
            "Order(Condition[] conditions,Metadata metadata,Trade trade,Trader trader)Condition(address target,bytes4 selector,bytes data,bytes32 expected)Metadata(uint256 genesis,uint256 expiration,bytes32 trackingCode,address referrer)Trade(uint8 t,uint128 marketId,int128 size,uint256 price)Trader(uint256 nonce,uint128 accountId,address signer)"
        );
        assertEq(
            typeHash,
            0xc2b77ec0de83b288142b0d2b7f5eaf28f1e541d1f2b38d1f0b5560539bbaaaa9
        );
    }

    function testConditionTypehash() public {
        bytes32 typeHash = keccak256(
            "Condition(address target,bytes4 selector,bytes data,bytes32 expected)"
        );
        assertEq(
            typeHash,
            0xa78671e011562296314e133d36fbac3c60cba08a14cd761d9dfff1d94cf16b9d
        );
    }

    function testMetadataTypehash() public {
        bytes32 typeHash = keccak256(
            "Metadata(uint256 genesis,uint256 expiration,bytes32 trackingCode,address referrer)"
        );
        assertEq(
            typeHash,
            0x3fb26409690ba72074e6ebc22d4e2bca8f0f7c7706a831359b40cede8a69c0f3
        );
    }

    function testTradeTypehash() public {
        bytes32 typeHash = keccak256(
            "Trade(uint8 t,uint128 marketId,int128 size,uint256 price)"
        );
        assertEq(
            typeHash,
            0x433c9a5d4b303267c7393b9e107e94fa1583ee7cc66f0c4d412f96baf0314099
        );
    }

    function testTraderTypehash() public {
        bytes32 typeHash = keccak256(
            "Trader(uint256 nonce,uint128 accountId,address signer)"
        );
        assertEq(
            typeHash,
            0x2e2f44372bdffa5cfd0ba02a50d853ad42cd226efcb6d6898e058f0d88716f6a
        );
    }

    // test hashes

    function testOrderHash() public {
        IClearinghouse.Order memory order = createOrderSameAsScript();
        bytes32 orderHash = clearinghouse.hashOrder(order);

        assertEq(
            orderHash,
            0xf64a8ac24e4abe158aecf44ec657a19746bce40e2d75fcf8dfe3bb4ec7c75806
        );
    }

    function testConditionHash() public {
        /// @dev that selector is of "someFunction()"
        IClearinghouse.Condition memory condition = IClearinghouse.Condition({
            target: 0x1234567890AbcdEF1234567890aBcdef12345678,
            selector: 0x35b09a6e,
            data: "data",
            expected: "expected"
        });

        bytes32 conditionHash = clearinghouse.hashCondition(condition);

        assertEq(
            conditionHash,
            0xb6879152cfc81967a8cf8b9ef47b4735a5ed438ee43b0092ce66b362cd8a3d70
        );
    }

    function testMetadataHash() public {
        IClearinghouse.Metadata memory metadata = IClearinghouse.Metadata({
            genesis: 1,
            expiration: 2,
            trackingCode: "KWENTA",
            referrer: 0x1234567890AbcdEF1234567890aBcdef12345678
        });

        bytes32 metadataHash = clearinghouse.hashMetadata(metadata);

        assertEq(
            metadataHash,
            0x6609a75dcac514ae8a054c1e4e48c2ae0f429cf00c70f18debcead49624701c4
        );
    }

    function testTradeHash() public {
        IClearinghouse.Trade memory trade = IClearinghouse.Trade({
            t: IClearinghouse.Type.MARKET,
            marketId: 1,
            size: 1,
            price: 1
        });

        bytes32 tradeHash = clearinghouse.hashTrade(trade);

        assertEq(
            tradeHash,
            0x3de551bc2a7cc85cb9b4546a6e15e5f4e709c46393642ea914ba2282dc1e7a81
        );
    }

    function testTraderHash() public {
        IClearinghouse.Trader memory trader = IClearinghouse.Trader({
            nonce: 1,
            accountId: 1,
            signer: 0x96aA512665C429cE1454abe871098E4858c9c147
        });

        bytes32 traderHash = clearinghouse.hashTrader(trader);

        assertEq(
            traderHash,
            0x5a44a495ae61ebfb01c627426271dfc5951c4411a0912b0ef270f7086108f8d6
        );
    }

    // helpers

    function createOrderSameAsScript() public returns (IClearinghouse.Order memory) {
        IClearinghouse.Metadata memory metadata = IClearinghouse.Metadata({
            genesis: 1,
            expiration: 2,
            trackingCode: "KWENTA",
            referrer: 0x1234567890AbcdEF1234567890aBcdef12345678
        });
        IClearinghouse.Trader memory trader = IClearinghouse.Trader({
            nonce: 1,
            accountId: 1,
            signer: 0x96aA512665C429cE1454abe871098E4858c9c147
        });
        IClearinghouse.Trade memory trade = IClearinghouse.Trade({
            t: IClearinghouse.Type.MARKET,
            marketId: 1,
            size: 1,
            price: 1
        });
        IClearinghouse.Condition memory condition = IClearinghouse.Condition({
            target: 0x1234567890AbcdEF1234567890aBcdef12345678,
            selector: 0x35b09a6e,
            data: "data",
            expected: "expected"
        });

        IClearinghouse.Condition[]
            memory conditions = new IClearinghouse.Condition[](1);
        conditions[0] = condition;

        IClearinghouse.Order memory order = IClearinghouse.Order({
            metadata: metadata,
            trader: trader,
            trade: trade,
            conditions: conditions
        });

        return order;
    }
}
