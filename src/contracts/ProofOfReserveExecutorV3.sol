// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IProofOfReserveExecutor} from '../interfaces/IProofOfReserveExecutor.sol';
import {ProofOfReserveExecutorBase} from './ProofOfReserveExecutorBase.sol';
import {IPool} from '../dependencies/IPool.sol';
import {IPoolAddressProvider} from '../dependencies/IPoolAddressProvider.sol';
import {IPoolConfigurator} from '../dependencies/IPoolConfigurator.sol';

/**
 * @author BGD Labs
 * @dev Contract to disable the borrowing for every asset listed on the AAVE V2 Pool,
 * when at least one of the bridged assets is not backed.
 */
contract ProofOfReserveExecutorV3 is ProofOfReserveExecutorBase {
  // AAVE v3 pool
  IPool internal _pool;

  /**
   * @notice Constructor.
   * @param poolAddress The address of the Aave's V3 pool
   */
  constructor(address poolAddress, address proofOfReserveAddress)
    ProofOfReserveExecutorBase(proofOfReserveAddress)
  {
    _pool = IPool(poolAddress);
  }

  /// @inheritdoc IProofOfReserveExecutor
  function executeEmergencyAction() public {
    (bool result, bool[] memory unbackedAssetsFlags) = _proofOfReserve
      .areAllReservesBacked(_assets);

    if (!result) {
      address[] memory reservesList = _pool.getReservesList();

      IPoolAddressProvider addressProvider = _pool.ADDRESSES_PROVIDER();
      IPoolConfigurator configurator = IPoolConfigurator(
        addressProvider.getPoolConfigurator()
      );

      for (uint256 i = 0; i < reservesList.length; i++) {
        configurator.setReserveBorrowing(reservesList[i], false);
      }

      for (uint256 i = 0; i < _assets.length; i++) {
        if (unbackedAssetsFlags[i]) {
          emit AssetIsNotBacked(_assets[i]);
        }
      }

      emit EmergencyActionExecuted(msg.sender);
    }
  }
}
