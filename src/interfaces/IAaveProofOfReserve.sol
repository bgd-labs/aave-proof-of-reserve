// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAaveProofOfReserve {
  enum PoolVersion {
    v2,
    v3
  }

  event EmergencyActionExecuted(address indexed asset, address indexed user);

  function addReserve(address asset, address reserveFeed) external;

  function removeReserve(address asset) external;

  function checkMarket(address pool, PoolVersion version)
    external
    returns (bool);

  function doSomething(address pool, PoolVersion version) external;
}
