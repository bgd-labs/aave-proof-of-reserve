// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DataTypes, IPoolAddressesProvider, IPool, IPoolConfigurator} from 'aave-address-book/AaveV3.sol';
import {ProofOfReserveExecutorBase} from './ProofOfReserveExecutorBase.sol';
import {IProofOfReserveExecutor} from '../interfaces/IProofOfReserveExecutor.sol';
import {ReserveConfiguration} from '../helpers/ReserveConfiguration.sol';

/**
 * @title ProofOfReserveExecutorV3
 * @notice ProofOfReserveExecutor contract for the Aave V3 Pool instance that can perform emergency action
 * if any enabled reserve fails in its Proof of Reserve feed validation, by freezing the reserves that are not backed
 * and setting their LTV to zero.
 * @author BGD Labs
 */
contract ProofOfReserveExecutorV3 is ProofOfReserveExecutorBase {
  /// @notice Aave V3 Pool.
  IPool internal immutable _pool;
  /// @notice Aave V3 Pool Configurator
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
    IPoolAddressesProvider addressesProvider = IPoolAddressesProvider(
      poolAddressesProviderAddress
    );
    _pool = IPool(addressesProvider.getPool());
    _configurator = IPoolConfigurator(addressesProvider.getPoolConfigurator());
  }

  /// @inheritdoc IProofOfReserveExecutor
  function isEmergencyActionPossible() external view override returns (bool) {
    (, bool[] memory unbackedAssetsFlags) = _proofOfReserveAggregator
      .areAllReservesBacked(_assets);

    uint256 assetsLength = _assets.length;

    for (uint256 i = 0; i < assetsLength; ++i) {
      if (unbackedAssetsFlags[i]) {
        DataTypes.ReserveConfigurationMap memory configuration = _pool
          .getConfiguration(_assets[i]);

        if (!ReserveConfiguration.getFrozen(configuration)) {
          return true;
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
          address asset = _assets[i];

          // freeze reserve
          _configurator.setReserveFreeze(asset, true);

          emit AssetIsNotBacked(asset);
        }
      }

      emit EmergencyActionExecuted();
    }
  }
}
