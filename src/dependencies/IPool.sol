// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IPoolAddressProvider} from './IPoolAddressProvider.sol';

interface IPool {
  function getReservesList() external view returns (address[] memory);

  function ADDRESSES_PROVIDER() external view returns (IPoolAddressProvider);

  function getAddressesProvider() external view returns (IPoolAddressProvider);
}
