// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {Test} from "forge-std/Test.sol";
import {MockClearinghouseInternals} from "./utils/MockClearinghouseInternals.sol";
import {IClearinghouse} from "synthetix-v3/markets/perps-market/contracts/interfaces/IClearinghouse.sol";

contract OrderHashTest is Test {
    // OrderSignature orderSignature;
    // Account account0;
    MockClearinghouseInternals clearinghouse;

    function setUp() public {
        // orderSignature = new OrderSignature();
        // account0 = makeAccount("a");
        clearinghouse = new MockClearinghouseInternals();
    }

    function testTraderHash() public {
        IClearinghouse.Trader memory trader = IClearinghouse.Trader({nonce: 0, accountId: 0, signer: address(0)});

        bytes32 traderHash = clearinghouse.hashTrader(trader);

        assertEq(traderHash, 0x32adae1fdb72af2c28b8f2ae2cec99d73c162e75615af1f51f7b6f73d8294ac2);
    }

    function testTraderTypehash() public {
        bytes32 typeHash = keccak256("Trader(uint256 nonce,uint128 accountId,address signer)");
        assertEq(typeHash, 0x2e2f44372bdffa5cfd0ba02a50d853ad42cd226efcb6d6898e058f0d88716f6a);
    }

    //IClearinghouse.Trader memory trader = IClearinghouse.Trader({t: IClearinghouse.Type.MARKET, marketId: 0, size: 0, price: 0});

    // function test_itemHash() public {
    //     IFloodPlain.Item memory item = IFloodPlain.Item({token: address(0), amount: 0});

    //     bytes32 itemHash = orderSignature.hash(item);

    //     assertEq(itemHash, 0xcb02862e625f0c341a0dbe9a7495af6982102db3456f3ded5efe8fabd6689904);
    // }

    // function test_hookHash() public {
    //     IFloodPlain.Hook memory hook = IFloodPlain.Hook({target: address(0), data: hex""});

    //     bytes32 hookHash = orderSignature.hash(hook);

    //     assertEq(hookHash, 0xd3b9e9f5bd8a8b242f8319849becb42f8ce6c5c6e9d24f9539f428e8d7e666bd);
    // }

    // function test_orderHash() public {
    //     IFloodPlain.Item memory item = IFloodPlain.Item({token: address(0), amount: 0});
    //     IFloodPlain.Hook memory hook = IFloodPlain.Hook({target: address(0), data: hex""});

    //     IFloodPlain.Item[] memory offer = new IFloodPlain.Item[](3);
    //     offer[0] = item;
    //     offer[1] = item;
    //     offer[2] = item;

    //     IFloodPlain.Hook[] memory preHooks = new IFloodPlain.Hook[](1);
    //     preHooks[0] = hook;

    //     IFloodPlain.Hook[] memory postHooks = new IFloodPlain.Hook[](2);
    //     postHooks[0] = hook;
    //     postHooks[1] = hook;

    //     IFloodPlain.Order memory order = IFloodPlain.Order({
    //         offerer: address(0),
    //         zone: address(0),
    //         recipient: address(0),
    //         offer: offer,
    //         consideration: item,
    //         deadline: 0,
    //         nonce: 0,
    //         preHooks: preHooks,
    //         postHooks: postHooks
    //     });

    //     bytes32 orderHash = orderSignature.hash(order);

    //     assertEq(orderHash, 0xece53f158244592f601148c3a00ab85c63d4bf4ce04da8375e216dfc40694b32);
    // }

    // function test_permitHash() public {
    //     IFloodPlain.Item memory item = IFloodPlain.Item({token: address(0), amount: 0});
    //     IFloodPlain.Hook memory hook = IFloodPlain.Hook({target: address(0), data: hex""});

    //     IFloodPlain.Item[] memory offer = new IFloodPlain.Item[](3);
    //     offer[0] = item;
    //     offer[1] = item;
    //     offer[2] = item;

    //     IFloodPlain.Hook[] memory preHooks = new IFloodPlain.Hook[](1);
    //     preHooks[0] = hook;

    //     IFloodPlain.Hook[] memory postHooks = new IFloodPlain.Hook[](2);
    //     postHooks[0] = hook;
    //     postHooks[1] = hook;

    //     IFloodPlain.Order memory order = IFloodPlain.Order({
    //         offerer: address(0),
    //         zone: address(0),
    //         recipient: address(0),
    //         offer: offer,
    //         consideration: item,
    //         deadline: 0,
    //         nonce: 0,
    //         preHooks: preHooks,
    //         postHooks: postHooks
    //     });

    //     bytes32 permitHash = orderSignature.hashAsWitness(order, address(0x420));

    //     assertEq(permitHash, 0x8aea3ef4ab58e3cfd67a39b948421def10f4424ee4be0b8c1be0bb6c05bb022a);
    // }

    // // `test_permitHash` checks the whole PermitBatchWitnessTransferFrom struct typehash, but
    // // what is passed to the Permit 2 is only the partial type string. Below tests the partial
    // // typestring against the whole typestring, which was implicitly checked to be true in the
    // // previous `test_permitHash` test.
    // function test_witnessTypeString() public {
    //     bytes32 permitTypeHash = keccak256(
    //         bytes(
    //             string.concat(
    //                 PermitHash._PERMIT_BATCH_WITNESS_TRANSFER_FROM_TYPEHASH_STUB, OrderHash._WITNESS_TYPESTRING
    //             )
    //         )
    //     );
    //     assertEq(permitTypeHash, OrderHash._PERMIT_TYPEHASH);
    // }
}