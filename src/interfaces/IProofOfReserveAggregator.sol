// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProofOfReserveAggregator {
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
   * @dev add the asset and corresponding proof of reserve feed to the registry.
   * @param asset the address of the asset
   */
  function getProofOfReserveFeedForAsset(address asset)
    external
    view
    returns (address);

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
   * @dev returns if all the assets that have been passed are backed;
   * @param assets list of the assets to check
   */
  function areAllReservesBacked(address[] calldata assets)
    external
    view
    returns (bool, bool[] memory);
}
