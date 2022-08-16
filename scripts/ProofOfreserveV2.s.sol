// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';
import {ProofOfReserveV2} from '../src/contracts/ProofOfReserveV2.sol';

contract Deploy is Script {
  function run() external {
    vm.startBroadcast();
    new ProofOfReserveV2();
    vm.stopBroadcast();
  }
}
