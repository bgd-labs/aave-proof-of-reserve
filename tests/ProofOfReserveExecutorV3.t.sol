// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PoRBaseTest} from './utils/PoRBaseTest.sol';
import {IProofOfReserveExecutor} from '../src/interfaces/IProofOfReserveExecutor.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {DataTypes} from 'aave-address-book/AaveV3.sol';
import {ReserveConfiguration} from 'aave-v3-origin/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';

contract ProofOfReserveExecutorV3Test is PoRBaseTest {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  function setUp() public override {
    _setUpV3({enableAssets: true});
  }

  function test_executeEmergencyActionAssetsBacked() public {
    _mintBacked(tokenList.usdx, 1 ether);

    proofOfReserveExecutorV3.executeEmergencyAction();

    _assertEmergencyAction();
  }

  function test_executeEmergencyActionAssetUnbacked() public {
    _mintUnbacked(tokenList.usdx, 1 ether);

    proofOfReserveExecutorV3.executeEmergencyAction();

    _assertEmergencyAction();
  }

  function test_isEmergencyActionPossibleAssetsBacked() public {
    _mintBacked(tokenList.usdx, 1 ether);

    assertFalse(proofOfReserveExecutorV3.isEmergencyActionPossible());
  }

  function test_isEmergencyActionPossibleAssetUnbacked() public {
    _mintUnbacked(tokenList.usdx, 1 ether);

    assertTrue(proofOfReserveExecutorV3.isEmergencyActionPossible());
  }

  function test_areAllReservesBacked() public {
    _mintBacked(tokenList.usdx, 1 ether);
    assertTrue(proofOfReserveExecutorV3.areAllReservesBacked());

    _mintUnbacked(tokenList.usdx, 1 ether);
    assertFalse(proofOfReserveExecutorV3.areAllReservesBacked());
  }

  function test_areAllReservesBackedNoAssetsEnabled() public {
    vm.startPrank(defaultAdmin);
    address[] memory assets = proofOfReserveExecutorV3.getAssets();
    proofOfReserveExecutorV3.disableAssets(assets);

    assertTrue(proofOfReserveExecutorV3.areAllReservesBacked());
  }

  function test_enableAssets(address asset1, address asset2) public {
    vm.assume(asset1 != asset2);
    address[] memory assets = new address[](2);
    assets[0] = asset1;
    assets[1] = asset2;

    _skipEnabledAssets(assets);

    vm.startPrank(defaultAdmin);
    for (uint256 i = 0; i < assets.length; ++i) {
      vm.expectEmit();
      emit IProofOfReserveExecutor.AssetStateChanged(assets[i], true);
    }
    proofOfReserveExecutorV3.enableAssets(assets);
  }

  function test_disableAssets(address asset1, address asset2) public {
    vm.assume(asset1 != asset2);
    address[] memory assets = new address[](2);
    assets[0] = asset1;
    assets[1] = asset2;

    _skipEnabledAssets(assets);

    vm.startPrank(defaultAdmin);
    proofOfReserveExecutorV3.enableAssets(assets);

    for (uint256 i = 0; i < assets.length; ++i) {
      vm.expectEmit();
      emit IProofOfReserveExecutor.AssetStateChanged(assets[i], false);
    }
    proofOfReserveExecutorV3.disableAssets(assets);
  }

  function test_configuration() public view {
    assertEq(address(proofOfReserveExecutorV3.POOL()), report.poolProxy);
    assertEq(
      address(proofOfReserveExecutorV3.POOL_CONFIGURATOR()),
      report.poolConfiguratorProxy
    );
    assertEq(
      address(proofOfReserveExecutorV3.PROOF_OF_RESERVE_AGGREGATOR()),
      address(proofOfReserveAggregator)
    );
    assertEq(proofOfReserveExecutorV3.owner(), defaultAdmin);
  }

  function _initPoolReserves() internal override {}

  function _assertEmergencyAction() internal view {
    address[] memory assets = proofOfReserveExecutorV3.getAssets();
    (, bool[] memory unbackedAssetsFlags) = proofOfReserveAggregator
      .areAllReservesBacked(assets);

    for (uint256 i = 0; i < assets.length; i++) {
      DataTypes.ReserveConfigurationMap memory configuration = contracts
        .poolProxy
        .getConfiguration(assets[i]);
      bool isFrozen = ReserveConfiguration.getFrozen(configuration);
      uint256 ltv = ReserveConfiguration.getLtv(configuration);

      if (unbackedAssetsFlags[i]) {
        assertTrue(isFrozen);
        assertEq(ltv, 0);
      } else {
        assertFalse(isFrozen);
        assertNotEq(ltv, 0);
      }
    }
  }

  function _skipEnabledAssets(address[] memory assets) internal view {
    for (uint256 i = 0; i < assets.length; i++) {
      vm.assume(assets[i] != tokenList.usdx);
      vm.assume(assets[i] != tokenList.weth);
      vm.assume(assets[i] != current_asset_3);
    }
  }
}
