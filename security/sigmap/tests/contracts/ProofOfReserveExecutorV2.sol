// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IProofOfReserveExecutor} from '../interfaces/IProofOfReserveExecutor.sol';
import {ProofOfReserveExecutorBase} from './ProofOfReserveExecutorBase.sol';
import {IPoolAddressesProvider} from '../dependencies/IPoolAddressesProvider.sol';
import {IPool, ReserveConfigurationMap} from '../dependencies/IPool.sol';
import {IPoolConfigurator} from '../dependencies/IPoolConfigurator.sol';
import {ReserveConfiguration} from '../dependencies/helpers/ReserveConfiguration.sol';

/**
 * @author BGD Labs
 * @dev Aave V2 contract for Proof of Reserve emergency action in case of any of bridged reserves is not backed:
 * - Disables borrowing of every asset on the market, when any of them is not backed
 */
contract ProofOfReserveExecutorV2 is ProofOfReserveExecutorBase {
  // IPoolConfigurator.sol events required for brownie to interpret events
  event BorrowingDisabledOnReserve(address indexed asset);

  event StableRateDisabledOnReserve(address indexed asset);
 
  // AAVE v2 pool addresses provider
  IPoolAddressesProvider internal _addressesProvider;

  /**
   * @notice Constructor.
   * @param poolAddressesProviderAddress The address of the Aave's V2 pool addresses provider
   * @param proofOfReserveAggregatorAddress The address of Proof of Reserve aggregator contract
   */
  constructor(
    address poolAddressesProviderAddress,
    address proofOfReserveAggregatorAddress
  ) ProofOfReserveExecutorBase(proofOfReserveAggregatorAddress) {
    _addressesProvider = IPoolAddressesProvider(poolAddressesProviderAddress);
  }

  /// @inheritdoc IProofOfReserveExecutor
  function isBorrowingEnabledForAtLeastOneAsset()
    external
    view
    override
    returns (bool)
  {
    IPool pool = IPool(_addressesProvider.getLendingPool());
    address[] memory allAssets = pool.getReservesList();

    for (uint256 i; i < allAssets.length; i++) {
      ReserveConfigurationMap memory configuration = pool.getConfiguration(
        allAssets[i]
      );

      if (ReserveConfiguration.getBorrowingEnabled(configuration)) {
        return true;
      }
    }

    return false;
  }

  /// @inheritdoc ProofOfReserveExecutorBase
  function _disableBorrowing() internal override {
    IPool pool = IPool(_addressesProvider.getLendingPool());
    address[] memory reservesList = pool.getReservesList();

    IPoolConfigurator configurator = IPoolConfigurator(
      _addressesProvider.getLendingPoolConfigurator()
    );

    // disable borrowing for all the reserves on the market
    for (uint256 i = 0; i < reservesList.length; i++) {
      configurator.disableReserveStableRate(reservesList[i]);
      configurator.disableBorrowingOnReserve(reservesList[i]);
    }
  }
}
