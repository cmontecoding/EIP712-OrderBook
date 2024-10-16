// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {MockClearinghouse} from "../src/MockClearinghouse.sol";
import {IClearinghouse} from "../src/interfaces/IClearinghouse.sol";

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
        MockClearinghouse.Request memory request = createBasicRequestOppositeSizes(
            owner1PrivateKey
        );
        MockClearinghouse.Response memory response = clearingHouse.canSettle(
            request
        );
        assertTrue(response.success);
        assertEq(response.data, "Settlement successful");
    }

    function testCanSettleSuccess() public {
        MockClearinghouse.Request memory request = createBasicRequestOppositeSizes(
            owner1PrivateKey
        );
        MockClearinghouse.Response memory response = clearingHouse.canSettle(
            request
        );
        assertTrue(response.success);
        assertEq(response.data, "Settlement successful");
    }

    function testCanSettleInvalidTradePairSizeBothLong() public {
        MockClearinghouse.Request memory request = createBasicRequest(
            owner1PrivateKey
        );
        MockClearinghouse.Response memory response = clearingHouse.canSettle(
            request
        );
        assertFalse(response.success);
        assertEq(response.data, "Invalid trade pair: size");
    }

    function testCanSettleInvalidTradePairSizeBothShort() public {
        MockClearinghouse.Request memory request = createBasicRequestBothShort(
            owner1PrivateKey
        );
        MockClearinghouse.Response memory response = clearingHouse.canSettle(
            request
        );
        assertFalse(response.success);
        assertEq(response.data, "Invalid trade pair: size");
    }

    function testCanSettleTooManyOrders() public {
        MockClearinghouse.Request memory request = createBasicRequest(
            owner1PrivateKey
        );
        request.orders = new IClearinghouse.Order[](3);
        request.signatures = new bytes[](3);
        MockClearinghouse.Response memory response = clearingHouse.canSettle(
            request
        );
        assertFalse(response.success);
        assertEq(response.data, "Too many orders");
    }

    function testCanSettleNoOrders() public {
        MockClearinghouse.Request memory request = createBasicRequest(
            owner1PrivateKey
        );
        request.orders = new IClearinghouse.Order[](0);
        request.signatures = new bytes[](0);
        MockClearinghouse.Response memory response = clearingHouse.canSettle(
            request
        );
        assertFalse(response.success);
        assertEq(response.data, "No orders");
    }

    function testCanSettleNotEnoughOrders() public {
        MockClearinghouse.Request memory request = createBasicRequest(
            owner1PrivateKey
        );
        request.orders = new IClearinghouse.Order[](1);
        request.signatures = new bytes[](1);
        MockClearinghouse.Response memory response = clearingHouse.canSettle(
            request
        );
        assertFalse(response.success);
        assertEq(response.data, "Not enough orders");
    }

    function testCanSettleInvalidNumberOfSignatures() public {
        MockClearinghouse.Request memory request = createBasicRequest(
            owner1PrivateKey
        );
        request.orders = new IClearinghouse.Order[](2);
        request.signatures = new bytes[](1);
        MockClearinghouse.Response memory response = clearingHouse.canSettle(
            request
        );
        assertFalse(response.success);
        assertEq(response.data, "Invalid number of signatures");
    }

    function testFuzzCanSettleInvalidNumberOfSignatures(uint8 amount) public {
        vm.assume(amount != 2);
        MockClearinghouse.Request memory request = createBasicRequest(
            owner1PrivateKey
        );
        request.orders = new IClearinghouse.Order[](2);
        request.signatures = new bytes[](amount);
        MockClearinghouse.Response memory response = clearingHouse.canSettle(
            request
        );
        assertFalse(response.success);
        assertEq(response.data, "Invalid number of signatures");
    }

    function testCanSettleInvalidSignature() public {
        MockClearinghouse.Request memory request = createBasicRequest(
            owner1PrivateKey
        );
        request.signatures[0] = abi.encodePacked(
            bytes32(0),
            bytes32(0),
            uint8(0)
        );
        MockClearinghouse.Response memory response = clearingHouse.canSettle(
            request
        );
        assertFalse(response.success);
        assertEq(response.data, "Invalid signature for order");
    }

    function testCanSettleInvalidSignature2() public {
        MockClearinghouse.Request memory request = createBasicRequest(
            owner1PrivateKey
        );
        request.signatures[1] = abi.encodePacked(
            bytes32(0),
            bytes32(0),
            uint8(0)
        );
        MockClearinghouse.Response memory response = clearingHouse.canSettle(
            request
        );
        assertFalse(response.success);
        assertEq(response.data, "Invalid signature for order");
    }

    function testSigner() public {
        MockClearinghouse.Order memory order = createBasicOrder();
        bytes32 hash = clearingHouse.hash(order);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(owner1PrivateKey, hash);

        address signer = ecrecover(hash, v, r, s);
        assertEq(owner1, signer);
    }

    // helpers

    function createBasicRequest(
        uint256 privateKey
    ) public returns (MockClearinghouse.Request memory) {
        IClearinghouse.Order memory order = createBasicOrder();
        bytes32 hash = clearingHouse.hash(order);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, hash);
        // Pack the ECDSA signature
        bytes memory packedSignature = abi.encodePacked(r, s, v);

        IClearinghouse.Order[] memory orders = new IClearinghouse.Order[](2);
        orders[0] = order;
        orders[1] = order;
        bytes[] memory signatures = new bytes[](2);
        signatures[0] = packedSignature;
        signatures[1] = packedSignature;

        return IClearinghouse.Request({orders: orders, signatures: signatures});
    }

    function createBasicRequestOppositeSizes(
        uint256 privateKey
    ) public returns (MockClearinghouse.Request memory) {
        IClearinghouse.Order memory order = createBasicOrder();
        bytes32 hash = clearingHouse.hash(order);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, hash);
        // Pack the ECDSA signature
        bytes memory packedSignature = abi.encodePacked(r, s, v);

        IClearinghouse.Order memory order2 = createBasicOrderNegativeSize();
        hash = clearingHouse.hash(order2);
        (v, r, s) = vm.sign(privateKey, hash);
        // Pack the ECDSA signature
        bytes memory packedSignature2 = abi.encodePacked(r, s, v);

        IClearinghouse.Order[] memory orders = new IClearinghouse.Order[](2);
        orders[0] = order;
        orders[1] = order2;
        bytes[] memory signatures = new bytes[](2);
        signatures[0] = packedSignature;
        signatures[1] = packedSignature2;

        return IClearinghouse.Request({orders: orders, signatures: signatures});
    }

    function createBasicRequestBothShort(
        uint256 privateKey
    ) public returns (MockClearinghouse.Request memory) {
        IClearinghouse.Order memory order = createBasicOrderNegativeSize();
        bytes32 hash = clearingHouse.hash(order);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, hash);
        // Pack the ECDSA signature
        bytes memory packedSignature = abi.encodePacked(r, s, v);

        IClearinghouse.Order memory order2 = createBasicOrderNegativeSize();
        hash = clearingHouse.hash(order2);
        (v, r, s) = vm.sign(privateKey, hash);
        // Pack the ECDSA signature
        bytes memory packedSignature2 = abi.encodePacked(r, s, v);

        IClearinghouse.Order[] memory orders = new IClearinghouse.Order[](2);
        orders[0] = order;
        orders[1] = order2;
        bytes[] memory signatures = new bytes[](2);
        signatures[0] = packedSignature;
        signatures[1] = packedSignature2;

        return IClearinghouse.Request({orders: orders, signatures: signatures});
    }

    function createBasicOrder() public returns (MockClearinghouse.Order memory) {
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

    function createBasicOrderNegativeSize() public returns (MockClearinghouse.Order memory) {
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
            size: -1,
            price: 1
        });

        IClearinghouse.Condition memory condition = IClearinghouse.Condition({
            target: address(0),
            selector: "",
            data: "",
            expected: ""
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
