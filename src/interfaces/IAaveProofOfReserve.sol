// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAaveProofOfReserve {
  event EmergencyActionExecuted(address indexed reserve, address indexed user);

  function addReserve(address reserve, address proofOfReserveFeed) external;

  function removeReserve(address reserve) external;

  function anyAssetReserveIsNotProofed(address poolAddress)
    external
    view
    returns (bool);

  function executeEmergencyAction(
    address poolAddress,
    address poolConfiguratorAddress
  ) external;
}
