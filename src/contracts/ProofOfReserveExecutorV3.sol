// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IProofOfReserveExecutor} from '../interfaces/IProofOfReserveExecutor.sol';
import {ProofOfReserveExecutorBase} from './ProofOfReserveExecutorBase.sol';
import {IPool} from '../dependencies/IPool.sol';
import {IPoolAddressProvider} from '../dependencies/IPoolAddressProvider.sol';
import {IPoolConfigurator} from '../dependencies/IPoolConfigurator.sol';

/**
 * @author BGD Labs
 * @dev Aave V3 contract for Proof of Reserve emergency action in case of any of bridged reserves is not backed:
 * - Disables borrowing of every asset on the market, when any of them is not backed
 */
contract ProofOfReserveExecutorV3 is ProofOfReserveExecutorBase {
  // AAVE v3 pool
  IPoolAddressProvider internal _addressProvider;

  /**
   * @notice Constructor.
   * @param poolAddressProviderAddress The address of the Aave's V3 pool address provider
   */
  constructor(address poolAddressProviderAddress, address proofOfReserveAddress)
    ProofOfReserveExecutorBase(proofOfReserveAddress)
  {
    _addressProvider = IPoolAddressProvider(poolAddressProviderAddress);
  }

  /// @inheritdoc IProofOfReserveExecutor
  function executeEmergencyAction() public {
    (
      bool areAllReservesbacked,
      bool[] memory unbackedAssetsFlags
    ) = _proofOfReserveAggregator.areAllReservesBacked(_assets);

    if (!areAllReservesbacked) {
      IPool pool = IPool(_addressProvider.getPool());
      address[] memory reservesList = pool.getReservesList();

      IPoolConfigurator configurator = IPoolConfigurator(
        _addressProvider.getPoolConfigurator()
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
