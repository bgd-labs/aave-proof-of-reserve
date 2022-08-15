// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface IPoolAddressProvider {
  function getPoolConfigurator() external view returns (address);

  function getLendingPoolConfigurator() external view returns (address);
}
