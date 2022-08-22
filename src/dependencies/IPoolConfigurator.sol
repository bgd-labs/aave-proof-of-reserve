// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface IPoolConfigurator {
  function setReserveBorrowing(address asset, bool enabled) external;

  function setReserveStableRateBorrowing(address asset, bool enabled) external;

  function disableBorrowingOnReserve(address asset) external;
}
