// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProofOfReserveExecutor {
  /**
   * @notice Event is emitted whenever an `asset` is enabled or disabled.
   * @param asset The address of the asset.
   * @param enabled Whether the asset was added or removed from the list.
   */
  event AssetStateChanged(address indexed asset, bool enabled);

  /**
   * @notice Event is emitted whenever an `asset` is not backed
   * @param asset The address of the asset that is not backed
   */
  event AssetIsNotBacked(address indexed asset);

  /**
   * @notice Event is emitted whenever the emergency action is activated
   */
  event EmergencyActionExecuted();

  /**
   * @notice Returns the list of assets enabled whose total supply will be validated against their PoR feed's answer.
   * @return Array of enabled assets.
   */
  function getAssets() external view returns (address[] memory);

  /**
   * @notice Sets a list of addresses whose total supply will be validated against their Proof of Reserve feed's answer.
   * @dev Assets already enabled will not be included.
   * @param assets The array of addresses of the assets
   */
  function enableAssets(address[] memory assets) external;

  /**
   * @notice Removes a list of addresses whose total supply will not be checked against their Proof of Reserve feed.
   * @param assets The array of addresses of the assets
   */
  function disableAssets(address[] memory assets) external;

  /**
   * @notice Returns whether the reserves of the enabled assets are backed by checking against their Proof of Reserve feed's answer.
   * @return True if all reserves of the enabled assets are backed, false otherwise.
   */
  function areAllReservesBacked() external view returns (bool);

  /**
   * @notice Returns whether the emergency action can be executed.
   * @dev Helper function used by the automation-compatible contract to check
   * whether the emergency action should be performed. 
   * @return True if the emergency action can be taken, false otherwise. 
   */
  function isEmergencyActionPossible() external view returns (bool);

/**
   * @notice Performs the pool-specific action if at least one reserve of the enabled assets
   * failed during the validation performed against their PoR feed's answer.
   * @dev For the V2 instance, borrowing across all assets is disabled, and the reserves
   * that failed PoR validation are frozen. 
   * @dev For the V3 instance, the reserves that fail PoR validation are frozen, and their LTV is set to 0.
   */
  function executeEmergencyAction() external;
}
