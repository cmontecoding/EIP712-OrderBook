// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IClearinghouse} from "synthetix-v3/markets/perps-market/contracts/interfaces/IClearinghouse.sol";

contract MockClearinghouse is IClearinghouse {

    function settle(Request calldata request) external override returns (Response memory) {
        return Response({
            success: true,
            data: "Settlement successful"
        });
    }

    function canSettle(Request calldata request) external view override returns (Response memory) {
        return Response({
            success: true,
            data: "Settlement successful"
        });
    }

    function hash(Order calldata order) external pure override returns (bytes32) {
        return keccak256(abi.encode(order));
    }

}