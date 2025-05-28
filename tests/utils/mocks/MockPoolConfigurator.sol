// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DataTypes as DataTypesV3} from 'aave-address-book/AaveV3.sol';
import {DataTypes as DataTypesV2} from 'aave-address-book/AaveV2.sol';
import {ReserveConfiguration} from 'aave-v3-origin/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';
import {ReserveConfigurationV2} from '../ReserveConfigurationV2.sol';
import {MockPoolV3, MockPoolV2} from './MockPool.sol';

contract MockPoolConfiguratorV3 {
  using ReserveConfiguration for DataTypesV3.ReserveConfigurationMap;
  MockPoolV3 internal _pool;

  constructor(MockPoolV3 pool) {
    _pool = pool;
  }

  function setReserveFreeze(address asset, bool freeze) external {
    DataTypesV3.ReserveConfigurationMap memory currentConfig = _pool
      .getConfiguration(asset);

    currentConfig.setFrozen(freeze);
    currentConfig.setLtv(0);
    _pool.setConfiguration(asset, currentConfig);
  }
}

contract MockPoolConfiguratorV2 {
  MockPoolV2 internal _pool;
  using ReserveConfigurationV2 for DataTypesV2.ReserveConfigurationMap;

  constructor(MockPoolV2 pool) {
    _pool = pool;
  }

  function freezeReserve(address asset) external {
    DataTypesV2.ReserveConfigurationMap memory currentConfig = _pool
      .getConfiguration(asset);

    currentConfig.setFrozen(true);

    _pool.setConfiguration(asset, currentConfig.data);
  }

  function disableReserveStableRate(address asset) external {
    DataTypesV2.ReserveConfigurationMap memory currentConfig = _pool
      .getConfiguration(asset);

    currentConfig.setStableRateBorrowingEnabled(false);

    _pool.setConfiguration(asset, currentConfig.data);
  }

  function disableBorrowingOnReserve(address asset) external {
    DataTypesV2.ReserveConfigurationMap memory currentConfig = _pool
      .getConfiguration(asset);

    currentConfig.setBorrowingEnabled(false);

    _pool.setConfiguration(asset, currentConfig.data);
  }
}
