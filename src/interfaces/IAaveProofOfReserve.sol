// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAaveProofOfReserve {
  enum PoolVersion {
    V2,
    V3
  }

  event EmergencyActionExecuted(address indexed reserve, address indexed user);

  function addReserve(address reserve, address proofOfReserveFeed) external;

  function removeReserve(address reserve) external;

  function areAllReservesBacked(address poolAddress)
    external
    view
    returns (bool);

  function executeEmergencyAction(address poolAddress, PoolVersion version)
    external;
}
