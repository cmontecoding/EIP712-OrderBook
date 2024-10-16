// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IClearinghouse} from "./interfaces/IClearinghouse.sol";
import {SignatureCheckerLib} from "solady/utils/SignatureCheckerLib.sol";

contract MockClearinghouse is IClearinghouse {
    /// @notice The name of this contract
    string public constant name = "Mock Clearinghouse";

    /// @notice The version of this contract
    string public constant version = "1";

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    /// @notice The EIP-712 typehash for the order struct used by the contract
    bytes32 public constant ORDER_TYPEHASH =
        keccak256(
            "Order(Condition[] conditions,Metadata metadata,Trade trade,Trader trader)Condition(address target,bytes4 selector,bytes data,bytes32 expected)Metadata(uint256 genesis,uint256 expiration,bytes32 trackingCode,address referrer)Trade(uint8 t,uint128 marketId,int128 size,uint256 price)Trader(uint256 nonce,uint128 accountId,address signer)"
        );

    /// @notice The EIP-712 typehash for the condition struct used by the order struct
    bytes32 public constant CONDITION_TYPEHASH =
        keccak256(
            "Condition(address target,bytes4 selector,bytes data,bytes32 expected)"
        );

    /// @notice The EIP-712 typehash for the metadata struct used by the order struct
    bytes32 public constant METADATA_TYPEHASH =
        keccak256(
            "Metadata(uint256 genesis,uint256 expiration,bytes32 trackingCode,address referrer)"
        );

    /// @notice The EIP-712 typehash for the trade struct used by the order struct
    bytes32 public constant TRADE_TYPEHASH =
        keccak256("Trade(uint8 t,uint128 marketId,int128 size,uint256 price)");

    /// @notice The EIP-712 typehash for the trader struct used by the order struct
    bytes32 public constant TRADER_TYPEHASH =
        keccak256("Trader(uint256 nonce,uint128 accountId,address signer)");


    function settle(
        Request calldata request
    ) external override returns (Response memory) {
        return canSettle(request);
    }

    function canSettle(
        Request calldata request
    ) public view override returns (Response memory) {
        if (request.orders.length > 2) {
            return Response({success: false, data: "Too many orders"});
        } else if (request.orders.length == 0) {
            return Response({success: false, data: "No orders"});
        } else if (request.orders.length == 1) {
            return Response({success: false, data: "Not enough orders"});
        }
        if (request.signatures.length != request.orders.length) {
            return
                Response({
                    success: false,
                    data: "Invalid number of signatures"
                });
        }
        for (uint256 i = 0; i < request.orders.length; i++) {
            Order memory order = request.orders[i];
            bytes memory signature = request.signatures[i];
            bool validSignature = SignatureCheckerLib.isValidSignatureNow(
                order.trader.signer,
                hash(order),
                signature
            );
            if (!validSignature) {
                return
                    Response({
                        success: false,
                        data: "Invalid signature for order"
                    });
            }
        }
        if (request.orders[0].trade.price != request.orders[1].trade.price) {
            return Response({success: false, data: "Invalid trade pair: price"});
        }
        // Assert that the trades are opposites (short and long)
        bool order1IsLong = request.orders[0].trade.size > 0;
        bool order2IsLong = request.orders[1].trade.size > 0;
        if (order1IsLong == order2IsLong) {
            return Response({success: false, data: "Invalid trade pair: size"});
        }
        return Response({success: true, data: "Settlement successful"});
    }

    function hash(
        Order memory order
    ) public view override returns (bytes32) {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                _getChainId(),
                address(this)
            )
        );
        bytes32 structHash = _hashOrder(order);
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        return digest;
    }

    /*///////////////////////////////////////////////////////////////
                                INTERNALS
    ///////////////////////////////////////////////////////////////*/

    function _hashOrder(Order memory order) internal pure returns (bytes32) {
        bytes32[] memory conditionHashes = new bytes32[](
            order.conditions.length
        );
        for (uint256 i = 0; i < order.conditions.length; i++) {
            conditionHashes[i] = _hashCondition(order.conditions[i]);
        }

        return
            keccak256(
                abi.encode(
                    ORDER_TYPEHASH,
                    keccak256(abi.encodePacked(conditionHashes)),
                    _hashMetadata(order.metadata),
                    _hashTrade(order.trade),
                    _hashTrader(order.trader)
                )
            );   
    }

    function _hashCondition(
        Condition memory condition
    ) internal pure returns (bytes32) {
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

    function _hashMetadata(
        Metadata memory metadata
    ) internal pure returns (bytes32) {
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

    function _hashTrade(Trade memory trade) internal pure returns (bytes32) {
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

    function _hashTrader(Trader memory trader) internal pure returns (bytes32) {
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

    function _getChainId() internal view returns (uint) {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}
