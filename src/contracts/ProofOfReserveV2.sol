// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAaveProofOfReserve} from '../interfaces/IAaveProofOfReserve.sol';
import {ProofOfReserve} from './ProofOfReserve.sol';
import {IPool} from '../dependencies/IPool.sol';
import {IPoolAddressProvider} from '../dependencies/IPoolAddressProvider.sol';
import {IPoolConfigurator} from '../dependencies/IPoolConfigurator.sol';

/**
 * @author BGD Labs
 * @dev Contract to disable the borrowing for every asset listed on the AAVE V2 Pool,
 * when at least one of the bridged assets is not backed.
 */
contract ProofOfReserveV2 is ProofOfReserve {
  // AAVE v2 pool
  IPool internal _pool;

  /**
   * @notice Constructor.
   * @param poolAddress The address of the Aave's V2 pool
   */
  constructor(address poolAddress) {
    _pool = IPool(poolAddress);
  }

  /// @inheritdoc IAaveProofOfReserve
  function executeEmergencyAction() public {
    if (!areAllReservesBacked()) {
      address[] memory reservesList = _pool.getReservesList();

      IPoolAddressProvider addressProvider = _pool.getAddressesProvider();
      IPoolConfigurator configurator = IPoolConfigurator(
        addressProvider.getLendingPoolConfigurator()
      );

      for (uint256 i = 0; i < reservesList.length; i++) {
        configurator.disableBorrowingOnReserve(reservesList[i]);
      }

      emit EmergencyActionExecuted(msg.sender);
    }
  }
}
