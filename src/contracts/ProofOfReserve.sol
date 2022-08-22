// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AggregatorV3Interface} from 'chainlink-brownie-contracts/interfaces/AggregatorV3Interface.sol';
import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {IProofOfReserve} from '../interfaces/IProofOfReserve.sol';

/**
 * @author BGD Labs
 * @dev Contract that contains the registry of pairs asset/proof of reserve feed for the chain
 * and can check if particular assets are not backed.
 */
contract ProofOfReserve is IProofOfReserve, Ownable {
  // the mapping of assets to proof of reserve feeds
  mapping(address => address) internal _proofOfReserveList;

  /// @inheritdoc IProofOfReserve
  function getProofOfReserveFeedForAsset(address asset)
    external
    view
    returns (address)
  {
    return _proofOfReserveList[asset];
  }

  /// @inheritdoc IProofOfReserve
  function enableProofOfReserveFeed(address asset, address proofOfReserveFeed)
    external
    onlyOwner
  {
    _proofOfReserveList[asset] = proofOfReserveFeed;
    emit ProofOfReserveFeedStateChanged(asset, proofOfReserveFeed, true);
  }

  /// @inheritdoc IProofOfReserve
  function disableProofOfReserveFeed(address asset) external onlyOwner {
    delete _proofOfReserveList[asset];
    emit ProofOfReserveFeedStateChanged(asset, address(0), false);
  }

  /// @inheritdoc IProofOfReserve
  function areAllReservesBacked(address[] calldata assets)
    external
    view
    returns (bool, bool[] memory)
  {
    bool[] memory unbackedAssetsFlags = new bool[](assets.length);
    bool result = true;

    for (uint256 i = 0; i < assets.length; i++) {
      unbackedAssetsFlags[i] = false;

      address assetAddress = assets[i];
      address feedAddress = _proofOfReserveList[assetAddress];

      if (feedAddress != address(0)) {
        (, int256 answer, , , ) = AggregatorV3Interface(feedAddress)
          .latestRoundData();

        if (
          answer < 0 || IERC20(assetAddress).totalSupply() > uint256(answer)
        ) {
          unbackedAssetsFlags[i] = true;
          result = false;
        }
      }
    }

    return (result, unbackedAssetsFlags);
  }
}
