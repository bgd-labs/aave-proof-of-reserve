// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {AggregatorInterface} from 'aave-v3-origin/contracts/dependencies/chainlink/AggregatorInterface.sol';

import {IProofOfReserveAggregator} from '../interfaces/IProofOfReserveAggregator.sol';

/**
 * @author BGD Labs
 * @dev Aave aggregator contract for Proof of Reserve Feeds and validations based on them:
 * - Indexes proof of reserve feed by token address
 * - Returns if all tokens of a list of assets are properly backed with Proof of Reserve logic, or not.
 */
contract ProofOfReserveAggregator is Ownable, IProofOfReserveAggregator {
  /// @dev token address => proof or reserve feed
  mapping(address => address) internal _proofOfReserveList;

  /// @dev token address = > bridge wrapper
  mapping(address => address) internal _bridgeWrapperList;

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
  function getBridgeWrapperForAsset(address asset)
    external
    view
    returns (address)
  {
    return _bridgeWrapperList[asset];
  }

  /// @inheritdoc IProofOfReserveAggregator
  function enableProofOfReserveFeed(address asset, address proofOfReserveFeed)
    external
    onlyOwner
  {
    require(asset != address(0), 'INVALID_ASSET');
    require(proofOfReserveFeed != address(0), 'INVALID_PROOF_OF_RESERVE_FEED');
    require(_proofOfReserveList[asset] == address(0), 'FEED_ALREADY_ENABLED');

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
    require(asset != address(0), 'INVALID_ASSET');
    require(proofOfReserveFeed != address(0), 'INVALID_PROOF_OF_RESERVE_FEED');
    require(bridgeWrapper != address(0), 'INVALID_BRIDGE_WRAPPER');
    require(_proofOfReserveList[asset] == address(0), 'FEED_ALREADY_ENABLED');

    _proofOfReserveList[asset] = proofOfReserveFeed;
    _bridgeWrapperList[asset] = bridgeWrapper;

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
    delete _bridgeWrapperList[asset];
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
    address feed = _proofOfReserveList[asset];
    if (feed != address(0)) {
      (, int256 answer, , , ) = AggregatorInterface(feed).latestRoundData();

      address bridgeWrapper = _bridgeWrapperList[asset];
    
      uint256 totalSupply = bridgeWrapper != address(0)
      ? IERC20(bridgeWrapper).totalSupply()
      : IERC20(asset).totalSupply();

      if (answer < 0 || totalSupply > uint256(answer)) {
        return false;
      }
    }
    return true;
  }
}
