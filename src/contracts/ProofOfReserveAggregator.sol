// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {Math} from '@openzeppelin/contracts/utils/math/Math.sol';
import {AggregatorInterface} from 'aave-v3-origin/contracts/dependencies/chainlink/AggregatorInterface.sol';

import {IProofOfReserveAggregator} from '../interfaces/IProofOfReserveAggregator.sol';
import {IReservesProvider} from '../interfaces/IReservesProvider.sol';

/**
 * @title ProofOfReserveAggregator 
 * @notice This contract maintains a list of assets, their proof of reserve feeds,
 * and their reserves provider (if applicable), which verifies whether the asset is backed
 * by checking its total supply and the corresponding PoR feed's answer.
 * @author BGD Labs
 */
contract ProofOfReserveAggregator is Ownable, IProofOfReserveAggregator {
  using Math for uint256;
  /// @dev 100%
  uint256 public constant PERCENTAGE_FACTOR = 100_00;

  /// @dev 10%
  uint256 public constant MAX_MARGIN = 10_00;

  /// @dev Map of asset and their PoR data;
  mapping(address asset => AssetPoRData) internal _assetsData;

  constructor(address owner) Ownable(owner) {}

  /// @inheritdoc IProofOfReserveAggregator
  function getProofOfReserveFeedForAsset(address asset)
    external
    view
    returns (address)
  {
    return _assetsData[asset].feed;
  }

  /// @inheritdoc IProofOfReserveAggregator
  function getReserveProviderForAsset(address asset)
    external
    view
    returns (address)
  {
    return _assetsData[asset].reserveProvider;
  }

  /// @inheritdoc IProofOfReserveAggregator
  function getMarginForAsset(address asset)
    external
    view
    returns (uint16)
  {
    return _assetsData[asset].margin;
  }

/// @inheritdoc IProofOfReserveAggregator
  function enableProofOfReserveFeed(
    address asset,
    address proofOfReserveFeed,
    uint16 margin
  ) external onlyOwner {
    _validateProofOfReserveParams(
      asset,
      proofOfReserveFeed,
      margin,
      address(0),
      false
    );
    _setAssetData(asset, proofOfReserveFeed, margin, address(0));
  }

  /// @inheritdoc IProofOfReserveAggregator
  function enableProofOfReserveFeedWithReserveProvider(
    address asset,
    address proofOfReserveFeed,
    address reserveProvider,
    uint16 margin
  ) external onlyOwner {
    _validateProofOfReserveParams(
      asset,
      proofOfReserveFeed,
      margin,
      reserveProvider,
      true
    );
    _setAssetData(asset, proofOfReserveFeed, margin, reserveProvider);
  }

  /// @inheritdoc IProofOfReserveAggregator
  function setAssetMargin(address asset, uint16 margin) external onlyOwner {
    AssetPoRData memory assetData = _assetsData[asset];
    require(assetData.feed != address(0), AssetNotEnabled());
    require(margin <= MAX_MARGIN, InvalidMargin());

    _setAssetData(asset, assetData.feed, margin, assetData.reserveProvider);
  }

  /// @inheritdoc IProofOfReserveAggregator
  function disableProofOfReserveFeed(address asset) external onlyOwner {
    delete _assetsData[asset];
    emit ProofOfReserveFeedStateChanged(asset, address(0), address(0), 0, false);
  }

  /// @inheritdoc IProofOfReserveAggregator
  function areAllReservesBacked(address[] calldata assets)
    external
    view
    returns (bool, bool[] memory)
  {
    bool[] memory unbackedAssetsFlags = new bool[](assets.length);
    bool areReservesBacked = true;

    for (uint256 i = 0; i < assets.length; ++i) {
      if (!_isReserveBacked(assets[i])) {
        unbackedAssetsFlags[i] = true;
        areReservesBacked = false;
      }
    }

    return (areReservesBacked, unbackedAssetsFlags);
  }

  /**
   * @notice Sets the Proof of reserve feed data for a given `asset`.
   * @param asset The address of the `asset` whose PoR Data will be set
   * @param proofOfReserveFeed The address of the proof of reserve feed of the `asset`.
   * @param margin The acceptable margin in which the total reserves/supply of the asset can exceed the PoR feeds answer.
   * @param reserveProvider The reserve provider of the `asset`, if any, which is used to retrieve the total reserves.
   */
  function _setAssetData(
    address asset,
    address proofOfReserveFeed,
    uint16 margin,
    address reserveProvider
  ) internal {
    _assetsData[asset] = AssetPoRData({
      feed: proofOfReserveFeed,
      reserveProvider: reserveProvider,
      margin: margin
    });

    emit ProofOfReserveFeedStateChanged(
      asset,
      proofOfReserveFeed,
      reserveProvider,
      margin,
      true
    );
  }

  /**
   * @notice Validates the Proof Of Reserve params that will be set for a given asset
   * @param asset The address of the `asset` whose PoR Data will be set
   * @param proofOfReserveFeed The address of the proof of reserve feed of the `asset`.
   * @param margin The acceptable margin in which the total reserves/supply of the asset can exceed the PoR feeds answer.
   * @param reserveProvider The reserve provider of the `asset`, if any, which is used to retrieve the total reserves.
   * @param reserveProviderEnabled Flag indicating whether the reserveProvider address can be the zero address.
   */
  function _validateProofOfReserveParams(
    address asset,
    address proofOfReserveFeed,
    uint16 margin,
    address reserveProvider,
    bool reserveProviderEnabled
  ) internal view {
    if (reserveProviderEnabled) {
      require(reserveProvider != address(0), ZeroAddress());
    }
    require(
      asset != address(0) && proofOfReserveFeed != address(0),
      ZeroAddress()
    );
    require(_assetsData[asset].feed == address(0), FeedAlreadyEnabled());
    require(margin <= MAX_MARGIN, InvalidMargin());
  }

  /**
   * @notice Returns whether a given `asset` is backed by checking its total supply against its PoR feed's answer.
   * @dev Assets with no PoR feed enabled will return true instantly.
   * @param asset Address of the `asset` whose total supply will be validated against its PoR feed's answer.
   * @return True if the reserves passed in the total supply validation, false otherwise.
   */
  function _isReserveBacked(address asset) internal view returns (bool) {
    AssetPoRData memory assetData  = _assetsData[asset];
    if (assetData.feed != address(0)) {
      (, int256 answer, , , ) = AggregatorInterface(assetData.feed).latestRoundData();

      if (answer < 0) {
        return false;
      }

      uint256 totalSupply = assetData.reserveProvider != address(0)
      ? IReservesProvider(assetData.reserveProvider).getTotalReserves()
      : IERC20(asset).totalSupply();

      uint256 excess = _percentMulDivUp(uint256(answer), assetData.margin);

      if (totalSupply > uint256(answer) + excess) {
        return false;
      }
    }
    return true;
  }

  function _percentMulDivUp(uint256 value, uint256 percent) internal pure returns (uint256) {
    return value.mulDiv(percent, PERCENTAGE_FACTOR, Math.Rounding.Ceil);
  }
}
