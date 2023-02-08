// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';
// import {AaveV2Avalanche} from 'aave-address-book/AaveAddressBook.sol';
import {UpgradeV2ConfiguratorImplPayload} from '../src/proposal/UpgradeV2ConfiguratorImplPayload.sol';

contract DeployAvax is Script {
  address public constant AGGREGATOR =
    0x80f2c02224a2E548FC67c0bF705eBFA825dd5439;

  address public constant EXECUTOR_V2 =
    0x7fc3FCb14eF04A48Bb0c12f0c39CD74C249c37d8;

  address public constant EXECUTOR_V3 =
    0xab22988D93d5F942fC6B6c6Ea285744809D1d9Cc;

  address public constant POOL_CONFIGURATOR =
    0xC383AAc4B3dC18D9ce08AB7F63B4632716F1e626;

  function run() external {
    vm.startBroadcast();

    // deploy proposal
    new UpgradeV2ConfiguratorImplPayload(
      AGGREGATOR,
      EXECUTOR_V2,
      EXECUTOR_V3,
      POOL_CONFIGURATOR
    );

    vm.stopBroadcast();
  }
}
