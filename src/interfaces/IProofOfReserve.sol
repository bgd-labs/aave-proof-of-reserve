// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProofOfReserve {
  event EmergencyActionExecuted(address indexed rerserve, address indexed user);
  function addReserve(address reserve, address reserveFeed) external;
  function removeReserve(address bridgedAsset) external;
  function checkReserves() external;
  function executeEmergencyAction() external;
}
