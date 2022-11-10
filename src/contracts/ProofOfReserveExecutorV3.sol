// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IProofOfReserveExecutor} from '../interfaces/IProofOfReserveExecutor.sol';
import {ProofOfReserveExecutorBase} from './ProofOfReserveExecutorBase.sol';
import {IPoolAddressesProvider} from '../dependencies/IPoolAddressesProvider.sol';
import {IPool, ReserveConfigurationMap} from '../dependencies/IPool.sol';
import {IPoolConfigurator} from '../dependencies/IPoolConfigurator.sol';
import {ReserveConfiguration} from '../helpers/ReserveConfiguration.sol';

/**
 * @author BGD Labs
 * @dev Aave V3 contract for Proof of Reserve emergency action in case of any of bridged reserves is not backed:
 * - Disables borrowing of every asset on the market, when any of them is not backed
 */
contract ProofOfReserveExecutorV3 is ProofOfReserveExecutorBase {
  // AAVE v3 pool addresses provider
  IPoolAddressesProvider internal immutable _addressesProvider;

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
  // TODO: not needed in current impl
  function isBorrowingEnabledForAtLeastOneAsset()
    external
    view
    override
    returns (bool)
  {
    IPool pool = IPool(_addressesProvider.getPool());
    address[] memory allAssets = pool.getReservesList();

    for (uint256 i; i < allAssets.length; ++i) {
      ReserveConfigurationMap memory configuration = pool.getConfiguration(
        allAssets[i]
      );

      if (ReserveConfiguration.getBorrowingEnabled(configuration)) {
        return true;
      }
    }

    return false;
  }

  /// @inheritdoc IProofOfReserveExecutor
  function executeEmergencyAction() external override {
    (
      bool areReservesBacked,
      bool[] memory unbackedAssetsFlags
    ) = _proofOfReserveAggregator.areAllReservesBacked(_assets);

    if (!areReservesBacked) {
      IPool pool = IPool(_addressesProvider.getPool());
      IPoolConfigurator configurator = IPoolConfigurator(
        _addressesProvider.getPoolConfigurator()
      );

      uint256 assetsLength = _assets.length;

      for (uint256 i = 0; i < assetsLength; ++i) {
        if (unbackedAssetsFlags[i]) {
          address dualBridgeAsset = _bridgedAssets[_assets[i]];

          address asset = dualBridgeAsset != address(0)
            ? dualBridgeAsset
            : _assets[i];

          ReserveConfigurationMap memory configuration = pool.getConfiguration(
            asset
          );
          (
            ,
            uint256 liquidationThreshold,
            uint256 liquidationBonus
          ) = ReserveConfiguration.getLtvAndLiquidationParams(configuration);

          // set LTV to 0
          configurator.configureReserveAsCollateral(
            asset,
            0,
            liquidationThreshold,
            liquidationBonus
          );

          emit AssetIsNotBacked(asset);
        }
      }

      emit EmergencyActionExecuted();
    }
  }
}
