// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AggregatorV3Interface} from 'chainlink-brownie-contracts/interfaces/AggregatorV3Interface.sol';
import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {IProofOfReserveMonitor} from '../interfaces/IProofOfReserveMonitor.sol';

/**
 * @author BGD Labs
 * @dev Contract that contains the registry of pairs asset/proof of reserve feed for the chain
 * and can check if any of the assets is not backed.
 */
abstract contract ProofOfReserveMonitorBase is IProofOfReserveMonitor, Ownable {
  // the list of the assets to check
  address[] internal _assets;

  /// @inheritdoc IProofOfReserveMonitor
  function getAssetsList() external view returns (address[] memory) {
    return _assets;
  }

  /// @inheritdoc IProofOfReserveMonitor
  function enableAsset(address asset) external onlyOwner {
    // somehow control if asset is here?
    _assets.push(asset);

    emit AssetStateChanged(asset, true);
  }

  /// @inheritdoc IProofOfReserveMonitor
  function disableAsset(address asset) external onlyOwner {
    _deleteAssetFromArray(asset);
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

  /// @inheritdoc IProofOfReserveMonitor
  function areAllReservesBacked() public view returns (bool) {
    // call other contract

    return true;
  }
}
