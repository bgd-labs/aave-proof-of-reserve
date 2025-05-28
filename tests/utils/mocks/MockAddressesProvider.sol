// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MockAddressesProvider {
  address internal _poolV2;
  address internal _poolConfiguratorV2;
  address internal _poolV3;
  address internal _poolConfiguratorV3;

  function setAddresses(
    address poolV2,
    address poolConfiguratorV2,
    address poolV3,
    address poolConfiguratorV3
  ) external {
    _poolV3 = poolV3;
    _poolV2 = poolV2;
    _poolConfiguratorV3 = poolConfiguratorV3;
    _poolConfiguratorV2 = poolConfiguratorV2;
  }


  function getLendingPool() external view returns (address) {
    return _poolV2;
  }
  function getLendingPoolConfigurator() external view returns (address) {
    return _poolConfiguratorV2;
  }

  function getPool() external view returns (address) {
    return _poolV2;
  }
  function getPoolConfigurator() external view returns (address) {
    return _poolConfiguratorV3;
  }
}
