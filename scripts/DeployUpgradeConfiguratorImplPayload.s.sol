// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';
// import {AaveV2Avalanche} from 'aave-address-book/AaveAddressBook.sol';
import {UpgradeV2ConfiguratorImplPayload} from '../src/proposal/UpgradeV2ConfiguratorImplPayload.sol';

contract Deploy is Script {
  address public constant EXECUTOR_V2 =
    0x7fc3FCb14eF04A48Bb0c12f0c39CD74C249c37d8;

  address public constant POOL_CONFIGURATOR =
    0xC383AAc4B3dC18D9ce08AB7F63B4632716F1e626;

  function run() external {
    vm.startBroadcast();

    // deploy proposal
    new UpgradeV2ConfiguratorImplPayload(EXECUTOR_V2, POOL_CONFIGURATOR);

    vm.stopBroadcast();
  }
}
