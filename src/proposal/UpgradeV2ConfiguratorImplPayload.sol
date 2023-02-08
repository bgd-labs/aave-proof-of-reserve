// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV2Avalanche} from 'aave-address-book/AaveAddressBook.sol';

/**
 * @title UpgradeV2ConfiguratorImplPayload
 * @author BGD Labs
 * @dev Proposal to update LendingPoolConfigurator impl and enable ExecutorV2 as the proofOfReserve admin for V2
 * - V2: upgrade implementation of LendingPoolConfigurator to enable new PROOF_OF_RESERVE_ADMIN role usage
 * - V2: assign PROOF_OF_RESERVE_ADMIN role to ProofOfReserveExecutorV2 in AddressProvider
 * Governance Forum Post: https://governance.aave.com/t/bgd-aave-chainlink-proof-of-reserve-phase-1-release-candidate/10972
 * Snapshot: https://snapshot.org/#/aave.eth/proposal/0x546ead37609b3f23c11559fe90e798b725af755f402bdd77e37583b4186d1f29
 */

contract UpgradeV2ConfiguratorImplPayload {
  address public immutable POOL_CONFIGURATOR;
  address public immutable EXECUTOR_V2;
  bytes32 public constant PROOF_OF_RESERVE_ADMIN = 'PROOF_OF_RESERVE_ADMIN';

  constructor(address poolConfigurator, address executorV2) {
    POOL_CONFIGURATOR = poolConfigurator;
    EXECUTOR_V2 = executorV2;
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
  }
}
