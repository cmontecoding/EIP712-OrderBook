const ethers = require('ethers');
const fs = require('fs');
require('dotenv').config();

// Load the contract ABI
const contractABI = JSON.parse(fs.readFileSync("out/MockClearingHouse.sol/MockClearinghouse.json", 'utf-8')).abi;

// Connect to the network
const provider = new ethers.providers.JsonRpcProvider(process.env.BASE_TENDERLY_RPC_URL);

// Create a wallet instance
const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

// Connect to the contract
const contract = new ethers.Contract(process.env.CONTRACT_ADDRESS, contractABI, wallet);

// Define the EIP-712 domain
const domain = {
  name: "Mock Clearinghouse",
  version: "1",
  chainId: 8453,
  verifyingContract: process.env.CONTRACT_ADDRESS
};

// Define the EIP-712 types
const types = {
  Order: [
    { name: "conditions", type: "Condition[]" },
    { name: "metadata", type: "Metadata" },
    { name: "trade", type: "Trade" },
    { name: "trader", type: "Trader" }
  ],
  Condition: [
    { name: "target", type: "address" },
    { name: "selector", type: "bytes4" },
    { name: "data", type: "bytes" },
    { name: "expected", type: "bytes32" }
  ],
  Metadata: [
    { name: "genesis", type: "uint256" },
    { name: "expiration", type: "uint256" },
    { name: "trackingCode", type: "bytes32" },
    { name: "referrer", type: "address" }
  ],
  Trade: [
    { name: "t", type: "uint8" },
    { name: "marketId", type: "uint128" },
    { name: "size", type: "int128" },
    { name: "price", type: "uint256" }
  ],
  Trader: [
    { name: "nonce", type: "uint256" },
    { name: "accountId", type: "uint128" },
    { name: "signer", type: "address" }
  ]
};

// Define the order data
const order = {
  conditions: [
    {
      target: "0x1234567890AbcdEF1234567890aBcdef12345678",
      selector: "0x35b09a6e",
      data: '0x' + Buffer.from('data').toString('hex'),
      expected: '0x' + Buffer.from('expected').toString('hex').padEnd(64, '0')
    }
  ],
  metadata: {
    genesis: 1,
    expiration: 2,
    trackingCode: '0x' + Buffer.from('KWENTA').toString('hex').padEnd(64, '0'),
    referrer: "0x1234567890AbcdEF1234567890aBcdef12345678"
  },
  trade: {
    t: 0, // BUY
    marketId: 1,
    size: 1,
    price: 1
  },
  trader: {
    nonce: 1,
    accountId: 1,
    signer: wallet.address
  }
};

const order2 = {
  conditions: [
    {
      target: "0x1234567890AbcdEF1234567890aBcdef12345678",
      selector: "0x35b09a6e",
      data: '0x' + Buffer.from('data').toString('hex'),
      expected: '0x' + Buffer.from('expected').toString('hex').padEnd(64, '0')
    }
  ],
  metadata: {
    genesis: 1,
    expiration: 2,
    trackingCode: '0x' + Buffer.from('KWENTA').toString('hex').padEnd(64, '0'),
    referrer: "0x1234567890AbcdEF1234567890aBcdef12345678"
  },
  trade: {
    t: 0, // BUY
    marketId: 1,
    size: -1,
    price: 1
  },
  trader: {
    nonce: 1,
    accountId: 1,
    signer: wallet.address
  }
};

async function signOrder(order) {
  const signature = await wallet._signTypedData(domain, types, order);
  return signature;
}

async function signOrder2(order2) {
  const signature2 = await wallet._signTypedData(domain, types, order2);
  return signature2;
}

async function testContract() {
  console.log("Signing order...");
  const signature = await signOrder(order);
  const signature2 = await signOrder(order2);
  console.log("Signature:", signature);
  console.log("Signature2:", signature2);

  const request = {
    orders: [order, order2],
    signatures: [signature, signature2]
  };

  console.log("Testing settle function...");
  try {
    const settleResponse = await contract.settle(request);
  } catch (error) {
    console.error("Error in settle:", error);
  }

  console.log("Testing canSettle function...");
  try {
    const canSettleResponse = await contract.canSettle(request);
    console.log("Can Settle Response:", canSettleResponse);
  } catch (error) {
    console.error("Error in canSettle:", error);
  }

  // Additional tests
  const halfFullRequest = {
    orders: [order],
    signatures: [signature]
  };

  const emptyRequest = {
    orders: [],
    signatures: []
  };

  const tooLargeRequest = {
    orders: [order, order, order],
    signatures: [signature, signature, signature]
  };

  const invalidNumberSignaturesRequest = {
    orders: [order, order],
    signatures: [signature]
  };

  console.log("Testing edge cases...");
  try {
    const halfFullResponse = await contract.canSettle(halfFullRequest);
    console.log("Half Full Request Response:", halfFullResponse);

    const emptyResponse = await contract.canSettle(emptyRequest);
    console.log("Empty Request Response:", emptyResponse);

    const tooLargeResponse = await contract.canSettle(tooLargeRequest);
    console.log("Too Large Request Response:", tooLargeResponse);

    const invalidSignaturesResponse = await contract.canSettle(invalidNumberSignaturesRequest);
    console.log("Invalid Number of Signatures Response:", invalidSignaturesResponse);
  } catch (error) {
    console.error("Error in edge case tests:", error);
  }
}

testContract().catch(console.error);