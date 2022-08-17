// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AggregatorV3Interface} from 'chainlink-brownie-contracts/interfaces/AggregatorV3Interface.sol';
import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {IAaveProofOfReserve} from '../interfaces/IAaveProofOfReserve.sol';

/**
 * @author BGD Labs
 * @dev Contract that contains the registry of pairs asset/proof of reserve feed for the chain
 * and can check if any of the assets is not backed.
 */
abstract contract ProofOfReserve is IAaveProofOfReserve, Ownable {
  // the mapping of assets to proof of reserve feeds
  mapping(address => address) internal _proofOfReserveList;

  // the list of the assets to check
  address[] public assets;

  /// @inheritdoc IAaveProofOfReserve
  function getProofOfReserveFeedForAsset(address asset)
    external
    view
    returns (address)
  {
    return _proofOfReserveList[asset];
  }

  /// @inheritdoc IAaveProofOfReserve
  function enableProofOfReserveFeed(address asset, address proofOfReserveFeed)
    public
    onlyOwner
  {
    if (_proofOfReserveList[asset] == address(0)) {
      assets.push(asset);
    }

    _proofOfReserveList[asset] = proofOfReserveFeed;
    emit ProofOfReserveFeedStateChanged(asset, proofOfReserveFeed, true);
  }

  /// @inheritdoc IAaveProofOfReserve
  function disableProofOfReserveFeed(address asset) public onlyOwner {
    delete _proofOfReserveList[asset];
    _deleteAssetFromArray(asset);
    emit ProofOfReserveFeedStateChanged(asset, address(0), false);
  }

  /**
   * @dev delete asset from array.
   * @param asset the address to delete
   */
  function _deleteAssetFromArray(address asset) internal {
    for (uint256 i = 0; i < assets.length; i++) {
      if (assets[i] == asset) {
        if (i != assets.length - 1) {
          assets[i] = assets[assets.length - 1];
        }

        assets.pop();
        break;
      }
    }
  }

  /// @inheritdoc IAaveProofOfReserve
  function areAllReservesBacked() public view returns (bool) {
    for (uint256 i = 0; i < assets.length; i++) {
      address assetAddress = assets[i];
      address feedAddress = _proofOfReserveList[assetAddress];

      if (feedAddress != address(0)) {
        (, int256 answer, , , ) = AggregatorV3Interface(feedAddress)
          .latestRoundData();

        if (answer < 0 || int256(IERC20(assetAddress).totalSupply()) > answer) {
          return false;
        }
      }
    }

    return true;
  }
}
