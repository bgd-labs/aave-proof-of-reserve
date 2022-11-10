// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface IPoolConfigurator {
  function setReserveBorrowing(address asset, bool enabled) external;

  function setReserveStableRateBorrowing(address asset, bool enabled) external;

  function disableBorrowingOnReserve(address asset) external;

  function disableReserveStableRate(address asset) external;

  function configureReserveAsCollateral(
    address asset,
    uint256 ltv,
    uint256 liquidationThreshold,
    uint256 liquidationBonus
  ) external;
}
