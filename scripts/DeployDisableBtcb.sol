// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';
import {DisableBtcbPayload} from '../src/proposal/DisableBtcbPayload.sol';

contract Deploy is Script {
  function run() external {
    vm.startBroadcast();

    new DisableBtcbPayload();

    vm.stopBroadcast();
  }
}
