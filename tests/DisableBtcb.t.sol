// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;
import {Test} from 'forge-std/Test.sol';

import {MockExecutor} from './MockExecutor.sol';
import {ProtocolV3TestBase} from 'aave-helpers/ProtocolV3TestBase.sol';
import {TestWithExecutor} from 'aave-helpers/GovHelpers.sol';
import {AaveV3Avalanche} from 'aave-address-book/AaveAddressBook.sol';
import {DataTypes} from 'aave-address-book/AaveV3.sol';
import {IProofOfReserveExecutor} from '../src/interfaces/IProofOfReserveExecutor.sol';
import {DisableBtcbPayload} from '../src/proposal/DisableBtcbPayload.sol';
import {ReserveConfiguration} from '../src/helpers/ReserveConfiguration.sol';

contract DisableExecutorRestoreBtcbTest is
  ProtocolV3TestBase,
  TestWithExecutor
{
  address public constant BTCB = 0x152b9d0FdC40C096757F570A51E494bd4b943E50;
  IProofOfReserveExecutor public constant EXECUTOR_V2 =
    IProofOfReserveExecutor(0x7fc3FCb14eF04A48Bb0c12f0c39CD74C249c37d8);
  IProofOfReserveExecutor public constant EXECUTOR_V3 =
    IProofOfReserveExecutor(0xab22988D93d5F942fC6B6c6Ea285744809D1d9Cc);

  function setUp() public {
    vm.createSelectFork('avalanche', 25781062); // when BTC.b is disabled

    _selectPayloadExecutor(AaveV3Avalanche.ACL_ADMIN);
  }

  function testExecuteProposal() public {
    DisableBtcbPayload proposal = new DisableBtcbPayload();

    // Check that BTC.b is not frozen and that LTV is fine
    (
      uint256 preLtv,
      uint256 preLiquidationThreshold,
      uint256 preLiquidationBonus,
      bool preIsFrozen
    ) = getReserveParams(BTCB);

    // Execute proposal
    _executePayload(address(proposal));

    // Check that BTC.b is not frozen and that LTV is fine
    (
      uint256 ltv,
      uint256 liquidationThreshold,
      uint256 liquidationBonus,
      bool isFrozen
    ) = getReserveParams(BTCB);

    assertTrue(ltv == 7000);
    assertTrue(!isFrozen);
    assertEq(preLiquidationThreshold, liquidationThreshold);
    assertEq(preLiquidationBonus, liquidationBonus);

    address[] memory v2assets = EXECUTOR_V2.getAssets();

    for (uint256 i; i < v2assets.length; ++i) {
      assertTrue(v2assets[i] != BTCB);
    }

    address[] memory v3assets = EXECUTOR_V3.getAssets();

    for (uint256 i; i < v3assets.length; ++i) {
      assertTrue(v3assets[i] != BTCB);
    }
  }

  function testSnpashotBeforePoRActivation() public {
    DisableBtcbPayload proposal = new DisableBtcbPayload();

    _executePayload(address(proposal));

    this.createConfigurationSnapshot(
      'post-restore-btc-b',
      AaveV3Avalanche.POOL
    );

    // before PoR was activated
    vm.rollFork(25705929);

    this.createConfigurationSnapshot(
      'pre-por-activation',
      AaveV3Avalanche.POOL
    );

    // requires --ffi
    diffReports('pre-por-activation', 'post-restore-btc-b');
  }

  function testSnpashot() public {
    DisableBtcbPayload proposal = new DisableBtcbPayload();

    this.createConfigurationSnapshot('pre-restore-btc-b', AaveV3Avalanche.POOL);

    _executePayload(address(proposal));

    this.createConfigurationSnapshot(
      'post-restore-btc-b',
      AaveV3Avalanche.POOL
    );

    // requires --ffi
    diffReports('pre-restore-btc-b', 'post-restore-btc-b');
  }

  function getReserveParams(address asset)
    private
    view
    returns (
      uint256,
      uint256,
      uint256,
      bool
    )
  {
    DataTypes.ReserveConfigurationMap memory configuration = AaveV3Avalanche
      .POOL
      .getConfiguration(asset);

    (
      uint256 ltv,
      uint256 liquidationThreshold,
      uint256 liquidationBonus,
      bool isFrozen
    ) = ReserveConfiguration.getReserveParams(configuration);

    return (ltv, liquidationThreshold, liquidationBonus, isFrozen);
  }
}
