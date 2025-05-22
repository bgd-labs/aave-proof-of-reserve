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
  ILendingPool internal immutable _pool;
  /// @notice Aave V2 Pool Configurator
  ILendingPoolConfigurator internal immutable _configurator;

  /**
   * @notice Constructor.
   * @param poolAddressesProviderAddress The address of the Aave's V2 pool addresses provider
   * @param proofOfReserveAggregatorAddress The address of Proof of Reserve aggregator contract
   */
  constructor(
    address poolAddressesProviderAddress,
    address proofOfReserveAggregatorAddress
  ) ProofOfReserveExecutorBase(proofOfReserveAggregatorAddress) {
    ILendingPoolAddressesProvider addressesProvider = ILendingPoolAddressesProvider(
        poolAddressesProviderAddress
      );
    _pool = ILendingPool(addressesProvider.getLendingPool());
    _configurator = ILendingPoolConfigurator(
      addressesProvider.getLendingPoolConfigurator()
    );
  }

  /// @inheritdoc IProofOfReserveExecutor
  function isEmergencyActionPossible() external view override returns (bool) {
    address[] memory allAssets = _pool.getReservesList();
    address[] memory enabledAssets = _enabledAssets.values();
    
    (, bool[] memory unbackedAssetsFlags) = _proofOfReserveAggregator
      .areAllReservesBacked(enabledAssets);
    
    // check if unbacked reserves are not frozen
    for (uint256 i; i < enabledAssets.length; ++i) {
      if (unbackedAssetsFlags[i]) {
        DataTypes.ReserveConfigurationMap memory configuration = _pool
          .getConfiguration(enabledAssets[i]);

        if (!ReserveConfiguration.getIsFrozen(configuration)) {
          return true;
        }
      }
    }

    // check if borrowing is enabled for any of the reserves
    for (uint256 i; i < allAssets.length; ++i) {
      DataTypes.ReserveConfigurationMap memory configuration = _pool
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
    ) = _proofOfReserveAggregator.areAllReservesBacked(enabledAssets);

    if (!areReservesBacked) {
      _disableBorrowing();

      for (uint256 i; i < enabledAssets.length; ++i) {
        if (unbackedAssetsFlags[i]) {
          address asset = enabledAssets[i];
          // freeze reserve
          _configurator.freezeReserve(asset);

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
    address[] memory reservesList = _pool.getReservesList();

    // disable borrowing for all the reserves on the pool
    for (uint256 i = 0; i < reservesList.length; ++i) {
      _configurator.disableReserveStableRate(reservesList[i]);
      _configurator.disableBorrowingOnReserve(reservesList[i]);
    }
  }
}
