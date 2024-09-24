// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IClearinghouse} from "synthetix-v3/markets/perps-market/contracts/interfaces/IClearinghouse.sol";

contract MockClearinghouse is IClearinghouse {
    /// @notice The name of this contract
    string public constant name = "Mock Clearinghouse";

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );

    /// @notice The EIP-712 typehash for the order struct used by the contract
    bytes32 public constant ORDER_TYPEHASH =
        keccak256(
            "Order(Metadata metadata,Trader trader,Trade trade,Condition[] conditions)Metadata(uint256 genesis,uint256 expiration,string trackingCode,address referrer)Trader(address traderAddress,uint256 traderId)Trade(uint256 tradeId,uint256 amount)Condition(uint256 conditionId,string conditionType)"
        );

    /// @notice The EIP-712 typehash for the metadata struct used by the order struct
    bytes32 public constant METADATA_TYPEHASH =
        keccak256(
            "Metadata(uint256 genesis,uint256 expiration,bytes32 trackingCode,address referrer)"
        );

    /// @notice The EIP-712 typehash for the trader struct used by the order struct
    bytes32 public constant TRADER_TYPEHASH =
        keccak256("Trader(uint256 nonce,uint128 accountId,address signer)");

    /// @notice The EIP-712 typehash for the trade struct used by the order struct
    bytes32 public constant TRADE_TYPEHASH =
        keccak256("Trade(Type t,uint128 marketId,int128 size,uint256 price)");

    /// @notice The EIP-712 typehash for the condition struct used by the order struct
    bytes32 public constant CONDITION_TYPEHASH =
        keccak256(
            "Condition(address target,bytes4 selector,bytes data,bytes32 expected)"
        );

    function settle(
        Request calldata request
    ) external override returns (Response memory) {
        return Response({success: true, data: "Settlement successful"});
    }

    function canSettle(
        Request calldata request
    ) external view override returns (Response memory) {
        return Response({success: true, data: "Settlement successful"});
    }

    function hash(
        Order calldata order
    ) external view override returns (bytes32) {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                getChainId(),
                address(this)
            )
        );
        bytes32 structHash = hashOrder(order);
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        return digest;
    }

    // helper functions

    function hashOrder(Order memory order) public pure returns (bytes32) {
        bytes32[] memory conditionHashes = new bytes32[](
            order.conditions.length
        );
        for (uint256 i = 0; i < order.conditions.length; i++) {
            conditionHashes[i] = hashCondition(order.conditions[i]);
        }

        return
            keccak256(
                abi.encode(
                    ORDER_TYPEHASH,
                    hashMetadata(order.metadata),
                    hashTrader(order.trader),
                    hashTrade(order.trade),
                    keccak256(abi.encodePacked(conditionHashes))
                )
            );
    }

    function hashMetadata(
        Metadata memory metadata
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    METADATA_TYPEHASH,
                    metadata.genesis,
                    metadata.expiration,
                    metadata.trackingCode,
                    metadata.referrer
                )
            );
    }

    function hashTrader(Trader memory trader) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    TRADER_TYPEHASH,
                    trader.nonce,
                    trader.accountId,
                    trader.signer
                )
            );
    }

    function hashTrade(Trade memory trade) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    TRADE_TYPEHASH,
                    trade.t,
                    trade.marketId,
                    trade.size,
                    trade.price
                )
            );
    }

    function hashCondition(
        Condition memory condition
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    CONDITION_TYPEHASH,
                    condition.target,
                    condition.selector,
                    keccak256(condition.data),
                    condition.expected
                )
            );
    }

    function getChainId() internal view returns (uint) {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}
