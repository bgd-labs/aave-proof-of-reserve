// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPool} from '../dependencies/IPool.sol';

interface IAaveProofOfReserve {
  enum PoolVersion {
    V2,
    V3
  }

  event ProofOfReserveFeedStateChanged(
    address indexed asset,
    address indexed proofOfReserveFeed,
    bool enabled
  );
  event EmergencyActionExecuted(address indexed user);

  function enableProofOfReserveFeed(address asset, address proofOfReserveFeed)
    external;

  function disableProofOfReserveFeed(address asset) external;

  function areAllReservesBacked(IPool pool) external view returns (bool);

  function executeEmergencyAction(IPool pool, PoolVersion version) external;
}
