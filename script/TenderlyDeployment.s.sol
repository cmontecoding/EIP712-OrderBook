// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {Script} from "../lib/forge-std/src/Script.sol";
import {MockClearinghouse} from "../src/MockClearinghouse.sol";

/**
 *
 * TESTNET DEPLOYMENT: Base Mainnet (Tenderly fork)
 *
 */
contract TenderlyDeployment is Script {
    // contract(s) being deployed
    MockClearinghouse clearingHouse;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // deploy contract(s)
        clearingHouse = new MockClearinghouse();

        vm.stopBroadcast();
    }
}

/**
 * TO DEPLOY:
 *
 * 1. Load the variables in the .env file
 * > source .env
 *
 * 2. Deploy and verify our contract
 * > forge script script/TenderlyDeployment.s.sol:TenderlyDeployment --rpc-url $BASE_TENDERLY_RPC_URL --broadcast -vvvv --etherscan-api-key $ETHERSCAN_API_KEY --verify
 *
 * 3. Verify the contract
 * > forge verify-contract CONTRACT_ADDRESS src/MockClearinghouse.sol:MockClearinghouse --etherscan-api-key $TENDERLY_ACCESS_KEY --verifier-url $TENDERLY_VERIFIER_URL --watch
 */