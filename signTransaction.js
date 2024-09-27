const { ethers } = require("ethers");
import {fs} from 'fs';
require('dotenv').config(); // Load environment variables from .env file

// Load the contract ABI and bytecode
const contractABI = JSON.parse(fs.readFileSync("out/MockClearingHouse.sol/MockClearinghouse.json")).abi;

// Define the EIP-712 domain
const domain = {
    name: "Mock Clearinghouse",
    version: "1",
    chainId: 8453, // Base (Tenderly fork)
    verifyingContract: process.env.CONTRACT_ADDRESS // Load contract address from .env file
};

// Define the EIP-712 types
const types = {
    Order: [
        { name: "metadata", type: "Metadata" },
        { name: "trader", type: "Trader" },
        { name: "trade", type: "Trade" },
        { name: "conditions", type: "Condition[]" }
    ],
    Metadata: [
        { name: "genesis", type: "uint256" },
        { name: "expiration", type: "uint256" },
        { name: "trackingCode", type: "bytes32" },
        { name: "referrer", type: "address" }
    ],
    Trader: [
        { name: "nonce", type: "uint256" },
        { name: "accountId", type: "uint128" },
        { name: "signer", type: "address" }
    ],
    Trade: [
        { name: "t", type: "uint8" },
        { name: "marketId", type: "uint128" },
        { name: "size", type: "int128" },
        { name: "price", type: "uint256" }
    ],
    Condition: [
        { name: "target", type: "address" },
        { name: "selector", type: "bytes4" },
        { name: "data", type: "bytes" },
        { name: "expected", type: "bytes32" }
    ]
};

// Define the order data
const order = {
    metadata: {
        genesis: 1,
        expiration: 2,
        trackingCode: ethers.utils.formatBytes32String("KWENTA"),
        referrer: "0x1234567890abcdef1234567890abcdef12345678"
    },
    trader: {
        nonce: 1,
        accountId: 1,
        signer: "0x96aA512665C429cE1454abe871098E4858c9c147"
    },
    trade: {
        t: 0, // BUY
        marketId: 1,
        size: 1,
        price: 1
    },
    conditions: [
        {
            target: "0x1234567890abcdef1234567890abcdef12345678",
            selector: "",
            data: "",
            expected: ""
        }
    ]
};

// Sign the data
async function signOrder() {
    const privateKey = process.env.PRIVATE_KEY; // Load private key from .env file
    const wallet = new ethers.Wallet(privateKey);

    const signature = await wallet.signTypedData(domain, types, order);
    console.log("Signature:", signature);

    // Split the signature into v, r, s
    const { v, r, s } = ethers.utils.splitSignature(signature);
    console.log("v:", v);
    console.log("r:", r);
    console.log("s:", s);

    // Pack the signature
    const packedSignature = ethers.utils.concat([r, s, ethers.utils.hexlify(v)]);
    console.log("Packed Signature:", packedSignature);

    return { order, packedSignature };
}

// Interact with the contract on Tenderly
async function interactWithContract(order, packedSignature) {
    const provider = new ethers.providers.JsonRpcProvider(process.env.TENDERLY_RPC_URL); // Load Tenderly RPC URL from .env file
    const contract = new ethers.Contract(process.env.CONTRACT_ADDRESS, contractABI, provider);

    const request = {
        orders: [order, order],
        signatures: [packedSignature, packedSignature]
    };

    const response = await contract.canSettle(request);
    console.log("Response:", response);
}

async function main() {
    const { order, packedSignature } = await signOrder();
    await interactWithContract(order, packedSignature);
}

main();