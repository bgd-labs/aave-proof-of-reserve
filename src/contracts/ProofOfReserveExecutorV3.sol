// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DataTypes, IPoolAddressesProvider, IPool, IPoolConfigurator} from 'aave-address-book/AaveV3.sol';
import {ProofOfReserveExecutorBase} from './ProofOfReserveExecutorBase.sol';
import {IProofOfReserveExecutor} from '../interfaces/IProofOfReserveExecutor.sol';
import {ReserveConfiguration} from '../helpers/ReserveConfiguration.sol';
import {EnumerableSet} from 'openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol';

/**
 * @title ProofOfReserveExecutorV3
 * @notice ProofOfReserveExecutor contract for the Aave V3 Pool instance that can perform emergency action
 * if any enabled reserve fails in its Proof of Reserve feed validation, by freezing the reserves that are not backed
 * and setting their LTV to zero.
 * @author BGD Labs
 */
contract ProofOfReserveExecutorV3 is ProofOfReserveExecutorBase {
  using EnumerableSet for EnumerableSet.AddressSet;

  /// @notice Aave V3 Pool.
  IPool internal immutable POOL;
  /// @notice Aave V3 Pool Configurator
  IPoolConfigurator internal immutable POOL_CONFIGURATOR;

  /**
   * @notice Constructor.
   * @param poolAddressesProviderAddress The address of the Aave's V3 pool addresses provider
   * @param proofOfReserveAggregatorAddress The address of Proof of Reserve aggregator contract
   * @param owner The owner address
   */
  constructor(
    address poolAddressesProviderAddress,
    address proofOfReserveAggregatorAddress,
    address owner
  ) ProofOfReserveExecutorBase(proofOfReserveAggregatorAddress, owner) {
    IPoolAddressesProvider addressesProvider = IPoolAddressesProvider(
      poolAddressesProviderAddress
    );
    POOL = IPool(addressesProvider.getPool());
    POOL_CONFIGURATOR = IPoolConfigurator(addressesProvider.getPoolConfigurator());
  }

  /// @inheritdoc IProofOfReserveExecutor
  function isEmergencyActionPossible() external view override returns (bool) {
    address[] memory enabledAssets = _enabledAssets.values();

    (, bool[] memory unbackedAssetsFlags) = _proofOfReserveAggregator
      .areAllReservesBacked(enabledAssets);

    for (uint256 i = 0; i < enabledAssets.length; ++i) {
      if (unbackedAssetsFlags[i]) {
        DataTypes.ReserveConfigurationMap memory configuration = POOL
          .getConfiguration(enabledAssets[i]);

        if (!ReserveConfiguration.getFrozen(configuration)) {
          return true;
        }
      }
    }

    return false;
  }

  /// @inheritdoc IProofOfReserveExecutor
  function executeEmergencyAction() external override {
    address[] memory enabledAssets = _enabledAssets.values();
    (
      bool areReservesBacked,
      bool[] memory unbackedAssetsFlags
    ) = _proofOfReserveAggregator.areAllReservesBacked(enabledAssets);

    if (!areReservesBacked) {
      for (uint256 i = 0; i < enabledAssets.length; ++i) {
        if (unbackedAssetsFlags[i]) {
          address asset = enabledAssets[i];

          // freeze reserve
          POOL_CONFIGURATOR.setReserveFreeze(asset, true);

          emit AssetIsNotBacked(asset);
        }
      }

      emit EmergencyActionExecuted();
    }
  }
}
