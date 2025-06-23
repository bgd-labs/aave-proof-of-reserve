// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {AggregatorInterface} from 'aave-v3-origin/contracts/dependencies/chainlink/AggregatorInterface.sol';
import {IProofOfReserveExecutor} from '../interfaces/IProofOfReserveExecutor.sol';
import {IProofOfReserveAggregator} from '../interfaces/IProofOfReserveAggregator.sol';
import {EnumerableSet} from 'openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol';

/**
 * @title ProofOfReserveExecutorBase
 * @notice An abstract pool-specific contract that maintains a list of assets whose total supply
 * will be verified against their proof of reserve feed data fetched from the ProofOfReserveAggregator contract.
 * @author BGD Labs
 */
abstract contract ProofOfReserveExecutorBase is
  Ownable,
  IProofOfReserveExecutor
{
  using EnumerableSet for EnumerableSet.AddressSet;

  /// @inheritdoc IProofOfReserveExecutor
  IProofOfReserveAggregator public immutable PROOF_OF_RESERVE_AGGREGATOR;

  /// @notice List of assets whose total supply will be validated against their PoR feed's answer on the Aggregator contract.
  EnumerableSet.AddressSet internal _enabledAssets;

  /**
   * @notice Constructor.
   * @param proofOfReserveAggregatorAddress The address of Proof of Reserve aggregator contract
   */
  constructor(
    address proofOfReserveAggregatorAddress,
    address owner
  ) Ownable(owner) {
    PROOF_OF_RESERVE_AGGREGATOR = IProofOfReserveAggregator(
      proofOfReserveAggregatorAddress
    );
  }

  /// @inheritdoc IProofOfReserveExecutor
  function getAssets() external view returns (address[] memory) {
    return _enabledAssets.values();
  }

  /// @inheritdoc IProofOfReserveExecutor
  function enableAssets(address[] calldata assets) external onlyOwner {
    for (uint256 i; i < assets.length; ++i) {
      if (_enabledAssets.add(assets[i])) {
        emit AssetStateChanged(assets[i], true);
      }
    }
  }

  /// @inheritdoc IProofOfReserveExecutor
  function disableAssets(address[] calldata assets) external onlyOwner {
    for (uint256 i; i < assets.length; ++i) {
      if (_enabledAssets.remove(assets[i])) {
        emit AssetStateChanged(assets[i], false);
      }
    }
  }

  /// @inheritdoc IProofOfReserveExecutor
  function areAllReservesBacked() external view returns (bool) {
    if (_enabledAssets.length() == 0) {
      return true;
    }

    (bool areReservesBacked, ) = PROOF_OF_RESERVE_AGGREGATOR
      .areAllReservesBacked(_enabledAssets.values());

    return areReservesBacked;
  }

  /// @inheritdoc IProofOfReserveExecutor
  function isEmergencyActionPossible() external view virtual returns (bool);
}
