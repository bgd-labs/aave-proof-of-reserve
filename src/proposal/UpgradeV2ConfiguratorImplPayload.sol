// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV2Avalanche, AaveV3Avalanche} from 'aave-address-book/AaveAddressBook.sol';

/**
 * @title UpgradeV2ConfiguratorImplPayload
 * @author BGD Labs
 * @dev Proposal to update LendingPoolConfigurator impl and enable ExecutorV2 as the proofOfReserve admin for V2
 * - V2: upgrade implementation of LendingPoolConfigurator to enable new PROOF_OF_RESERVE_ADMIN role usage
 * - V2: assign PROOF_OF_RESERVE_ADMIN role to ProofOfReserveExecutorV2 in AddressProvider
 * - V2: set address of the Aggregator and Executor in AddressProvider
 * - V3: set address of the Aggregator and Executor in AddressProvider
 * Governance Forum Post: https://governance.aave.com/t/bgd-aave-chainlink-proof-of-reserve-phase-1-release-candidate/10972
 * Snapshot: https://snapshot.org/#/aave.eth/proposal/0x546ead37609b3f23c11559fe90e798b725af755f402bdd77e37583b4186d1f29
 */

contract UpgradeV2ConfiguratorImplPayload {
  address public immutable POOL_CONFIGURATOR;
  address public immutable AGGREGATOR;
  address public immutable EXECUTOR_V2;
  address public immutable EXECUTOR_V3;

  bytes32 public constant PROOF_OF_RESERVE_ADMIN = 'PROOF_OF_RESERVE_ADMIN';
  bytes32 public constant PROOF_OF_RESERVE_AGGREGATOR =
    'PROOF_OF_RESERVE_AGGREGATOR';
  bytes32 public constant PROOF_OF_RESERVE_EXECUTOR =
    'PROOF_OF_RESERVE_EXECUTOR';

  constructor(
    address poolConfigurator,
    address aggregator,
    address executorV2,
    address executorV3
  ) {
    POOL_CONFIGURATOR = poolConfigurator;
    AGGREGATOR = aggregator;
    EXECUTOR_V2 = executorV2;
    EXECUTOR_V3 = executorV3;
  }

  function execute() external {
    // set the new implementation for Pool Configurator to enable PROOF_OF_RESERVE_ADMIN
    AaveV2Avalanche.POOL_ADDRESSES_PROVIDER.setLendingPoolConfiguratorImpl(
      POOL_CONFIGURATOR
    );

    // set ProofOfReserveExecutorV2 as PROOF_OF_RESERVE_ADMIN
    AaveV2Avalanche.POOL_ADDRESSES_PROVIDER.setAddress(
      PROOF_OF_RESERVE_ADMIN,
      EXECUTOR_V2
    );

    // set the address of the Aggregator for V2
    AaveV2Avalanche.POOL_ADDRESSES_PROVIDER.setAddress(
      PROOF_OF_RESERVE_AGGREGATOR,
      AGGREGATOR
    );

    // set the address of the V2 Executor
    AaveV2Avalanche.POOL_ADDRESSES_PROVIDER.setAddress(
      PROOF_OF_RESERVE_EXECUTOR,
      EXECUTOR_V2
    );

    // set the address of the Aggregator for V3
    AaveV3Avalanche.POOL_ADDRESSES_PROVIDER.setAddress(
      PROOF_OF_RESERVE_AGGREGATOR,
      AGGREGATOR
    );

    // set address of the V3 Executor
    AaveV3Avalanche.POOL_ADDRESSES_PROVIDER.setAddress(
      PROOF_OF_RESERVE_EXECUTOR,
      EXECUTOR_V3
    );
  }
}
