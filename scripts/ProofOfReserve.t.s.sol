// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';
import {ProofOfReserve.t} from '../src/contracts/ProofOfReserve.t.sol';

contract Deploy is Script {
  function run() external {
    vm.startBroadcast();
    new ProofOfReserve.t();
    vm.stopBroadcast();
  }
}
