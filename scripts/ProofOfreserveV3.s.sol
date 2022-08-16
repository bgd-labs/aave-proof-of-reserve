// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';
import {ProofOfReserveV3} from '../src/contracts/ProofOfReserveV3.sol';

contract Deploy is Script {
  function run() external {
    vm.startBroadcast();
    new ProofOfReserveV3();
    vm.stopBroadcast();
  }
}
