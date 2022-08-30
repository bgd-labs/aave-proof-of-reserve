// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IProofOfReserveExecutor} from '../interfaces/IProofOfReserveExecutor.sol';
import {ProofOfReserveExecutorBase} from './ProofOfReserveExecutorBase.sol';
import {IPool, ReserveConfigurationMap} from '../dependencies/IPool.sol';
import {IPoolAddressProvider} from '../dependencies/IPoolAddressProvider.sol';
import {IPoolConfigurator} from '../dependencies/IPoolConfigurator.sol';
import {ReserveConfiguration} from '../helpers/ReserveConfiguration.sol';

/**
 * @author BGD Labs
 * @dev Aave V2 contract for Proof of Reserve emergency action in case of any of bridged reserves is not backed:
 * - Disables borrowing of every asset on the market, when any of them is not backed
 */
contract ProofOfReserveExecutorV2 is ProofOfReserveExecutorBase {
  // AAVE v2 pool
  IPoolAddressProvider internal _addressProvider;

  /**
   * @notice Constructor.
   * @param poolAddressProviderAddress The address of the Aave's V2 pool address provider
   */
  constructor(address poolAddressProviderAddress, address proofOfReserveAddress)
    ProofOfReserveExecutorBase(proofOfReserveAddress)
  {
    _addressProvider = IPoolAddressProvider(poolAddressProviderAddress);
  }

  /// @inheritdoc IProofOfReserveExecutor
  function isBorrowingEnabledForAtLeastOneAsset() external view returns (bool) {
    IPool pool = IPool(_addressProvider.getLendingPool());
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
  function executeEmergencyAction() public {
    (
      bool areAllReservesbacked,
      bool[] memory unbackedAssetsFlags
    ) = _proofOfReserveAggregator.areAllReservesBacked(_assets);

    if (!areAllReservesbacked) {
      IPool pool = IPool(_addressProvider.getLendingPool());
      address[] memory reservesList = pool.getReservesList();

      IPoolConfigurator configurator = IPoolConfigurator(
        _addressProvider.getLendingPoolConfigurator()
      );

      for (uint256 i = 0; i < reservesList.length; i++) {
        configurator.disableReserveStableRate(reservesList[i]);
        configurator.disableBorrowingOnReserve(reservesList[i]);
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
