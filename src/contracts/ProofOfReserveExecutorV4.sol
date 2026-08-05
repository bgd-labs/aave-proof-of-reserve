// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IHub, ISpoke, ISpokeConfigurator} from 'aave-address-book/AaveV4.sol';
import {ProofOfReserveExecutorBase} from './ProofOfReserveExecutorBase.sol';
import {IProofOfReserveExecutor} from '../interfaces/IProofOfReserveExecutor.sol';
import {IProofOfReserveExecutorV4} from '../interfaces/IProofOfReserveExecutorV4.sol';

/**
 * @title ProofOfReserveExecutorV4
 * @notice ProofOfReserveExecutor contract for the Aave V4 hub-and-spoke architecture that can perform
 * an emergency action if any enabled reserve fails in its Proof of Reserve feed validation.
 * @dev The emergency action, for each unbacked monitored asset, scans every enabled Hub where the asset is
 * listed, discovers the Spokes that consume it, and freezes the matching reserve of each Spoke through
 * the Aave V4 SpokeConfigurator.
 * @author Aave Labs
 */
contract ProofOfReserveExecutorV4 is
  ProofOfReserveExecutorBase,
  IProofOfReserveExecutorV4
{
  /// @notice The Aave V4 SpokeConfigurator used to freeze reserves.
  ISpokeConfigurator internal immutable _spokeConfigurator;

  /// @dev the list of the Aave V4 Hubs on which the monitored assets are looked up.
  address[] internal _hubs;

  /// @dev hub address => is it contained in the list.
  mapping(address => bool) internal _hubsState;

  /**
   * @notice Constructor.
   * @param spokeConfiguratorAddress The address of the Aave V4 SpokeConfigurator
   * @param proofOfReserveAggregatorAddress The address of Proof of Reserve aggregator contract
   */
  constructor(
    address spokeConfiguratorAddress,
    address proofOfReserveAggregatorAddress
  ) ProofOfReserveExecutorBase(proofOfReserveAggregatorAddress) {
    _spokeConfigurator = ISpokeConfigurator(spokeConfiguratorAddress);
  }

  /// @inheritdoc IProofOfReserveExecutorV4
  function getHubs() external view returns (address[] memory) {
    return _hubs;
  }

  /// @inheritdoc IProofOfReserveExecutorV4
  function enableHubs(address[] memory hubs) external onlyOwner {
    for (uint256 i = 0; i < hubs.length; ++i) {
      if (hubs[i] == address(0)) revert ZeroAddress();

      if (!_hubsState[hubs[i]]) {
        _hubs.push(hubs[i]);
        _hubsState[hubs[i]] = true;
        emit HubStateChanged(hubs[i], true);
      }
    }
  }

  /// @inheritdoc IProofOfReserveExecutorV4
  function disableHubs(address[] memory hubs) external onlyOwner {
    for (uint256 i = 0; i < hubs.length; ++i) {
      if (_hubsState[hubs[i]]) {
        _deleteHubFromArray(hubs[i]);
        delete _hubsState[hubs[i]];
        emit HubStateChanged(hubs[i], false);
      }
    }
  }

  /// @inheritdoc IProofOfReserveExecutor
  function isEmergencyActionPossible() external view override returns (bool) {
    (, bool[] memory unbackedAssetsFlags) = _proofOfReserveAggregator
      .areAllReservesBacked(_assets);

    uint256 assetsLength = _assets.length;

    for (uint256 i = 0; i < assetsLength; ++i) {
      if (unbackedAssetsFlags[i] && _hasUnfrozenReserve(_assets[i])) {
        return true;
      }
    }

    return false;
  }

  /// @inheritdoc IProofOfReserveExecutor
  function executeEmergencyAction() external override {
    (
      bool areReservesBacked,
      bool[] memory unbackedAssetsFlags
    ) = _proofOfReserveAggregator.areAllReservesBacked(_assets);

    if (!areReservesBacked) {
      uint256 assetsLength = _assets.length;

      for (uint256 i = 0; i < assetsLength; ++i) {
        if (unbackedAssetsFlags[i] && _freezeReservesForAsset(_assets[i])) {
          emit AssetIsNotBacked(_assets[i]);
        }
      }

      emit EmergencyActionExecuted();
    }
  }

  /**
   * @dev Returns whether the `underlying` asset has at least one reserve that is listed and not yet
   * frozen across all the enabled hubs and their spokes.
   * @param underlying The address of the underlying asset.
   * @return True if an unfrozen reserve was found, false otherwise.
   */
  function _hasUnfrozenReserve(
    address underlying
  ) internal view returns (bool) {
    uint256 hubsLength = _hubs.length;

    for (uint256 i = 0; i < hubsLength; ++i) {
      IHub hub = IHub(_hubs[i]);

      if (!hub.isUnderlyingListed(underlying)) {
        continue;
      }

      uint256 assetId = hub.getAssetId(underlying);
      uint256 spokesLength = hub.getSpokeCount(assetId);

      for (uint256 j = 0; j < spokesLength; ++j) {
        address spoke = hub.getSpokeAddress(assetId, j);

        (bool exists, uint256 reserveId) = _getReserveId(
          spoke,
          address(hub),
          assetId
        );

        if (exists && !_isFrozen(spoke, reserveId)) {
          return true;
        }
      }
    }

    return false;
  }

  /**
   * @dev Freezes every listed and not yet frozen reserve of the `underlying` asset across all the
   * enabled hubs and their spokes.
   * @param underlying The address of the underlying asset.
   * @return acted True if at least one reserve was frozen, false otherwise.
   */
  function _freezeReservesForAsset(
    address underlying
  ) internal returns (bool acted) {
    uint256 hubsLength = _hubs.length;

    for (uint256 i = 0; i < hubsLength; ++i) {
      IHub hub = IHub(_hubs[i]);

      if (!hub.isUnderlyingListed(underlying)) {
        continue;
      }

      uint256 assetId = hub.getAssetId(underlying);
      uint256 spokesLength = hub.getSpokeCount(assetId);

      for (uint256 j = 0; j < spokesLength; ++j) {
        address spoke = hub.getSpokeAddress(assetId, j);

        (bool exists, uint256 reserveId) = _getReserveId(
          spoke,
          address(hub),
          assetId
        );

        if (exists && !_isFrozen(spoke, reserveId)) {
          _spokeConfigurator.freezeReserve(spoke, reserveId);
          acted = true;
        }
      }
    }
  }

  /**
   * @dev Safely resolves the reserve identifier of the `(hub, assetId)` pair on the given `spoke`.
   * @dev Not every address registered as a spoke on the Hub necessarily holds a reserve for the asset
   * (e.g. the fee receiver spoke), so the lookup is wrapped to avoid reverting.
   * @param spoke The address of the Spoke.
   * @param hub The address of the Hub where the asset is listed.
   * @param assetId The identifier of the asset on the Hub.
   * @return exists True if the spoke holds a reserve for the pair.
   * @return reserveId The identifier of the reserve, if it exists.
   */
  function _getReserveId(
    address spoke,
    address hub,
    uint256 assetId
  ) internal view returns (bool exists, uint256 reserveId) {
    try ISpoke(spoke).getReserveId(hub, assetId) returns (uint256 id) {
      return (true, id);
    } catch {
      return (false, 0);
    }
  }

  /**
   * @dev Returns whether the reserve is frozen, treating a failed lookup as frozen so that no action
   * is attempted on a reserve whose configuration cannot be read.
   * @param spoke The address of the Spoke.
   * @param reserveId The identifier of the reserve.
   * @return True if the reserve is frozen or its configuration cannot be read.
   */
  function _isFrozen(
    address spoke,
    uint256 reserveId
  ) internal view returns (bool) {
    try ISpoke(spoke).getReserveConfig(reserveId) returns (
      ISpoke.ReserveConfig memory config
    ) {
      return config.frozen;
    } catch {
      return true;
    }
  }

  /**
   * @dev delete hub from array.
   * @param hub the address to delete
   */
  function _deleteHubFromArray(address hub) internal {
    uint256 hubsLength = _hubs.length;

    for (uint256 i = 0; i < hubsLength; ++i) {
      if (_hubs[i] == hub) {
        if (i != hubsLength - 1) {
          _hubs[i] = _hubs[hubsLength - 1];
        }

        _hubs.pop();
        break;
      }
    }
  }
}
