// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DataTypes, IPoolAddressesProvider, IPool, IPoolConfigurator} from 'aave-address-book/AaveV3.sol';
import {ProofOfReserveExecutorBase} from './ProofOfReserveExecutorBase.sol';
import {IProofOfReserveExecutor} from '../interfaces/IProofOfReserveExecutor.sol';
import {ReserveConfiguration} from '../helpers/ReserveConfiguration.sol';

/**
 * @author BGD Labs
 * @dev Aave V3 contract for Proof of Reserve emergency action in case of any of bridged reserves is not backed:
 * - Disables borrowing of every asset on the market, when any of them is not backed
 */
contract ProofOfReserveExecutorV3 is ProofOfReserveExecutorBase {
  // AAVE v3 pool addresses provider
  IPoolAddressesProvider internal immutable _addressesProvider;
  // AAVE v3 pool
  IPool internal immutable _pool;
  // AAVE v3 pool configurator
  IPoolConfigurator internal immutable _configurator;

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
    _pool = IPool(_addressesProvider.getPool());
    _configurator = IPoolConfigurator(_addressesProvider.getPoolConfigurator());
  }

  /// @inheritdoc IProofOfReserveExecutor
  function isEmergencyActionAppliable() external view override returns (bool) {
    (
      bool areReservesBacked,
      bool[] memory unbackedAssetsFlags
    ) = _proofOfReserveAggregator.areAllReservesBacked(_assets);

    if (!areReservesBacked) {
      uint256 assetsLength = _assets.length;

      for (uint256 i = 0; i < assetsLength; ++i) {
        if (unbackedAssetsFlags[i]) {
          address dualBridgeAsset = _bridgedAssets[_assets[i]];

          address asset = dualBridgeAsset != address(0)
            ? dualBridgeAsset
            : _assets[i];

          DataTypes.ReserveConfigurationMap memory configuration = _pool
            .getConfiguration(asset);

          (uint256 ltv, , ) = ReserveConfiguration.getLtvAndLiquidationParams(
            configuration
          );

          if (ltv > 0) {
            return true;
          }
        }
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
      uint256 assetsLength = _assets.length;

      for (uint256 i = 0; i < assetsLength; ++i) {
        if (unbackedAssetsFlags[i]) {
          address dualBridgeAsset = _bridgedAssets[_assets[i]];

          address asset = dualBridgeAsset != address(0)
            ? dualBridgeAsset
            : _assets[i];

          DataTypes.ReserveConfigurationMap memory configuration = _pool
            .getConfiguration(asset);
          (
            ,
            uint256 liquidationThreshold,
            uint256 liquidationBonus
          ) = ReserveConfiguration.getLtvAndLiquidationParams(configuration);

          // set LTV to 0
          _configurator.configureReserveAsCollateral(
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
