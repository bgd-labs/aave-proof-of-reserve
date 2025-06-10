// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {Math} from '@openzeppelin/contracts/utils/math/Math.sol';
import {AggregatorInterface} from 'aave-v3-origin/contracts/dependencies/chainlink/AggregatorInterface.sol';

import {IProofOfReserveAggregator} from '../interfaces/IProofOfReserveAggregator.sol';

/**
 * @title ProofOfReserveAggregator 
 * @notice This contract maintains a list of assets, their proof of reserve feeds,
 * and their bridge wrapper (if applicable), which verifies whether the asset is backed
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
  function getBridgeWrapperForAsset(address asset)
    external
    view
    returns (address)
  {
    return _assetsData[asset].bridgeWrapper;
  }

  /// @inheritdoc IProofOfReserveAggregator
  function getMarginForAsset(address asset)
    external
    view
    returns (uint256)
  {
    return _assetsData[asset].margin;
  }

  /// @inheritdoc IProofOfReserveAggregator
  function enableProofOfReserveFeed(address asset, address proofOfReserveFeed, uint256 margin)
    external
    onlyOwner
  {
    require(asset != address(0) && proofOfReserveFeed != address(0), ZeroAddress());
    require(_assetsData[asset].feed == address(0), FeedAlreadyEnabled());
    require(margin <= MAX_MARGIN, InvalidMargin());

    _assetsData[asset] = AssetPoRData({
      feed: proofOfReserveFeed,
      bridgeWrapper: address(0),
      margin: uint16(margin)
    });

    emit ProofOfReserveFeedStateChanged(
      asset,
      proofOfReserveFeed,
      address(0),
      margin,
      true
    );
  }

  /// @inheritdoc IProofOfReserveAggregator
  function enableProofOfReserveFeedWithBridgeWrapper(
    address asset,
    address proofOfReserveFeed,
    address bridgeWrapper,
    uint256 margin
  ) external onlyOwner {
    require(
      asset != address(0) && proofOfReserveFeed != address(0) && bridgeWrapper != address(0),
      ZeroAddress()
    );
    require(_assetsData[asset].feed == address(0), FeedAlreadyEnabled());
    require(margin <= MAX_MARGIN, InvalidMargin());

    _assetsData[asset] = AssetPoRData({
      feed: proofOfReserveFeed,
      bridgeWrapper: bridgeWrapper,
      margin: uint16(margin)
    });

    emit ProofOfReserveFeedStateChanged(
      asset,
      proofOfReserveFeed,
      bridgeWrapper,
      margin,
      true
    );
  }

  /// @inheritdoc IProofOfReserveAggregator
  function setAssetMargin(address asset, uint256 margin) external onlyOwner {
    require(_assetsData[asset].feed != address(0), AssetNotEnabled());
    require(margin <= MAX_MARGIN, InvalidMargin());

    _assetsData[asset].margin = uint16(margin);

    emit ProofOfReserveFeedStateChanged(
      asset,
      _assetsData[asset].feed,
      _assetsData[asset].bridgeWrapper,
      margin,
      true
    );
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

      uint256 totalSupply = assetData.bridgeWrapper != address(0)
      ? IERC20(assetData.bridgeWrapper).totalSupply()
      : IERC20(asset).totalSupply();

      uint256 excess = _percentMulDiv(uint256(answer), assetData.margin);

      if (totalSupply > uint256(answer) + excess) {
        return false;
      }
    }
    return true;
  }

  function _percentMulDiv(uint256 value, uint256 percent) internal pure returns (uint256) {
    return value.mulDiv(percent, PERCENTAGE_FACTOR);
  }
}
