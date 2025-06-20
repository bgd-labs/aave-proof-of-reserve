// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DataTypesV2, ILendingPoolAddressesProvider, ILendingPool, ILendingPoolConfigurator} from '../interfaces/AaveV2.sol';
import {ProofOfReserveExecutorBase} from './ProofOfReserveExecutorBase.sol';
import {IProofOfReserveExecutor} from '../interfaces/IProofOfReserveExecutor.sol';
import {ReserveConfiguration} from './dependencies/helpers/ReserveConfiguration.sol';

/**
 * @author BGD Labs
 * @dev Aave V2 contract for Proof of Reserve emergency action in case of any of bridged reserves is not backed:
 * - Disables borrowing of every asset on the market, when any of them is not backed
 */
contract ProofOfReserveExecutorV2 is ProofOfReserveExecutorBase {
  // @audit Add IPoolConfigurator event that is not registered by brownie
  event ReserveFrozen(address indexed asset, bool frozen);

  // AAVE v2 pool
  ILendingPool internal immutable _pool;
  // AAVE v2 pool configurator
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
    _configurator = ILendingPoolConfigurator(addressesProvider.getLendingPoolConfigurator());
  }

  /// @inheritdoc IProofOfReserveExecutor
  function isEmergencyActionPossible() external view override returns (bool) {
    address[] memory allAssets = _pool.getReservesList();
    (, bool[] memory unbackedAssetsFlags) = _proofOfReserveAggregator.areAllReservesBacked(_assets);

    // check if unbacked reserves are not frozen
    for (uint256 i; i < _assets.length; ++i) {
      if (unbackedAssetsFlags[i]) {
        DataTypesV2.ReserveConfigurationMap memory configuration = _pool.getConfiguration(
          _assets[i]
        );

        if (!ReserveConfiguration.getIsFrozen(configuration)) {
          return true;
        }
      }
    }

    // check if borrowing is enabled for any of the reserves
    for (uint256 i; i < allAssets.length; ++i) {
      DataTypesV2.ReserveConfigurationMap memory configuration = _pool.getConfiguration(
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
    (bool areReservesBacked, bool[] memory unbackedAssetsFlags) = _proofOfReserveAggregator
      .areAllReservesBacked(_assets);

    if (!areReservesBacked) {
      _disableBorrowing();

      uint256 assetsLength = _assets.length;

      for (uint256 i = 0; i < assetsLength; ++i) {
        if (unbackedAssetsFlags[i]) {
          // freeze reserve
          _configurator.freezeReserve(_assets[i]);

          emit AssetIsNotBacked(_assets[i]);
        }
      }

      emit EmergencyActionExecuted();
    }
  }

  /**
   * @dev disable borrowing for every asset on the market.
   */
  function _disableBorrowing() internal {
    address[] memory reservesList = _pool.getReservesList();

    // disable borrowing for all the reserves on the market
    for (uint256 i = 0; i < reservesList.length; ++i) {
      _configurator.disableReserveStableRate(reservesList[i]);
      _configurator.disableBorrowingOnReserve(reservesList[i]);
    }
  }
}
