const { pad, hexToBytes, getAddress, keccak256, createPublicClient, http, createWalletClient, getContract, stringToBytes, defineChain, encodeAbiParameters, parseAbiParameters, toBytes, concat } = require('viem');
import { privateKeyToAccount } from 'viem/accounts'
const { readFileSync } = require('fs');
const { config } = require('dotenv');
const { base } = require('viem/chains');

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
    signer: "0x96aA512665C429cE1454abe871098E4858c9c147"
  }
}

// Sign the data
async function signOrder() {

  // sanity check
  if (getAddress(wallet.address) !== getAddress(order.trader.signer)) {
    throw new Error("Wallet address not equal to order signer")
  }

  const signature = await wallet.signTypedData({
    domain: domain,
    primaryType: 'Order',
    types: orderTypes,
    message: order,
  })

  console.log("Signature:", signature)

  // Define the ORDER_TYPEHASH
  const ORDER_TYPEHASH = keccak256(
    new TextEncoder().encode("Order(Metadata metadata,Trader trader,Trade trade,Condition[] conditions)Condition(address target,bytes4 selector,bytes data,bytes32 expected)Metadata(uint256 genesis,uint256 expiration,bytes32 trackingCode,address referrer)Trade(uint8 t,uint128 marketId,int128 size,uint256 price)Trader(uint256 nonce,uint128 accountId,address signer)")
  )

  if (ORDER_TYPEHASH !== '0x1b6b336c5e77095ee4e3043794d375c20a9d5654e11d1bb0c33df1c210e63a49') {
    throw new Error("ORDER_TYPEHASH mismatch")
  }

  // Define the CONDITION_TYPEHASH
  const CONDITION_TYPEHASH = keccak256(
    new TextEncoder().encode("Condition(address target,bytes4 selector,bytes data,bytes32 expected)")
  )

  if (CONDITION_TYPEHASH !== '0xa78671e011562296314e133d36fbac3c60cba08a14cd761d9dfff1d94cf16b9d') {
    throw new Error("CONDITION_TYPEHASH mismatch")
  }

  // Define the METADATA_TYPEHASH
  const METADATA_TYPEHASH = keccak256(
    new TextEncoder().encode("Metadata(uint256 genesis,uint256 expiration,bytes32 trackingCode,address referrer)")
  )

  if (METADATA_TYPEHASH !== '0x3fb26409690ba72074e6ebc22d4e2bca8f0f7c7706a831359b40cede8a69c0f3') {
    throw new Error("METADATA_TYPEHASH mismatch")
  }

  // Define the TRADE_TYPEHASH
  const TRADE_TYPEHASH = keccak256(
    new TextEncoder().encode("Trade(uint8 t,uint128 marketId,int128 size,uint256 price)")
  )

  if (TRADE_TYPEHASH !== '0x433c9a5d4b303267c7393b9e107e94fa1583ee7cc66f0c4d412f96baf0314099') {
    throw new Error("TRADE_TYPEHASH mismatch")
  }

  // Define the TRADER_TYPEHASH
  const TRADER_TYPEHASH = keccak256(
    new TextEncoder().encode("Trader(uint256 nonce,uint128 accountId,address signer)")
  )

  if (TRADER_TYPEHASH !== '0x2e2f44372bdffa5cfd0ba02a50d853ad42cd226efcb6d6898e058f0d88716f6a') {
    throw new Error("TRADER_TYPEHASH mismatch")
  }

  // Hash individual conditions
  const conditionHashes = order.conditions.map(condition =>
    keccak256(
      encodeAbiParameters(
        parseAbiParameters('bytes32, address, bytes4, bytes, bytes32'),
        [CONDITION_TYPEHASH, condition.target, condition.selector, condition.data, condition.expected]
      )
    )
  )

  if (conditionHashes[0] !== '0xbde287ad2f06064fff4a014e3d93a86d8264413f567c911c6a26ab921fa1d4c5') {
    throw new Error("CONDITION_HASH mismatch")
  }

  // Hash the array of condition hashes using tight packing (encodePacked)
  const conditionsHash = keccak256(
    concat(conditionHashes)
  )

  // Hash the metadata
  const metadataHash = keccak256(
    encodeAbiParameters(
      parseAbiParameters('bytes32, uint256, uint256, bytes32, address'),
      [METADATA_TYPEHASH, order.metadata.genesis, order.metadata.expiration, order.metadata.trackingCode, order.metadata.referrer]
    )
  )

  if (metadataHash !== '0x6609a75dcac514ae8a054c1e4e48c2ae0f429cf00c70f18debcead49624701c4') {
    throw new Error("METADATA_HASH mismatch")
  }

  // Hash the trade
  const tradeHash = keccak256(
    encodeAbiParameters(
      parseAbiParameters('bytes32, uint8, uint128, int128, uint256'),
      [TRADE_TYPEHASH, order.trade.t, order.trade.marketId, order.trade.size, order.trade.price]
    )
  )

  if (tradeHash !== '0x3de551bc2a7cc85cb9b4546a6e15e5f4e709c46393642ea914ba2282dc1e7a81') {
    throw new Error("TRADE_HASH mismatch")
  }

  // Hash the trader
  const traderHash = keccak256(
    encodeAbiParameters(
      parseAbiParameters('bytes32, uint256, uint128, address'),
      [TRADER_TYPEHASH, order.trader.nonce, order.trader.accountId, order.trader.signer]
    )
  )

  if (traderHash !== '0x5a44a495ae61ebfb01c627426271dfc5951c4411a0912b0ef270f7086108f8d6') {
    throw new Error("TRADER_HASH mismatch")
  }

  // Encode the order using the ORDER_TYPEHASH and component hashes
  const encodedOrder = encodeAbiParameters(
    parseAbiParameters('bytes32, bytes32, bytes32, bytes32, bytes32'),
    [ORDER_TYPEHASH, conditionsHash, metadataHash, tradeHash, traderHash]
  )

  // Calculate the hash of the order in the script
  const orderHash = keccak256(encodedOrder)
  console.log("Order Hash (Script):", orderHash)

  if (orderHash !== '0x95d0602f03a09935145b1da0f2febd1483f1c392c31e46db9b41e3cef027c1bf') {
    throw new Error("ORDER_HASH mismatch")
  }

  // Helper function to create the EIP-712 type hash
  const id = (str: string) => keccak256(toBytes(str))

  // Calculate domain separator
  const domainSeparator = keccak256(
    encodeAbiParameters(
      parseAbiParameters('bytes32, bytes32, uint256, address'),
      [
        id('EIP712Domain(string name,uint256 chainId,address verifyingContract)'),
        keccak256(toBytes(domain.name)),
        domain.chainId,
        domain.verifyingContract
      ]
    )
  )

  // Calculate struct hash
  const structHash = keccak256(encodedOrder);

  // Calculate digest
  const digest = keccak256(
    concat([
      '0x1901',
      domainSeparator,
      structHash
    ])
  )

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
    const [digest, domainSeparator, structHash] = await contract.read.hashExposed([order])
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