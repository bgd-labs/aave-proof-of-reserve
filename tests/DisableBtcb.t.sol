// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;
import {Test} from 'forge-std/Test.sol';

import {MockExecutor} from './MockExecutor.sol';
import {AaveV3Avalanche} from 'aave-address-book/AaveAddressBook.sol';
import {DataTypes} from 'aave-address-book/AaveV3.sol';
import {IProofOfReserveExecutor} from '../src/interfaces/IProofOfReserveExecutor.sol';
import {DisableBtcbPayload} from '../src/proposal/DisableBtcbPayload.sol';
import {ReserveConfiguration} from '../src/helpers/ReserveConfiguration.sol';

contract DisableExecutorRestoreBtcbTest is Test {
  address public constant GUARDIAN = 0xa35b76E4935449E33C56aB24b23fcd3246f13470;
  address public constant BTCB = 0x152b9d0FdC40C096757F570A51E494bd4b943E50;
  IProofOfReserveExecutor public constant EXECUTOR_V2 =
    IProofOfReserveExecutor(0x7fc3FCb14eF04A48Bb0c12f0c39CD74C249c37d8);
  IProofOfReserveExecutor public constant EXECUTOR_V3 =
    IProofOfReserveExecutor(0xab22988D93d5F942fC6B6c6Ea285744809D1d9Cc);

  MockExecutor internal _executor;

  function setUp() public {
    vm.createSelectFork('avalanche', 25781062); // when BTC.b is disabled

    MockExecutor mockExecutor = new MockExecutor();
    vm.etch(GUARDIAN, address(mockExecutor).code);

    _executor = MockExecutor(GUARDIAN);
  }

  function testExecuteProposal() public {
    DisableBtcbPayload proposal = new DisableBtcbPayload();

    // Execute proposal
    _executor.execute(address(proposal));

    // Check that BTC.b is not frozen and that LTV is fine
    (uint256 ltv, bool isFrozen) = getLtvAndIsFrozen(BTCB);

    assertTrue(ltv == 7000);
    assertTrue(!isFrozen);

    address[] memory v2assets = EXECUTOR_V2.getAssets();

    for (uint256 i; i < v2assets.length; ++i) {
      assertTrue(v2assets[i] != BTCB);
    }

    address[] memory v3assets = EXECUTOR_V3.getAssets();

    for (uint256 i; i < v3assets.length; ++i) {
      assertTrue(v3assets[i] != BTCB);
    }
  }

  function getLtvAndIsFrozen(address asset)
    private
    view
    returns (uint256, bool)
  {
    DataTypes.ReserveConfigurationMap memory configuration = AaveV3Avalanche
      .POOL
      .getConfiguration(asset);

    (uint256 ltv, , , bool isFrozen) = ReserveConfiguration.getReserveParams(
      configuration
    );

    return (ltv, isFrozen);
  }
}
