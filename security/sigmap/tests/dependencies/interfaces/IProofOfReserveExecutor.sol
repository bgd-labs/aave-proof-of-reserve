// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProofOfReserveExecutor {
  /**
   * @dev emitted when new asset is enabled or disabled
   * @param asset the address of the asset
   * @param enabled whether it was enabled or disabled
   */
  event AssetStateChanged(address indexed asset, bool enabled);

  /**
   * @dev emitted when asset is not backed
   * @param asset asset that is not backed
   */
  event AssetIsNotBacked(address indexed asset);

  /**
   * @dev emitted when borrowing of all assets on the market is disabled
   */
  event EmergencyActionExecuted();

  /**
   * @dev gets the list of the assets to check
   */
  function getAssets() external view returns (address[] memory);

  /**
   * @dev enable checking of proof of reserve for the passed list of assets
   * @param assets the addresses of the assets
   */
  function enableAssets(address[] memory assets) external;

  /**
   * @dev delete the assets and the proof of reserve feeds from the registry.
   * @param assets addresses of the assets
   */
  function disableAssets(address[] memory assets) external;

  /**
   * @dev returns if all the assets in the registry are backed.
   */
  function areAllReservesBacked() external view returns (bool);

  /**
   * @dev returns if borrowing is enabled for at least one asset.
   * This is not checked in executeEmergencyAction(), but is used
   * to prevent infinite execution of performUpkeep() inside the Keeper contract.
   */
  function isBorrowingEnabledForAtLeastOneAsset() external view returns (bool);

  /**
   * @dev disable borrowing for all the assets on the pool when at least
   * one of the assets in the registry is not backed.
   */
  function executeEmergencyAction() external;
}
