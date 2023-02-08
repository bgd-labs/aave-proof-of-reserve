// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';

import {AaveV2Avalanche, AaveV3Avalanche} from 'aave-address-book/AaveAddressBook.sol';
import {ProxyHelpers} from 'aave-helpers/ProxyHelpers.sol';
import {MockExecutor} from './MockExecutor.sol';
import {ConfiguratorMock} from './helpers/ConfiguratorMock.sol';
import {UpgradeV2ConfiguratorImplPayload} from '../src/proposal/UpgradeV2ConfiguratorImplPayload.sol';

contract UpgradeV2ConfiguratorImplPayloadTest is Test {
  address public constant GUARDIAN = 0xa35b76E4935449E33C56aB24b23fcd3246f13470;

  address public constant AGGREGATOR =
    0x80f2c02224a2E548FC67c0bF705eBFA825dd5439;

  address public constant EXECUTOR_V2 =
    0x7fc3FCb14eF04A48Bb0c12f0c39CD74C249c37d8;

  address public constant EXECUTOR_V3 =
    0xab22988D93d5F942fC6B6c6Ea285744809D1d9Cc;

  address public constant POOL_CONFIGURATOR =
    0xC383AAc4B3dC18D9ce08AB7F63B4632716F1e626;

  MockExecutor internal _executor;

  event ChainlinkUpkeepRegistered(
    string indexed name,
    uint256 indexed upkeedId
  );

  function setUp() public {
    vm.createSelectFork('avalanche', 26003116);

    MockExecutor mockExecutor = new MockExecutor();
    vm.etch(GUARDIAN, address(mockExecutor).code);

    _executor = MockExecutor(GUARDIAN);
  }

  function testExecuteProposal() public {
    UpgradeV2ConfiguratorImplPayload proposal = new UpgradeV2ConfiguratorImplPayload(
        AGGREGATOR,
        EXECUTOR_V2,
        EXECUTOR_V3,
        POOL_CONFIGURATOR
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

    // check that aggregator's address was added to v2 addresses provider
    address proofOfReserveAggregator = AaveV2Avalanche
      .POOL_ADDRESSES_PROVIDER
      .getAddress('PROOF_OF_RESERVE_AGGREGATOR');
    assertEq(proofOfReserveAggregator, AGGREGATOR);

    // check that aggregator's address was added to v2 addresses provider
    address proofOfReserveExecutor = AaveV2Avalanche
      .POOL_ADDRESSES_PROVIDER
      .getAddress('PROOF_OF_RESERVE_EXECUTOR');
    assertEq(proofOfReserveExecutor, EXECUTOR_V2);

    // check that aggregator's address was added to v3 addresses provider
    proofOfReserveAggregator = AaveV3Avalanche
      .POOL_ADDRESSES_PROVIDER
      .getAddress('PROOF_OF_RESERVE_AGGREGATOR');
    assertEq(proofOfReserveAggregator, AGGREGATOR);

    // check that aggregator's address was added to v3 addresses provider
    proofOfReserveExecutor = AaveV3Avalanche.POOL_ADDRESSES_PROVIDER.getAddress(
        'PROOF_OF_RESERVE_EXECUTOR'
      );
    assertEq(proofOfReserveExecutor, EXECUTOR_V3);
  }
}
