// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';
import {ProofOfReserveAggregator} from '../src/contracts/ProofOfReserveAggregator.sol';
import {ProofOfReserveExecutorV2} from '../src/contracts/ProofOfReserveExecutorV2.sol';
import {ProofOfReserveExecutorV3} from '../src/contracts/ProofOfReserveExecutorV3.sol';
import {ProofOfReserveKeeper} from '../src/contracts/ProofOfReserveKeeper.sol';
import {AvaxBridgeWrapper} from '../src/contracts/AvaxBridgeWrapper.sol';

contract Deploy is Script {
  function run() external {
    vm.startBroadcast();

    // deploy v2 configurator impl

    // init it with some

    // deploy proposal for v2

    vm.stopBroadcast();
  }
}
