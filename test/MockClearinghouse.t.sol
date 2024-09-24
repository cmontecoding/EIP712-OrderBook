// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {MockClearinghouse} from "../src/MockClearinghouse.sol";
import {IClearinghouse} from "synthetix-v3/markets/perps-market/contracts/interfaces/IClearinghouse.sol";

contract MockClearingHouseTest is Test {

    MockClearinghouse clearingHouse;

    function setUp() public {
        clearingHouse = new MockClearinghouse();
    }

    function testSettle() public {
        MockClearinghouse.Request memory request = createRequest();
        MockClearinghouse.Response memory response = clearingHouse.settle(request);
        assertTrue(response.success);
        assertEq(response.data, "Settlement successful");
    }

    // helpers

    function createRequest() public returns(MockClearinghouse.Request memory) {
        IClearinghouse.Metadata memory metadata = IClearinghouse.Metadata({
            genesis: 0,
            expiration: 0,
            trackingCode: "KWENTA",
            referrer: address(0)
        });

        IClearinghouse.Trader memory trader = IClearinghouse.Trader({
            accountId: 1,
            nonce: 0,
            signer: address(this)
        });

        IClearinghouse.Trade memory trade = IClearinghouse.Trade({
            t: IClearinghouse.Type.LIMIT,
            marketId: 1,
            size: 1,
            price: 1
        });

        IClearinghouse.Condition memory condition = IClearinghouse.Condition({
            target: address(0),
            selector: "",
            data: "",
            expected: ""
        });

        IClearinghouse.Condition[] memory conditions = new IClearinghouse.Condition[](1);
        conditions[0] = condition;

        IClearinghouse.Order memory order = IClearinghouse.Order({
            metadata: metadata,
            trader: trader,
            trade: trade,
            conditions: conditions
        });

        IClearinghouse.Order[] memory orders = new IClearinghouse.Order[](1);
        orders[0] = order;
        bytes[] memory signatures = new bytes[](1);

        return IClearinghouse.Request({
            orders: orders,
            signatures: signatures
        });
    }

}