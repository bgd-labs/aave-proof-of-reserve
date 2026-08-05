// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProofOfReserveExecutorV4 {
  /**
   * @notice Event is emitted whenever a `hub` is enabled or disabled.
   * @param hub The address of the Aave V4 Hub.
   * @param enabled Whether the hub was added or removed from the list.
   */
  event HubStateChanged(address indexed hub, bool enabled);

  /**
   * @dev Attempted to enable the zero address as a hub.
   */
  error ZeroAddress();

  /**
   * @notice Returns the list of the Aave V4 Hubs monitored by this Executor.
   * @dev A monitored `asset` is looked up on each of these hubs (by its underlying) to find the
   * spokes whose reserves should be frozen when the asset fails its Proof of Reserve validation.
   * @return Array of enabled hubs.
   */
  function getHubs() external view returns (address[] memory);

  /**
   * @notice Adds a list of Aave V4 Hubs to be scanned during the emergency action.
   * @dev Hubs already enabled will not be included.
   * @param hubs The array of addresses of the Aave V4 Hubs.
   */
  function enableHubs(address[] memory hubs) external;

  /**
   * @notice Removes a list of Aave V4 Hubs from the list scanned during the emergency action.
   * @param hubs The array of addresses of the Aave V4 Hubs.
   */
  function disableHubs(address[] memory hubs) external;
}
