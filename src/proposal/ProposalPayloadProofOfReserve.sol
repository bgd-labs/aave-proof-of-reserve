// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV2Avalanche, AaveV3Avalanche} from 'aave-address-book/AaveAddressBook.sol';
import {ILendingPoolAddressesProvider} from 'aave-address-book/AaveV2.sol';
import {IACLManager} from 'aave-address-book/AaveV3.sol';
import {IProofOfReserveAggregator} from '../interfaces/IProofOfReserveAggregator.sol';
import {IProofOfReserveExecutor} from '../interfaces/IProofOfReserveExecutor.sol';
import {StewardBase} from './StewardBase.sol';

/**
 * @title ProposalPayloadProofOfReserve
 * @author BGD Labs
 * @dev Proposal to deploy Proof Of Reserve and enable it as proofOfReserve admin for V2 and risk admin for V3.
 * - Add tokens and their proof of reserves to registry
 * - V2: upgrade implementation of LendingPoolConfigurator to enable new PROOF_OF_RESERVE_ADMIN role usage
 * - V2: assign PROOF_OF_RESERVE_ADMIN role to ProofOfReserveExecutorV2
 * - V2: enable tokens for checking against their proof of reserfe feed
 * - V3: assign Risk admin role to ProofOfReserveExecutorV3
 * - V3: enable tokens for checking against their proof of reserfe feed
 */

contract ProposalPayloadProofOfReserve is StewardBase {
  bytes32 public constant PROOF_OF_RESERVE_ADMIN = 'PROOF_OF_RESERVE_ADMIN';

  address public constant LENDING_POOL_CONFIGURATOR_IMPL = address(0);
  address public constant PROOF_OF_RESERVE_AGGREGATOR = address(0);
  address public constant PROOF_OF_RESERVE_EXECUTOR_V2 = address(0);
  address public constant PROOF_OF_RESERVE_EXECUTOR_V3 = address(0);

  address[] public ASSETS = [address(0), address(1)];
  address[] public PROOF_OF_RESERVE_FEEDS = [address(10), address(11)];

  function execute()
    external
    withRennounceOfAllAavePermissions(AaveV3Avalanche.ACL_MANAGER)
    withOwnershipBurning
    onlyOwner
  {
    // Aggregator
    IProofOfReserveAggregator aggregator = IProofOfReserveAggregator(
      PROOF_OF_RESERVE_AGGREGATOR
    );

    for (uint256 i; i < ASSETS.length; i++) {
      aggregator.enableProofOfReserveFeed(ASSETS[i], PROOF_OF_RESERVE_FEEDS[i]);
    }

    // V2
    ILendingPoolAddressesProvider addressesProvider = AaveV2Avalanche
      .POOL_ADDRESSES_PROVIDER;

    // set new implementation for pool configurator
    addressesProvider.setLendingPoolConfiguratorImpl(
      LENDING_POOL_CONFIGURATOR_IMPL
    );

    // set executor v2 as proof of reserve admin
    addressesProvider.setAddress(
      PROOF_OF_RESERVE_ADMIN,
      PROOF_OF_RESERVE_EXECUTOR_V2
    );
    IProofOfReserveExecutor executorV2 = IProofOfReserveExecutor(
      PROOF_OF_RESERVE_EXECUTOR_V2
    );

    // enable asset to be validated by proof of reserve
    for (uint256 i; i < ASSETS.length; i++) {
      executorV2.enableAsset(ASSETS[i]);
    }

    // V3
    IACLManager aclManager = AaveV3Avalanche.ACL_MANAGER;

    aclManager.addRiskAdmin(PROOF_OF_RESERVE_EXECUTOR_V3);

    IProofOfReserveExecutor executorV3 = IProofOfReserveExecutor(
      PROOF_OF_RESERVE_EXECUTOR_V3
    );

    // enable assets to be validated by proof of reserve
    for (uint256 i; i < ASSETS.length; i++) {
      executorV3.enableAsset(ASSETS[i]);
    }
  }
}
