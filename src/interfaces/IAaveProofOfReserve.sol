// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPool} from '../dependencies/IPool.sol';

interface IAaveProofOfReserve {
  /**
   * @dev emitted when new asset and it's proof of reserve feed are enabled or disabled
   * @param asset the address of the asset
   * @param proofOfReserveFeed the address of the PoR feed
   * @param enabled whether it was enabled or disabled
   */
  event ProofOfReserveFeedStateChanged(
    address indexed asset,
    address indexed proofOfReserveFeed,
    bool enabled
  );

  /**
   * @dev emitted when borrowing of all assets on the market is disabled
   * @param user the address of the user who inited the action
   */
  event EmergencyActionExecuted(address indexed user);

  /**
   * @dev add the asset and corresponding proof of reserve feed to the registry.
   * @param asset the address of the asset
   * @param proofOfReserveFeed the address of the proof of reserve aggregator feed
   */
  function enableProofOfReserveFeed(address asset, address proofOfReserveFeed)
    external;

  /**
   * @dev delete the asset and the proof of reserve feed from the registry.
   * @param asset address of the asset
   */
  function disableProofOfReserveFeed(address asset) external;

  /**
   * @dev returns if all the assets in the registry are backed.
   */
  function areAllReservesBacked() external view returns (bool);

  /**
   * @dev disable borrowing for all the assets on the pool when at least
   * one of the assets in the registry is not backed.
   */
  function executeEmergencyAction() external;
}
