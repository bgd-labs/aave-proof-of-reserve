// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface IPoolConfigurator {
  function setReserveBorrowing(address asset, bool enabled) external;

  function setReserveStableRateBorrowing(address asset, bool enabled) external;

  function disableBorrowingOnReserve(address asset) external;

  function disableReserveStableRate(address asset) external;

  // V2
  event BorrowingDisabledOnReserve(address indexed asset);

  event StableRateDisabledOnReserve(address indexed asset);

  // V3
  event ReserveBorrowing(address indexed asset, bool enabled);

  event ReserveStableRateBorrowing(address indexed asset, bool enabled);
}
