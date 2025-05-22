// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProofOfReserveAggregator {
  /**
   * @notice Event is emitted whenever a Proof of Reserve feed is enabled or disabled for an `asset`
   * @param asset The address of the asset
   * @param proofOfReserveFeed The address of the PoR feed
   * @param bridgeWrapper The address of the bridgeWrapper, if any.
   * @param enabled Whether the PoR feed for the asset was turned on or off
   */
  event ProofOfReserveFeedStateChanged(
    address indexed asset,
    address indexed proofOfReserveFeed,
    address indexed bridgeWrapper,
    bool enabled
  );

  /**
   * @notice Returns the address of the proof of reserve feed for a given asset.
   * @dev returns the zero address if the PoR for the given asset was not set.
   * @param asset The address of the `asset` whose proof of reserve feed should be returned.
   * @return The address of the proof of reserve feed.
   */
  function getProofOfReserveFeedForAsset(address asset)
    external
    view
    returns (address);

  /**
   * @notice Returns the address of the bridge wrapper for a given asset.
   * @dev returns the zero address if the bridge wrapper for the given asset was not set.
   * @param asset The address of the `asset` whose bridge wrapper should be returned.
   * @return The address of the bridge wrapper.
   */
  function getBridgeWrapperForAsset(address asset)
    external
    view
    returns (address);

  /**
   * @notice Sets an `asset` and its corresponding proof of reserve feed address. 
   * @param asset The address of the `asset` whose PoR will be enabled.
   * @param proofOfReserveFeed the address of the proof of reserve feed of the `asset`.
   */
  function enableProofOfReserveFeed(address asset, address proofOfReserveFeed)
    external;

  /**
   * @notice Sets an `asset`, its corresponding proof of reserve feed, and its bridge wrapper address.
   * @dev This method should be used for the assets with the existing deprecated bridge.
   * @param asset The address of the `asset` whose PoR and bridge wrapper will be enabled.
   * @param proofOfReserveFeed The address of the proof of reserve aggregator feed of the `asset`.
   * @param bridgeWrapper The bridge wrapper of the `asset`
   */
  function enableProofOfReserveFeedWithBridgeWrapper(
    address asset,
    address proofOfReserveFeed,
    address bridgeWrapper
  ) external;

  /**
   * @notice Removes a given `asset`, its proof of reserve feed, and its bridge wrapper address.
   * @param asset address of the asset whose data will be deleted.
   */
  function disableProofOfReserveFeed(address asset) external;

  /**
   * @notice Returns whether the reserves are backed by checking against their Proof of Reserve feed's answer.
   * @dev Assets with no PoR feed enabled will return true instantly.
   * @param assets The array of asset addresses whose PoR will be checked.
   * @return bool True if all of the assets are backed, false otherwise.
   * @return List of flags indicating whether the asset is backed or not.
   */
  function areAllReservesBacked(address[] calldata assets)
    external
    view
    returns (bool, bool[] memory);
}
