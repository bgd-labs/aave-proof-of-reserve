// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from './oz-common/Ownable.sol';
import {AggregatorV3Interface} from '../interfaces/AggregatorV3Interface.sol';
import {IERC20} from './oz-common/interfaces/IERC20.sol';

import {IProofOfReserveExecutor} from '../interfaces/IProofOfReserveExecutor.sol';
import {ProofOfReserveAggregator} from './ProofOfReserveAggregator.sol';

/**
 * @author BGD Labs
 * @dev Aave market-specific contract for Proof of Reserve validations:
 * - Stores list of token addresses that will be validated against their proof of reserve feed data
 * - Returns if all tokens of a list of assets are properly backed or not.
 */
abstract contract ProofOfReserveExecutorBase is
  IProofOfReserveExecutor,
  Ownable
{
  /// @dev proof of reserve aggregator contract that holds
  ProofOfReserveAggregator internal _proofOfReserveAggregator;

  /// @dev the list of the tokens, which total supply we would check against data of the associated proof of reserve feed
  address[] internal _assets;

  /// @dev token address = > is it contained in the list
  mapping(address => bool) internal _assetsState;

  /**
   * @notice Constructor.
   * @param proofOfReserveAggregatorAddress The address of Proof of Reserve aggregator contract
   */
  constructor(address proofOfReserveAggregatorAddress) {
    _proofOfReserveAggregator = ProofOfReserveAggregator(
      proofOfReserveAggregatorAddress
    );
  }

  /// @inheritdoc IProofOfReserveExecutor
  function getAssets() external view returns (address[] memory) {
    return _assets;
  }

  /// @inheritdoc IProofOfReserveExecutor
  function enableAssets(address[] memory assets) external onlyOwner {
    for (uint256 i = 0; i < assets.length; i++) {
      if (!_assetsState[assets[i]]) {
        _assets.push(assets[i]);
        _assetsState[assets[i]] = true;
        emit AssetStateChanged(assets[i], true);
      }
    }
  }

  /// @inheritdoc IProofOfReserveExecutor
  function disableAssets(address[] memory assets) external onlyOwner {
    for (uint256 i = 0; i < assets.length; i++) {
      if (_assetsState[assets[i]]) {
        _deleteAssetFromArray(assets[i]);
        delete _assetsState[assets[i]];
        emit AssetStateChanged(assets[i], false);
      }
    }
  }

  /**
   * @dev delete asset from array.
   * @param asset the address to delete
   */
  function _deleteAssetFromArray(address asset) internal {
    for (uint256 i = 0; i < _assets.length; i++) {
      if (_assets[i] == asset) {
        if (i != _assets.length - 1) {
          _assets[i] = _assets[_assets.length - 1];
        }

        _assets.pop();
        break;
      }
    }
  }

  /// @inheritdoc IProofOfReserveExecutor
  function areAllReservesBacked() external view returns (bool) {
    if (_assets.length == 0) {
      return true;
    }

    (bool areAllReservesbacked, ) = _proofOfReserveAggregator
      .areAllReservesBacked(_assets);

    return areAllReservesbacked;
  }

  /// @inheritdoc IProofOfReserveExecutor
  function executeEmergencyAction() external {
    (
      bool areReservesBacked,
      bool[] memory unbackedAssetsFlags
    ) = _proofOfReserveAggregator.areAllReservesBacked(_assets);

    if (!areReservesBacked) {
      _disableBorrowing();

      for (uint256 i = 0; i < _assets.length; i++) {
        if (unbackedAssetsFlags[i]) {
          emit AssetIsNotBacked(_assets[i]);
        }
      }

      emit EmergencyActionExecuted();
    }
  }

  /**
   * @dev disable borrowing for every asset on the market.
   */
  function _disableBorrowing() internal virtual;

  /// @inheritdoc IProofOfReserveExecutor
  function isBorrowingEnabledForAtLeastOneAsset()
    external
    view
    virtual
    returns (bool);
}
