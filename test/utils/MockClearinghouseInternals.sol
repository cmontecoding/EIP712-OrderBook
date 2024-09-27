// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {MockClearinghouse} from "../../src/MockClearinghouse.sol";

contract MockClearinghouseInternals is MockClearinghouse {
    function hashOrder(Order memory order) public view returns (bytes32) {
        return _hashOrder(order);
    }

    function hashCondition(Condition memory condition) public view returns (bytes32) {
        return _hashCondition(condition);
    }

    function hashMetadata(Metadata memory metadata) public view returns (bytes32) {
        return _hashMetadata(metadata);
    }

    function hashTrade(Trade memory trade) public view returns (bytes32) {
        return _hashTrade(trade);
    }

    function hashTrader(Trader memory trader) public view returns (bytes32) {
        return _hashTrader(trader);
    }
}
