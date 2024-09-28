const { createPublicClient, http, createWalletClient, getContract, stringToBytes, defineChain } = require('viem');
import { privateKeyToAccount } from 'viem/accounts'
const { readFileSync } = require('fs');
const { config } = require('dotenv');
const { base } = require('viem/chains');
const { keccak256, defaultAbiCoder, id } = require('ethers').utils;

// Load environment variables from .env file
config()

// Ensure PRIVATE_KEY is defined
if (!process.env.PRIVATE_KEY) {
  throw new Error('PRIVATE_KEY is not defined in the environment variables');
}

const wallet = privateKeyToAccount(process.env.PRIVATE_KEY as `0x${string}`)

// Load the contract ABI
const contractABI = JSON.parse(readFileSync("out/MockClearingHouse.sol/MockClearinghouse.json", 'utf-8')).abi

// Define the EIP-712 domain
const domain = ({
  name: "Mock Clearinghouse",
  chainId: 8453,
  verifyingContract: process.env.CONTRACT_ADDRESS as `0x${string}`
})

// Define the EIP-712 types
const orderTypes = {
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
}

// Define the FullOrder type
type FullOrder = {
  conditions: {
      target: string,
      selector: string,
      data: string,
      expected: string
  }[],
  metadata: {
      genesis: number,
      expiration: number,
      trackingCode: string,
      referrer: string
  },
  trade: {
      t: number,
      marketId: number,
      size: number,
      price: number
  },
  trader: {
      nonce: number,
      accountId: number,
      signer: string
  }
}

// Define the order data
const order: FullOrder = {
  conditions: [
      {
          target: "0x1234567890abcdef1234567890abcdef12345678",
          selector: '0x' + Buffer.from('someFunction()').toString('hex').slice(0, 8),
          data: '0x' + Buffer.from('data').toString('hex'),
          expected: '0x' + Buffer.from('expected').toString('hex').padEnd(64, '0')
      }
  ],
  metadata: {
      genesis: 1,
      expiration: 2,
      trackingCode: '0x' + Buffer.from('KWENTA').toString('hex').padEnd(64, '0'),
      referrer: "0x1234567890abcdef1234567890abcdef12345678"
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
      signer: "0x96aA512665C429cE1454abe871098E4858c9c147"
  }
}

// Sign the data
async function signOrder() {
  const account = "0x96aA512665C429cE1454abe871098E4858c9c147" as `0x${string}`

  const signature = await wallet.signTypedData({
    domain: domain,
    primaryType: 'Order',
    types: orderTypes,
    message: order,
  })

  console.log("Signature:", signature)

  // Encode the order object
  const encodedOrder = defaultAbiCoder.encode(
    [
        "tuple(address target, bytes4 selector, bytes data, bytes32 expected)[]",
        "tuple(uint256 genesis, uint256 expiration, bytes32 trackingCode, address referrer)",
        "tuple(uint8 t, uint128 marketId, int128 size, uint256 price)",
        "tuple(uint256 nonce, uint128 accountId, address signer)"
    ],
    [order.conditions, order.metadata, order.trade, order.trader]
);

  // Calculate the hash of the order in the script
  const orderHash = keccak256(encodedOrder)
  console.log("Order Hash (Script):", orderHash)

  // Calculate domain separator
  const domainSeparator = keccak256(
    defaultAbiCoder.encode(
      ["bytes32", "bytes32", "uint256", "address"],
      [
        id("EIP712Domain(string name,uint256 chainId,address verifyingContract)"),
        keccak256(Buffer.from(domain.name)),
        domain.chainId,
        domain.verifyingContract
      ]
    )
  );

  // Calculate struct hash
  const structHash = keccak256(encodedOrder);

  // Calculate digest
  const digest = keccak256(
    defaultAbiCoder.encode(
      ["bytes1", "bytes1", "bytes32", "bytes32"],
      ["0x19", "0x01", domainSeparator, structHash]
    )
  );

  console.log("Domain Separator (Script):", domainSeparator);
  console.log("Struct Hash (Script):", structHash);
  console.log("Digest (Script):", digest);

  return { order, signature, wallet, orderHash }
}

// Interact with the contract on Tenderly
async function interactWithContract(order: FullOrder, signature: string, walletClient: any, orderHash: string) {
  const publicClient = createPublicClient({
    chain: base,
    transport: http(process.env.BASE_TENDERLY_RPC_URL as string) // Load Tenderly RPC URL from .env file
  })

  const contract = getContract({
    address: process.env.CONTRACT_ADDRESS as `0x${string}`,
    abi: contractABI,
    client: {
      public: publicClient,
      wallet: walletClient
    }
  })

  const request = {
    orders: [order, order],
    signatures: [signature, signature]
  }

  // Log the request body
  // console.log("Request Body:", JSON.stringify(request, null, 2));

  try {
    const response = await contract.read.settle([request])
    console.log("Response:", response)
  } catch (error) {
    console.error("Error interacting with contract:", error)
    throw error
  }

  try {
    const response = await contract.read.canSettle([request])
    console.log("Response:", response)
  } catch (error) {
    console.error("Error interacting with contract:", error)
    throw error
  }

  try {
    const response = await contract.read.hash([order])
    console.log("The hash of the order:", response)
  } catch (error) {
    console.error("Error interacting with contract:", error)
    throw error
  }

  try {
    const [ digest, domainSeparator, structHash ] = await contract.read.hashExposed([order])
    console.log("Digest (Contract):", digest)
    console.log("Domain Separator (Contract):", domainSeparator)
    console.log("Struct Hash (Contract):", structHash)
  } catch (error) {
    console.error("Error interacting with contract:", error)
    throw error
  }

  // try {
  //   const contractOrderHash = await contract.read._hashOrder([order])
  //   console.log("Order Hash (Contract):", contractOrderHash)

  //   // Compare the hashes
  //   if (orderHash !== contractOrderHash) {
  //     throw new Error("Order hash mismatch between script and contract")
  //   }
  // } catch (error) {
  //   console.error("Error interacting with contract:", error)
  //   throw error
  // }
}

async function main() {
  console.log("Signing order...")
  const { order, signature, wallet, orderHash } = await signOrder()
  console.log("Interacting with contract...")
  await interactWithContract(order, signature, wallet, orderHash)
}

main().catch(console.error)