// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;
import {Test} from 'forge-std/Test.sol';

import {ICollectorController} from '../src/dependencies/ICollectorController.sol';
import {Deploy} from '../scripts/DeployProofOfReserveAvax.s.sol';
import {MockExecutor} from './MockExecutor.sol';
import {ConfiguratorMock} from './helpers/ConfiguratorMock.sol';
import {AaveV2Avalanche} from 'aave-address-book/AaveAddressBook.sol';

contract ProposalPayloadProofOfReserveTest is Test {
  address public constant GUARDIAN =
    address(0x01244E7842254e3FD229CD263472076B1439D1Cd);

  MockExecutor internal _executor;

  event ChainlinkUpkeepRegistered(
    string indexed name,
    uint256 indexed upkeedId
  );

  function setUp() public {
    vm.createSelectFork('avalanche', 23712421);

    MockExecutor mockExecutor = new MockExecutor();
    vm.etch(GUARDIAN, address(mockExecutor).code);

    _executor = MockExecutor(GUARDIAN);
  }

  function testExecuteProposal() public {
    // deploy all contracts
    Deploy script = new Deploy();
    script.deployContracts();

    address executorV2 = address(script.executorV2());
    address proposal = script.upgradeV2ConfigurtorAddress();

    // Execute proposal
    _executor.execute(address(proposal));

    // Assert
    address proofOfReserveAdmin = AaveV2Avalanche
      .POOL_ADDRESSES_PROVIDER
      .getAddress('PROOF_OF_RESERVE_ADMIN');
    assertEq(proofOfReserveAdmin, executorV2);
    // check that impl is different
    // check that executorV2 is admin
  }
}
