// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;
import {Test} from 'forge-std/Test.sol';

import {ICollectorController} from '../src/dependencies/ICollectorController.sol';
import {ProposalPayloadProofOfReserve} from '../src/proposal/ProposalPayloadProofOfReserve.sol';
import {ProofOfReserveAggregator} from '../src/contracts/ProofOfReserveAggregator.sol';
import {ProofOfReserveExecutorV2} from '../src/contracts/ProofOfReserveExecutorV2.sol';
import {ProofOfReserveExecutorV3} from '../src/contracts/ProofOfReserveExecutorV3.sol';
import {ProofOfReserveKeeper} from '../src/contracts/ProofOfReserveKeeper.sol';
import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {AaveV2Avalanche, AaveV3Avalanche} from 'aave-address-book/AaveAddressBook.sol';
import {BaseProxy} from './helpers/BaseProxy.sol';

contract ProposalPayloadProofOfReserveTest is Test {
  uint256 private avalancheFork;
  address public constant GUARDIAN =
    address(0xa35b76E4935449E33C56aB24b23fcd3246f13470);

  function setUp() public {
    avalancheFork = vm.createFork('https://api.avax.network/ext/bc/C/rpc');
    vm.selectFork(avalancheFork);
  }

  function testExecute() public {
    // deploy all contracts
    ProofOfReserveAggregator aggregator = new ProofOfReserveAggregator();
    ProofOfReserveExecutorV2 executorV2 = new ProofOfReserveExecutorV2(
      address(AaveV2Avalanche.POOL_ADDRESSES_PROVIDER),
      address(aggregator)
    );
    ProofOfReserveExecutorV3 executorV3 = new ProofOfReserveExecutorV3(
      address(AaveV3Avalanche.POOL_ADDRESSES_PROVIDER),
      address(aggregator)
    );
    ProofOfReserveKeeper keeper = new ProofOfReserveKeeper();

    // deploy proposal
    ProposalPayloadProofOfReserve proposal = new ProposalPayloadProofOfReserve(
      AaveV2Avalanche.POOL_ADDRESSES_PROVIDER.getLendingPoolConfigurator(),
      address(aggregator),
      address(executorV2),
      address(executorV3),
      address(keeper)
    );

    // transfer ownership to proposal
    aggregator.transferOwnership(address(proposal));
    executorV2.transferOwnership(address(proposal));
    executorV3.transferOwnership(address(proposal));
    // TODO: transfer collectorController ownership to proposal

    // currently v2 pool address provider has other owner
    vm.startPrank(address(0x01244E7842254e3FD229CD263472076B1439D1Cd));

    // trasfer v2 Addreess Provider ownership to proposal
    // TODO: check owner of immutable proxy
    Ownable(address(AaveV2Avalanche.POOL_ADDRESSES_PROVIDER)).transferOwnership(
        address(proposal)
      );

    // vm.stopPrank();
    // check that GUARDIAN is v3 risk admin and set risk admin to proposal
    // vm.startPrank(GUARDIAN);

    // GUARDIAN is not v3 risk admin, should be added inside proposal (and then removed)
    // AaveV3Avalanche.ACL_MANAGER.setRoleAdmin(address(proposal));
    // assertTrue(AaveV3Avalanche.ACL_MANAGER.isRiskAdmin(GUARDIAN));

    // check that GUARDIAN is the owner of the Collector Controller and transfer ownership to proposal
    // assertEq(GUARDIAN, Ownable(AaveV3Avalanche.COLLECTOR_CONTROLLER).owner());
    // Ownable(AaveV3Avalanche.COLLECTOR_CONTROLLER).transferOwnership(
    //   address(proposal)
    // );

    // vm.stopPrank();

    // Execute proposal
    // proposal.execute();
  }

  // function setRiskAdmin(address proposalAddress) private {
  //   IPoolAddressesProvider addressesProvider = IPoolAddressesProvider(
  //     ADDRESS_PROVIDER
  //   );
  //   IACLManager aclManager = IACLManager(addressesProvider.getACLManager());
  //   aclManager.addRiskAdmin(proposalAddress);
  // }
}

// check:
// 	1) assets/PoR are enabled in aggregator
// 	2) assets are enabled in aggregator v2
// 	3) assets are enabled in aggregator v3
// 	4) LendingPoolConfigurator is upgraded
// 	5) ExecutorV2 is PROOF_OF_RESERVE_ADMIN
// 	6) ExecutorV3 has risk admin role
// 	7) UpkeepV2 created
// 	8) UpkeepV3 created

// 	9) call something ?
