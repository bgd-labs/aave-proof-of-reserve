// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
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
contract ProofOfReserveAggregator is IProofOfReserveAggregator, Ownable {
  /// @dev token address => proof or reserve feed
  mapping(address => address) internal _proofOfReserveList;

  /// @dev token address = > reserves provider
  mapping(address => address) internal _reservesProvider;

  constructor() Ownable(msg.sender) {}

  /// @inheritdoc IProofOfReserveAggregator
  function getProofOfReserveFeedForAsset(address asset)
    external
    view
    returns (address)
  {
    return _proofOfReserveList[asset];
  }

  /// @inheritdoc IProofOfReserveAggregator
  function getReservesProviderForAsset(address asset)
    external
    view
    returns (address)
  {
    return _reservesProvider[asset];
  }

  /// @inheritdoc IProofOfReserveAggregator
  function enableProofOfReserveFeed(address asset, address proofOfReserveFeed)
    external
    onlyOwner
  {
    require(asset != address(0) && proofOfReserveFeed != address(0), ZeroAddress());
    require(_proofOfReserveList[asset] == address(0), FeedAlreadyEnabled());

    _proofOfReserveList[asset] = proofOfReserveFeed;
    emit ProofOfReserveFeedStateChanged(
      asset,
      proofOfReserveFeed,
      address(0),
      true
    );
  }

  /// @inheritdoc IProofOfReserveAggregator
  function enableProofOfReserveFeedWithBridgeWrapper(
    address asset,
    address proofOfReserveFeed,
    address bridgeWrapper
  ) external onlyOwner {
    require(
      asset != address(0) && proofOfReserveFeed != address(0) && bridgeWrapper != address(0),
      ZeroAddress()
    );
    require(_proofOfReserveList[asset] == address(0), FeedAlreadyEnabled());

    _proofOfReserveList[asset] = proofOfReserveFeed;
    _reservesProvider[asset] = bridgeWrapper;

    emit ProofOfReserveFeedStateChanged(
      asset,
      proofOfReserveFeed,
      bridgeWrapper,
      true
    );
  }

  /// @inheritdoc IProofOfReserveAggregator
  function disableProofOfReserveFeed(address asset) external onlyOwner {
    delete _proofOfReserveList[asset];
    delete _reservesProvider[asset];
    emit ProofOfReserveFeedStateChanged(asset, address(0), address(0), false);
  }

  /// @inheritdoc IProofOfReserveAggregator
  function areAllReservesBacked(address[] calldata assets)
    external
    view
    returns (bool, bool[] memory)
  {
    bool[] memory unbackedAssetsFlags = new bool[](assets.length);
    bool areReservesBacked = true;

    unchecked {
      for (uint256 i = 0; i < assets.length; ++i) {
        address assetAddress = assets[i];
        address feedAddress = _proofOfReserveList[assetAddress];
        address reserveProvider = _reservesProvider[assetAddress];
        uint256 totalReserves = reserveProvider != address(0)
          ? IReservesProvider(reserveProvider).getTotalReserves()
          : IERC20(assetAddress).totalSupply();

        if (feedAddress != address(0)) {
          (, int256 answer, , , ) = AggregatorInterface(feedAddress)
            .latestRoundData();

          if (
            answer < 0 ||
            totalReserves > uint256(answer)
          ) {
            unbackedAssetsFlags[i] = true;
            areReservesBacked = false;
          }
        }
      }
    }

    return (areReservesBacked, unbackedAssetsFlags);
  }
}
