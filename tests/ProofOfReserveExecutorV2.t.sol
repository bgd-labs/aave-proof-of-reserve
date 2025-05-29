// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PoRBaseTest} from './utils/PoRBaseTest.sol';
import {ReserveConfigurationV2} from './utils/ReserveConfigurationV2.sol';
import {DataTypes} from 'aave-address-book/AaveV2.sol';

contract ProofOfReserveExecutorV2Test is PoRBaseTest {
  using ReserveConfigurationV2 for DataTypes.ReserveConfigurationMap;

  function setUp() public override {
    _setUpV2({enableAssets: true});
  }

  function test_executeEmergencyActionAssetsBacked() public {
    _mintBacked(asset_1, 1 ether);

    proofOfReserveExecutorV2.executeEmergencyAction();

    _assertEmergencyAction();
  }

  function test_executeEmergencyActionAssetUnbacked() public {
    _mintUnbacked(asset_1, 1 ether);

    proofOfReserveExecutorV2.executeEmergencyAction();

    _assertEmergencyAction();
  }

  function test_isEmergencyActionPossibleAssetsBacked() public {
    _mintBacked(asset_1, 1 ether);

    assertFalse(proofOfReserveExecutorV2.isEmergencyActionPossible());
  }

  function test_isEmergencyActionPossibleAssetUnbacked() public {
    _mintUnbacked(asset_1, 1 ether);

    assertTrue(proofOfReserveExecutorV2.isEmergencyActionPossible());
  }

  function test_isEmergencyActionPossibleAssetBorrowEnabled() public {
    DataTypes.ReserveConfigurationMap memory currentConfig = poolV2.getConfiguration(address(asset_1));
    currentConfig.setBorrowingEnabled(true);
    poolV2.setConfiguration(address(asset_1), currentConfig.data);

    assertTrue(proofOfReserveExecutorV2.isEmergencyActionPossible());
  }

  function _initPoolReserves() internal override {
    address[] memory assets = proofOfReserveExecutorV2.getAssets();
    // this keep getFrozen flag = false and enable borrows
    poolConfiguratorV2.initReserves(assets);
  }

  function _assertEmergencyAction() internal view {
    address[] memory assets = proofOfReserveExecutorV2.getAssets();
    (, bool[] memory unbackedAssetsFlags) = proofOfReserveAggregator
      .areAllReservesBacked(assets);

    for (uint256 i = 0; i < assets.length; i++) {
      DataTypes.ReserveConfigurationMap memory configuration = poolV2
        .getConfiguration(assets[i]);
      bool isFrozen = ReserveConfigurationV2.getFrozen(configuration);
      bool isBorrowingEnable = ReserveConfigurationV2.getBorrowingEnabled(
        configuration
      );

      assertFalse(isBorrowingEnable);

      if (unbackedAssetsFlags[i]) {
        assertTrue(isFrozen);
      } else {
        assertFalse(isFrozen);
      }
    }
  }
}
