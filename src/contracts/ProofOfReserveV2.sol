// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAaveProofOfReserve} from '../interfaces/IAaveProofOfReserve.sol';
import {ProofOfReserve} from './ProofOfReserve.sol';
import {IPool} from '../dependencies/IPool.sol';
import {IPoolAddressProvider} from '../dependencies/IPoolAddressProvider.sol';
import {IPoolConfigurator} from '../dependencies/IPoolConfigurator.sol';

contract ProofOfReserveV2 is ProofOfReserve, IAaveProofOfReserve {
  function executeEmergencyAction(IPool pool) public {
    if (!_areAllReservesBacked()) {
      address[] memory reservesList = pool.getReservesList();

      IPoolAddressProvider addressProvider = pool.getAddressesProvider();
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
