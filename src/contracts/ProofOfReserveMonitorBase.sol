// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AggregatorV3Interface} from 'chainlink-brownie-contracts/interfaces/AggregatorV3Interface.sol';
import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {IProofOfReserveMonitor} from '../interfaces/IProofOfReserveMonitor.sol';
import {ProofOfReserve} from './ProofOfReserve.sol';

/**
 * @author BGD Labs
 * @dev Contract that contains the registry of pairs asset/proof of reserve feed for the chain
 * and can check if any of the assets is not backed.
 */
abstract contract ProofOfReserveMonitorBase is IProofOfReserveMonitor, Ownable {
  // proof of reserve registry for checkings
  ProofOfReserve internal _proofOfReserve;

  // the list of the assets to check
  address[] internal _assets;

  // the list of the assets to check
  mapping(address => bool) internal _assetsState;

  constructor(address proofOfReserveAddress) {
    _proofOfReserve = ProofOfReserve(proofOfReserveAddress);
  }

  /// @inheritdoc IProofOfReserveMonitor
  function getAssetsList() external view returns (address[] memory) {
    return _assets;
  }

  /// @inheritdoc IProofOfReserveMonitor
  function enableAsset(address asset) external onlyOwner {
    if (!_assetsState[asset]) {
      _assets.push(asset);
      _assetsState[asset] = true;
      emit AssetStateChanged(asset, true);
    }
  }

  /// @inheritdoc IProofOfReserveMonitor
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

  /// @inheritdoc IProofOfReserveMonitor
  function areAllReservesBacked() external view returns (bool) {
    if (_assets.length == 0) {
      return true;
    }

    (bool result, ) = _proofOfReserve.areAllReservesBacked(_assets);

    return result;
  }
}
