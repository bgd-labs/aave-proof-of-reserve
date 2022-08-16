// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPool} from '../dependencies/IPool.sol';

interface IAaveProofOfReserve {
  enum PoolVersion {
    V2,
    V3
  }

  event EmergencyActionExecuted(address indexed user);

  function addReserve(address reserve, address proofOfReserveFeed) external;

  function removeReserve(address reserve) external;

  function areAllReservesBacked(IPool pool) external view returns (bool);

  function executeEmergencyAction(IPool pool, PoolVersion version) external;
}
