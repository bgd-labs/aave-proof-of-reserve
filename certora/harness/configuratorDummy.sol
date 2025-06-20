// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract configuratorDummy {
  uint256 public _ltv;
  bool public freezeWasCalled;

  function configureReserveAsCollateral(
    address asset,
    uint256 ltv,
    uint256 liquidationThreshold,
    uint256 liquidationBonus
  ) external {
    _ltv = ltv;
  }

  function setReserveFreeze(address _asset, bool freeze) external {
    freezeWasCalled = true;
  }
}
