// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';

import {AaveV2Avalanche} from 'aave-address-book/AaveAddressBook.sol';
import {ProxyHelpers} from 'aave-helpers/ProxyHelpers.sol';
import {MockExecutor} from './MockExecutor.sol';
import {ConfiguratorMock} from './helpers/ConfiguratorMock.sol';
import {UpgradeAaveV2ConfiguratorPayload} from '../src/proposal/UpgradeAaveV2ConfiguratorPayload.sol';

contract UpgradeAaveV2ConfiguratorPayloadTest is Test {
  address public constant GUARDIAN = 0x01244E7842254e3FD229CD263472076B1439D1Cd;

  address public constant EXECUTOR_V2 =
    0x7fc3FCb14eF04A48Bb0c12f0c39CD74C249c37d8;

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
    ConfiguratorMock configurator = new ConfiguratorMock();

    UpgradeAaveV2ConfiguratorPayload proposal = new UpgradeAaveV2ConfiguratorPayload(
        address(configurator),
        EXECUTOR_V2
      );

    address implBefore = ProxyHelpers
      .getInitializableAdminUpgradeabilityProxyImplementation(
        vm,
        address(AaveV2Avalanche.POOL_CONFIGURATOR)
      );

    // Execute proposal
    _executor.execute(address(proposal));

    // Assert
    address implAfter = ProxyHelpers
      .getInitializableAdminUpgradeabilityProxyImplementation(
        vm,
        address(AaveV2Avalanche.POOL_CONFIGURATOR)
      );
    // implementation should change
    assertTrue(implBefore != implAfter);

    // check that executorV2 is proof of reserve admin
    address proofOfReserveAdmin = AaveV2Avalanche
      .POOL_ADDRESSES_PROVIDER
      .getAddress('PROOF_OF_RESERVE_ADMIN');
    assertEq(proofOfReserveAdmin, EXECUTOR_V2);
  }
}
