pragma solidity ^0.8.0;

import {LinkTokenInterface} from 'chainlink-brownie-contracts/interfaces/LinkTokenInterface.sol';
import {KeeperRegistryInterface, Config, State} from 'chainlink-brownie-contracts/interfaces/KeeperRegistryInterface.sol';
import {KeeperRegistrarInterface} from './KeeperRegistrarInterface.sol';
import {ILendingPoolAddressesProvider} from 'aave-address-book/AaveV2.sol';
import {IACLManager} from 'aave-address-book/AaveV3.sol';
import {IProofOfReserveAggregator} from '../interfaces/IProofOfReserveAggregator.sol';
import {IProofOfReserveExecutor} from '../interfaces/IProofOfReserveExecutor.sol';
import {ICollectorController} from '../dependencies/ICollectorController.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {AaveV2Avalanche, AaveV3Avalanche} from 'aave-address-book/AaveAddressBook.sol';

/**
 * @title UpgradeAaveV2ConfiguratorPayload
 * @author BGD Labs
 * @dev Proposal to deploy Proof Of Reserve and enable it as proofOfReserve admin for V2 and risk admin for V3.
 * - V2: upgrade implementation of LendingPoolConfigurator to enable new PROOF_OF_RESERVE_ADMIN role usage
 * - V2: assign PROOF_OF_RESERVE_ADMIN role to ProofOfReserveExecutorV2 in AddressProvider
 */

contract ProposalPayloadProofOfReserve {
  address public constant LENDING_POOL_CONFIGURATOR_IMPL = address(0);
  address public constant EXECUTOR_V2 = address(0);
  bytes32 public constant PROOF_OF_RESERVE_ADMIN = 'PROOF_OF_RESERVE_ADMIN';

  function execute() external {
    // set the new implementation for Pool Configurator to enable PROOF_OF_RESERVE_ADMIN
    AaveV2Avalanche.POOL_ADDRESSES_PROVIDER.setLendingPoolConfiguratorImpl(
      LENDING_POOL_CONFIGURATOR_IMPL
    );

    // set ProofOfReserveExecutorV2 as PROOF_OF_RESERVE_ADMIN
    AaveV2Avalanche.POOL_ADDRESSES_PROVIDER.setAddress(
      PROOF_OF_RESERVE_ADMIN,
      address(EXECUTOR_V2)
    );
  }
}
