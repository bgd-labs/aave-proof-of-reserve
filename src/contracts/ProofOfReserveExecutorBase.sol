// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {AggregatorV3Interface} from 'chainlink-brownie-contracts/interfaces/AggregatorV3Interface.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';

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
  /// @dev proof of reserve aggregator contract that
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
  function enableAsset(address asset) external onlyOwner {
    if (!_assetsState[asset]) {
      _assets.push(asset);
      _assetsState[asset] = true;
      emit AssetStateChanged(asset, true);
    }
  }

  /// @inheritdoc IProofOfReserveExecutor
  function disableAsset(address asset) external onlyOwner {
    _deleteAssetFromArray(asset);
    delete _assetsState[asset];
    emit AssetStateChanged(asset, false);
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
  function executeEmergencyAction() external virtual;

  /// @inheritdoc IProofOfReserveExecutor
  function isBorrowingEnabledForAtLeastOneAsset()
    external
    view
    virtual
    returns (bool);
}
