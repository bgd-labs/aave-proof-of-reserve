// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface IACLManager {
  function addRiskAdmin(address admin) external;

  function removeRiskAdmin(address admin) external;

  function isRiskAdmin(address admin) external view returns (bool);

  function getRoleAdmin(bytes32 role) external view returns (bytes32);
}
