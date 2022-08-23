// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AggregatorV3Interface} from 'chainlink-brownie-contracts/interfaces/AggregatorV3Interface.sol';
import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {IProofOfReserveExecutor} from '../interfaces/IProofOfReserveExecutor.sol';
import {ProofOfReserve} from './ProofOfReserve.sol';

/**
 * @author BGD Labs
 * @dev Contract that contains the registry of pairs asset/proof of reserve feed for the chain
 * and can check if any of the assets is not backed.
 */
abstract contract ProofOfReserveExecutorBase is
  IProofOfReserveExecutor,
  Ownable
{
  /// @dev proof of reserve aggregator contract that
  ProofOfReserve internal _proofOfReserveAggregator;

  /// @dev the list of the tokens, which total supply we would check against data of the associated proof of reserve feed
  address[] internal _assets;

  /// @dev token address = > is it contained in the list
  mapping(address => bool) internal _assetsState;

  constructor(address proofOfReserveAggregatorAddress) {
    _proofOfReserveAggregator = ProofOfReserve(proofOfReserveAggregatorAddress);
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
  function _deleteAssetFromArray(address asset) private {
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
}
