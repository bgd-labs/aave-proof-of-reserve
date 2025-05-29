// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DataTypes as DataTypesV3} from 'aave-address-book/AaveV3.sol';
import {DataTypes as DataTypesV2} from 'aave-address-book/AaveV2.sol';

contract MockPoolV3 {
  address immutable _POOL_ADDRESSES_PROVIDER;

  mapping(address reserve => DataTypesV3.ReserveConfigurationMap config)
    internal _configs;

  constructor(address mockPoolAddressesProvider) {
    _POOL_ADDRESSES_PROVIDER = mockPoolAddressesProvider;
  }

  function ADDRESSES_PROVIDER() external view returns (address) {
    return _POOL_ADDRESSES_PROVIDER;
  }

  function setConfiguration(
    address reserve,
    DataTypesV3.ReserveConfigurationMap calldata config
  ) external {
    _configs[reserve] = config;
  }

  function getConfiguration(
    address reserve
  ) external view returns (DataTypesV3.ReserveConfigurationMap memory) {
    return DataTypesV3.ReserveConfigurationMap(_configs[reserve].data);
  }
}

contract MockPoolV2 {
  address immutable _POOL_ADDRESSES_PROVIDER;
  bool deactivateReserve;
  address[] internal _reserves;
  mapping(address reserve => DataTypesV2.ReserveConfigurationMap config) _configs;

  constructor(address mockPoolAddressesProvider) {
    _POOL_ADDRESSES_PROVIDER = mockPoolAddressesProvider;
  }

  function initReserve(address reserve) external {
    _reserves.push(reserve);
  }

  function setConfiguration(address asset, uint256 config) external {
    _configs[asset].data = config;
  }

  function getConfiguration(
    address reserve
  ) external view returns (DataTypesV2.ReserveConfigurationMap memory) {
    uint256 add = deactivateReserve ? 0 : 1;
    return DataTypesV2.ReserveConfigurationMap(_configs[reserve].data + add);
  }

  function switchReserve() external {
    deactivateReserve = true;
  }

  function getReservesList() external view returns (address[] memory) {
    return _reserves;
  }
}
