// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAaveProofOfReserve} from '../interfaces/IAaveProofOfReserve.sol';
import {ProofOfReserve} from './ProofOfReserve.sol';
import {IPool} from '../dependencies/IPool.sol';
import {IPoolAddressProvider} from '../dependencies/IPoolAddressProvider.sol';
import {IPoolConfigurator} from '../dependencies/IPoolConfigurator.sol';

contract ProofOfReserve is ProofOfReserve, IAaveProofOfReserve {
  function executeEmergencyAction(IPool pool) public {
    if (!_areAllReservesBacked()) {
      address[] memory reservesList = pool.getReservesList();

      IPoolAddressProvider addressProvider = pool.ADDRESSES_PROVIDER();
      IPoolConfigurator configurator = IPoolConfigurator(
        addressProvider.getPoolConfigurator()
      );

      for (uint256 i = 0; i < reservesList.length; i++) {
        configurator.setReserveBorrowing(reservesList[i], false);
      }

      // TODO: emit event for every unbacked reserve
      emit EmergencyActionExecuted(msg.sender);
    }
  }
}
