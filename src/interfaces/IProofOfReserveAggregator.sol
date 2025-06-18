// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProofOfReserveAggregator {
  struct AssetPoRData {
    /// @notice Chainlink Proof of Reserve feed address for a given asset
    address feed;
    /// @notice The reserve provider address for a given asset 
    address reserveProvider;
    /// @notice Margin for a given asset
    uint16 margin;
  }
  
  /**
   * @notice Event is emitted whenever a Proof of Reserve feed is enabled or disabled for an `asset`
   * @param asset The address of the asset
   * @param proofOfReserveFeed The address of the PoR feed
   * @param reserveProvider The address of the reserve provider, if any.
   * @param margin The margin allowed in which total reserves/supply can exceed the PoR feed's answer.
   * @param enabled Whether the PoR feed for the asset was turned on or off
   */
  event ProofOfReserveFeedStateChanged(
    address indexed asset,
    address indexed proofOfReserveFeed,
    address indexed reserveProvider,
    uint16 margin,
    bool enabled
  );

  /**
   * @dev Attempted to set zero address.
   */
  error ZeroAddress();

  /**
   * @dev Attempted to set feed address to an asset already enabled.
   */
  error FeedAlreadyEnabled();

  /**
   * 
   * @dev Attempted to set the margin to an asset not enabled.
   */
  error AssetNotEnabled();

  /**
   * 
   * @dev Attempted to set the margin higher than allowed.
   */
  error InvalidMargin();

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
   * @notice Returns the address of the reserve provider for a given asset.
   * @dev returns the zero address if the reserve provider for the given asset was not set.
   * @param asset The address of the `asset` whose reserve provider should be returned.
   * @return The address of the reserve provider.
   */
  function getReserveProviderForAsset(address asset)
    external
    view
    returns (address);

  /**
   * @notice Returns the acceptable margin in which the total reserves/supply of the asset
   * can exceed the PoR feeds answer. 
   * @dev returns zero if the given asset was not set.
   * @param asset The address of the `asset` whose margin should be returned.
   * @return The margin allowed for the given asset in Bps 
   */
  function getMarginForAsset(address asset)
    external
    view
    returns (uint16);

  /**
   * @notice Sets the Proof of reserve feed for a given `asset` and its `margin`.
   * @param asset The address of `asset` whose PoR will be enabled.
   * @param proofOfReserveFeed The address of the proof of reserve feed of the `asset`
   * @param margin The acceptable margin in which the total reserves/supply of the asset can exceed the PoR feeds answer.  
   */
  function enableProofOfReserveFeed(address asset, address proofOfReserveFeed, uint16 margin) external;

  /**
   * @notice Sets the Proof of reserve feed for a given `asset` with a reserve provider and its `margin`.
   * @dev This method should be used for the assets with the reserves fetched from a method other than `totalSupply`.
   * @param asset The address of the `asset` whose PoR and reserve provider will be enabled.
   * @param proofOfReserveFeed The address of the proof of reserve aggregator feed of the `asset`.
   * @param reserveProvider The reserve provider of the `asset`
   * @param margin The acceptable margin in which the total reserves/supply of the asset can exceed the PoR feeds answer.  
   */
  function enableProofOfReserveFeedWithReserveProvider(
    address asset,
    address proofOfReserveFeed,
    address reserveProvider,
    uint16 margin
  ) external;

  /**
   * @notice Sets a `margin` for a given `asset`.
   * @dev This method requires the `asset` to have a PoR already enabled.
   * @param asset The address of the `asset` whose margin will be defined.
   * @param margin The acceptable margin in which the total reserves/supply of the asset can exceed the PoR feeds answer.
   */
  function setAssetMargin(address asset, uint16 margin) external;

  /**
   * @notice Removes a given `asset`, its proof of reserve feed, and its reserve provider address.
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
