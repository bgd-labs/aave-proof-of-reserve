// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAaveProofOfReserve {
  event EmergencyActionExecuted(address indexed bridgedAsset, address indexed user);

  function addReserve(address bridgedAsset, address reserveFeed) external;
  function removeReserve(address bridgedAsset) external;
}
