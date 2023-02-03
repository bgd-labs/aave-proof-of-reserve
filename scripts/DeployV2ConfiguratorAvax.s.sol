// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity >=0.6.0;

import {Script} from 'forge-std/Test.sol';
import {console} from 'forge-std/console.sol';
import {AaveV2Avalanche, AaveV3Avalanche} from 'aave-address-book/AaveAddressBook.sol';
import {LendingPoolConfigurator} from '@aave/core-v2/contracts/protocol/lendingpool/LendingPoolConfigurator.sol';
import {ILendingPoolAddressesProvider} from '@aave/core-v2/contracts/interfaces/ILendingPoolAddressesProvider.sol';
import {UpgradeAaveV2ConfiguratorPayload} from '../src/proposal/UpgradeAaveV2ConfiguratorPayload.sol';

contract Deploy is Script {
  address public constant EXECUTOR_V2 =
    0x7fc3FCb14eF04A48Bb0c12f0c39CD74C249c37d8;

  function run() external {
    vm.startBroadcast();

    // deploy & init lending pool configurator
    LendingPoolConfigurator poolConfigurator = new LendingPoolConfigurator();
    poolConfigurator.initialize(AaveV2Avalanche.POOL_ADDRESSES_PROVIDER);

    // deploy proposal
    upgradeAaveV2ConfiguratorPayload = new UpgradeAaveV2ConfiguratorPayload(
      EXECUTOR_V2,
      address(poolConfigurator)
    );

    vm.stopBroadcast();
  }
}
