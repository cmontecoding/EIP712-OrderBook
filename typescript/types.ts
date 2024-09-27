export const Order = {
    Order: [
        { name: 'metadata', type: 'Metadata' },
        { name: 'trader', type: 'Trader' },
        { name: 'trade', type: 'Trade' },
        { name: 'conditions', type: 'Condition[]' },
    ],
    Metadata: [
        { name: 'genesis', type: 'uint256' },
        { name: 'expiration', type: 'uint256' },
        { name: 'trackingCode', type: 'bytes32' },
        { name: 'referrer', type: 'address' },
    ],
    Trader: [
        { name: 'nonce', type: 'uint256' },
        { name: 'accountId', type: 'uint128' },
        { name: 'signer', type: 'address' },
    ],
    Trade: [
        { name: 't', type: 'uint8' },
        { name: 'marketId', type: 'uint128' },
        { name: 'size', type: 'int128' },
        { name: 'price', type: 'uint256' },
    ],
    Condition: [
        { name: 'target', type: 'address' },
        { name: 'selector', type: 'bytes4' },
        { name: 'data', type: 'bytes' },
        { name: 'expected', type: 'bytes32' },
    ],
}