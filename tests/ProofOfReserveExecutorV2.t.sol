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

    address[] memory assets = proofOfReserveExecutorV2.getAssets();
    (
      bool areAllReservesBacked,
      bool[] memory unbackedAssetsFlags
    ) = proofOfReserveAggregator.areAllReservesBacked(assets);

    assertTrue(areAllReservesBacked);

    for (uint256 i = 0; i < unbackedAssetsFlags.length; i++) {
      assertFalse(unbackedAssetsFlags[i]);
    }
  }

  function test_executeEmergencyActionAssetUnbacked() public {
    _mintUnbacked(asset_1, 1 ether);

    proofOfReserveExecutorV2.executeEmergencyAction();

    address[] memory assets = proofOfReserveExecutorV2.getAssets();
    (
      bool areAllReservesBacked,
      bool[] memory unbackedAssetsFlags
    ) = proofOfReserveAggregator.areAllReservesBacked(assets);

    assertFalse(areAllReservesBacked);

    for (uint256 i = 0; i < assets.length; i++) {
      DataTypes.ReserveConfigurationMap memory configuration = poolV2
        .getConfiguration(assets[i]);
      bool isFrozen = ReserveConfigurationV2.getFrozen(configuration);

      // if it is flagging unbacked, it should flag frozen after emergency action
      assertEq(unbackedAssetsFlags[i], isFrozen);
    }
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
    DataTypes.ReserveConfigurationMap memory currentConfig = poolV2
      .getConfiguration(asset_1);
    currentConfig.setBorrowingEnabled(true);
    poolV2.setConfiguration(asset_1, currentConfig.data);

    assertTrue(proofOfReserveExecutorV2.isEmergencyActionPossible());
  }

  function test_configuration() public view {
    assertEq(address(proofOfReserveExecutorV2.POOL()), address(poolV2));
    assertEq(
      address(proofOfReserveExecutorV2.POOL_CONFIGURATOR()),
      address(poolConfiguratorV2)
    );
    assertEq(
      address(proofOfReserveExecutorV2.PROOF_OF_RESERVE_AGGREGATOR()),
      address(proofOfReserveAggregator)
    );
    assertEq(proofOfReserveExecutorV2.owner(), defaultAdmin);
  }

  function _initPoolReserves() internal override {
    address[] memory assets = proofOfReserveExecutorV2.getAssets();
    // adds assets to the pool reserves list
    poolConfiguratorV2.initReserves(assets);
  }
}
