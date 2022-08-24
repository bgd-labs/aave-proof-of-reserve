// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'chainlink-brownie-contracts/KeeperCompatible.sol';
//
import {IProofOfReserveExecutor} from '../interfaces/IProofOfReserveExecutor.sol';

/**
 * @author BGD Labs
 * @dev Aave chainlink keeper-compatible contract for proof of reserve:
 * - checks in simulation whether all reserves are backed
 * - executes emergency action for market
 */
contract ProofOfReserveKeeper is KeeperCompatibleInterface {
  /**
   * @dev run off-chain, checks if all reserves are backed on passed market and decides whether to run emergency action on-chain
   * @param checkData address of the ProofOfReserveExecutor contract
   */
  function checkUpkeep(bytes calldata checkData)
    external
    view
    override
    returns (bool, bytes memory)
  {
    address executorAddress = abi.decode(checkData, (address));
    IProofOfReserveExecutor proofOfreserveExecutor = IProofOfReserveExecutor(
      executorAddress
    );

    if (!proofOfreserveExecutor.areAllReservesBacked()) {
      return (true, checkData);
    }

    return (false, checkData);
  }

  /**
   * @dev if not all reserves are backed - executes emergency action for the market
   * @param performData address of the ProofOfReserveExecutor contract
   */
  function performUpkeep(bytes calldata performData) external override {
    address executorAddress = abi.decode(performData, (address));

    IProofOfReserveExecutor proofOfreserveExecutor = IProofOfReserveExecutor(
      executorAddress
    );

    if (!proofOfreserveExecutor.areAllReservesBacked()) {
      proofOfreserveExecutor.executeEmergencyAction();
    }
  }
}
