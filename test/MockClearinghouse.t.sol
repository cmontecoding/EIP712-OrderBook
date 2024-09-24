// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {MockClearinghouse} from "../src/MockClearinghouse.sol";
import {IClearinghouse} from "synthetix-v3/markets/perps-market/contracts/interfaces/IClearinghouse.sol";

contract MockClearingHouseTest is Test {

    MockClearinghouse clearingHouse;
    uint256 owner1PrivateKey = 123;
    address owner1 = vm.addr(owner1PrivateKey);
    uint256 owner2PrivateKey = 456;
    address owner2 = vm.addr(owner2PrivateKey);

    function setUp() public {
        clearingHouse = new MockClearinghouse();
    }

    function testSettle() public {
        MockClearinghouse.Request memory request = createRequest();
        MockClearinghouse.Response memory response = clearingHouse.settle(request);
        assertTrue(response.success);
        assertEq(response.data, "Settlement successful");
    }

    function testCanSettle() public {
        MockClearinghouse.Request memory request = createRequest();
        MockClearinghouse.Response memory response = clearingHouse.canSettle(request);
        assertTrue(response.success);
        assertEq(response.data, "Settlement successful");
    }

    function testHash() public {
        MockClearinghouse.Order memory order = createRequest().orders[0];
        bytes32 hash = clearingHouse.hash(order);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(owner1PrivateKey, hash);

        address signer = ecrecover(hash, v, r, s);
        assertEq(owner1, signer);

        // i know this doesnt actually test the hash function
        // still thinking about how to test, prob only offchain
    }

    // helpers

    function createRequest() public returns(MockClearinghouse.Request memory) {        
        IClearinghouse.Order memory order = createOrder();
        bytes32 hash = clearingHouse.hash(order);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(owner1PrivateKey, hash);
        // Pack the ECDSA signature
        bytes memory packedSignature = abi.encodePacked(r, s, v);

        IClearinghouse.Order[] memory orders = new IClearinghouse.Order[](2);
        orders[0] = order;
        orders[1] = order;
        bytes[] memory signatures = new bytes[](2);
        signatures[0] = packedSignature;
        signatures[1] = packedSignature;

        return IClearinghouse.Request({
            orders: orders,
            signatures: signatures
        });
    }

    function createOrder() public returns(MockClearinghouse.Order memory) {
        IClearinghouse.Metadata memory metadata = IClearinghouse.Metadata({
            genesis: 0,
            expiration: 0,
            trackingCode: "KWENTA",
            referrer: address(0)
        });

        IClearinghouse.Trader memory trader = IClearinghouse.Trader({
            accountId: 1,
            nonce: 0,
            signer: owner1
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

        return order;
    }

}