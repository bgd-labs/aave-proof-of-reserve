// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DataTypes, ILendingPoolAddressesProvider, ILendingPool, ILendingPoolConfigurator} from 'aave-address-book/AaveV2.sol';
import {ProofOfReserveExecutorBase} from './ProofOfReserveExecutorBase.sol';
import {IProofOfReserveExecutor} from '../interfaces/IProofOfReserveExecutor.sol';
import {ReserveConfiguration} from '../helpers/ReserveConfiguration.sol';
import {EnumerableSet} from 'openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol';

/**
 * @title ProofOfReserveExecutorV2
 * @notice ProofOfReserveExecutor contract for the Aave V2 Pool instance that can perform emergency action
 * if any enabled reserve fails in its Proof of Reserve feed validation, by disabling borrowing of all assets
 * and freezing the reserves that are not backed.
 * @author BGD Labs
 */
contract ProofOfReserveExecutorV2 is ProofOfReserveExecutorBase {
  using EnumerableSet for EnumerableSet.AddressSet;

  /// @notice The Aave V2 Pool
  ILendingPool public immutable POOL;
  /// @notice Aave V2 Pool Configurator
  ILendingPoolConfigurator public immutable POOL_CONFIGURATOR;

  /**
   * @notice Constructor.
   * @param poolAddressesProviderAddress The address of the Aave's V2 pool addresses provider
   * @param proofOfReserveAggregatorAddress The address of Proof of Reserve aggregator contract
   * @param owner The owner address
   */
  constructor(
    address poolAddressesProviderAddress,
    address proofOfReserveAggregatorAddress,
    address owner
  ) ProofOfReserveExecutorBase(proofOfReserveAggregatorAddress, owner) {
    ILendingPoolAddressesProvider addressesProvider = ILendingPoolAddressesProvider(
        poolAddressesProviderAddress
      );
    POOL = ILendingPool(addressesProvider.getLendingPool());
    POOL_CONFIGURATOR = ILendingPoolConfigurator(
      addressesProvider.getLendingPoolConfigurator()
    );
  }

  /// @inheritdoc IProofOfReserveExecutor
  function isEmergencyActionPossible() external view override returns (bool) {
    address[] memory allAssets = POOL.getReservesList();
    address[] memory enabledAssets = _enabledAssets.values();

    (, bool[] memory unbackedAssetsFlags) = PROOF_OF_RESERVE_AGGREGATOR
      .areAllReservesBacked(enabledAssets);

    // check if unbacked reserves are not frozen
    for (uint256 i; i < enabledAssets.length; ++i) {
      if (unbackedAssetsFlags[i]) {
        DataTypes.ReserveConfigurationMap memory configuration = POOL
          .getConfiguration(enabledAssets[i]);

        if (!ReserveConfiguration.getFrozen(configuration)) {
          return true;
        }
      }
    }

    // check if borrowing is enabled for any of the reserves
    for (uint256 i; i < allAssets.length; ++i) {
      DataTypes.ReserveConfigurationMap memory configuration = POOL
        .getConfiguration(allAssets[i]);

      if (ReserveConfiguration.getBorrowingEnabled(configuration)) {
        return true;
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
    ) = PROOF_OF_RESERVE_AGGREGATOR.areAllReservesBacked(enabledAssets);

    if (!areReservesBacked) {
      _disableBorrowing();

      for (uint256 i; i < enabledAssets.length; ++i) {
        if (unbackedAssetsFlags[i]) {
          address asset = enabledAssets[i];
          // freeze reserve
          POOL_CONFIGURATOR.freezeReserve(asset);

          emit AssetIsNotBacked(asset);
        }
      }

      emit EmergencyActionExecuted();
    }
  }

  /**
   * @dev disable borrowing for every asset on the pool.
   */
  function _disableBorrowing() internal {
    address[] memory reservesList = POOL.getReservesList();

    // disable borrowing for all the reserves on the pool
    for (uint256 i = 0; i < reservesList.length; ++i) {
      POOL_CONFIGURATOR.disableReserveStableRate(reservesList[i]);
      POOL_CONFIGURATOR.disableBorrowingOnReserve(reservesList[i]);
    }
  }
}
