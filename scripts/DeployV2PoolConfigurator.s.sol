// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity >=0.6.0;

import {Script} from 'forge-std/Script.sol';
import {LendingPoolConfigurator} from '@aave/core-v2/contracts/protocol/lendingpool/LendingPoolConfigurator.sol';
import {ILendingPoolAddressesProvider} from '@aave/core-v2/contracts/interfaces/ILendingPoolAddressesProvider.sol';

contract DeployAvax is Script {
  address public constant EXECUTOR_V2 =
    0x7fc3FCb14eF04A48Bb0c12f0c39CD74C249c37d8;

  function run() external {
    vm.startBroadcast();

    // deploy & init lending pool configurator
    LendingPoolConfigurator poolConfigurator = new LendingPoolConfigurator();
    poolConfigurator.initialize(
      ILendingPoolAddressesProvider(
        0xb6A86025F0FE1862B372cb0ca18CE3EDe02A318f // Avalanche V2 Addresses Provider
      )
    );

    vm.stopBroadcast();
  }
}
