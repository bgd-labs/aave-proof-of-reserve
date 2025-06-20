// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IPoolAddressesProvider} from './IPoolAddressesProvider.sol';

struct ReserveConfigurationMap {
  //bit 0-15: LTV
  //bit 16-31: Liq. threshold
  //bit 32-47: Liq. bonus
  //bit 48-55: Decimals
  //bit 56: Reserve is active
  //bit 57: reserve is frozen
  //bit 58: borrowing is enabled
  //bit 59: stable rate borrowing enabled
  //bit 60-63: reserved
  //bit 64-79: reserve factor
  uint256 data;
}

interface IPool {
  function getReservesList() external view returns (address[] memory);

  function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

  function getAddressesProvider() external view returns (IPoolAddressesProvider);

  function getConfiguration(address asset) external view returns (ReserveConfigurationMap memory);
}
