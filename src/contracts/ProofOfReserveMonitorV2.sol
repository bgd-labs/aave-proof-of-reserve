// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IProofOfReserveMonitor} from '../interfaces/IProofOfReserveMonitor.sol';
import {ProofOfReserveMonitorBase} from './ProofOfReserveMonitorBase.sol';
import {IPool} from '../dependencies/IPool.sol';
import {IPoolAddressProvider} from '../dependencies/IPoolAddressProvider.sol';
import {IPoolConfigurator} from '../dependencies/IPoolConfigurator.sol';

/**
 * @author BGD Labs
 * @dev Contract to disable the borrowing for every asset listed on the AAVE V2 Pool,
 * when at least one of the monitored bridged assets is not backed.
 */
contract ProofOfReserveMonitorBaseV2 is ProofOfReserveMonitorBase {
  // AAVE v2 pool
  IPool internal _pool;

  /**
   * @notice Constructor.
   * @param poolAddress The address of the Aave's V2 pool
   */
  constructor(address poolAddress, address proofOfReserveAddress)
    ProofOfReserveMonitorBase(proofOfReserveAddress)
  {
    _pool = IPool(poolAddress);
  }

  /// @inheritdoc IProofOfReserveMonitor
  function executeEmergencyAction() public {
    (bool result, bool[] memory unbackedAssetsFlags) = _proofOfReserve
      .areAllReservesBacked(_assets);

    if (!result) {
      address[] memory reservesList = _pool.getReservesList();

      IPoolAddressProvider addressProvider = _pool.getAddressesProvider();
      IPoolConfigurator configurator = IPoolConfigurator(
        addressProvider.getLendingPoolConfigurator()
      );

      for (uint256 i = 0; i < reservesList.length; i++) {
        configurator.disableBorrowingOnReserve(reservesList[i]);
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
