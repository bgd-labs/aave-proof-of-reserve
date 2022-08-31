// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IProofOfReserveExecutor} from '../interfaces/IProofOfReserveExecutor.sol';
import {ProofOfReserveExecutorBase} from './ProofOfReserveExecutorBase.sol';
import {IPool, ReserveConfigurationMap} from '../dependencies/IPool.sol';
import {IPoolAddressesProvider} from '../dependencies/IPoolAddressesProvider.sol';
import {IPoolConfigurator} from '../dependencies/IPoolConfigurator.sol';
import {ReserveConfiguration} from '../helpers/ReserveConfiguration.sol';

/**
 * @author BGD Labs
 * @dev Aave V3 contract for Proof of Reserve emergency action in case of any of bridged reserves is not backed:
 * - Disables borrowing of every asset on the market, when any of them is not backed
 */
contract ProofOfReserveExecutorV3 is ProofOfReserveExecutorBase {
  // AAVE v3 pool address provider
  IPoolAddressesProvider internal _addressesProvider;

  /**
   * @notice Constructor.
   * @param poolAddressesProviderAddress The address of the Aave's V3 pool addresses provider
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
    IPool pool = IPool(_addressesProvider.getPool());
    address[] memory allAssets = pool.getReservesList();

    for (uint256 i; i < allAssets.length; i++) {
      ReserveConfigurationMap memory configuration = pool.getConfiguration(
        allAssets[i]
      );

      (, , bool borrowingEnabled, ) = ReserveConfiguration.getFlags(
        configuration
      );

      if (borrowingEnabled) {
        return true;
      }
    }

    return false;
  }

  /// @inheritdoc IProofOfReserveExecutor
  function executeEmergencyAction() external override {
    (
      bool areAllReservesbacked,
      bool[] memory unbackedAssetsFlags
    ) = _proofOfReserveAggregator.areAllReservesBacked(_assets);

    if (!areAllReservesbacked) {
      IPool pool = IPool(_addressesProvider.getPool());
      address[] memory reservesList = pool.getReservesList();

      IPoolConfigurator configurator = IPoolConfigurator(
        _addressesProvider.getPoolConfigurator()
      );

      for (uint256 i = 0; i < reservesList.length; i++) {
        configurator.setReserveStableRateBorrowing(reservesList[i], false);
        configurator.setReserveBorrowing(reservesList[i], false);
      }

      for (uint256 i = 0; i < _assets.length; i++) {
        if (unbackedAssetsFlags[i]) {
          emit AssetIsNotBacked(_assets[i]);
        }
      }

      emit EmergencyActionExecuted();
    }
  }
}
