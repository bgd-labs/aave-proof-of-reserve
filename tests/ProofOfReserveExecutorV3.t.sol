// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {PoRBaseTest} from './utils/PoRBaseTest.sol';
import {IProofOfReserveExecutor} from '../src/interfaces/IProofOfReserveExecutor.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {DataTypes} from 'aave-address-book/AaveV3.sol';
import {ReserveConfiguration} from 'aave-v3-origin/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';

contract ProofOfReserveExecutorV3Test is PoRBaseTest {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  function setUp() public override {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 22746000);

    _setUpIntegrationTest();
  }

  function test_executeEmergencyActionAssetsBacked() public {
    _mintBacked(AaveV3EthereumAssets.USDT_UNDERLYING, 1 ether);

    proofOfReserveExecutorV3.executeEmergencyAction();

    address[] memory assets = proofOfReserveExecutorV3.getAssets();

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
    _mintUnbacked(AaveV3EthereumAssets.USDT_UNDERLYING, 1 ether);

    proofOfReserveExecutorV3.executeEmergencyAction();

    address[] memory assets = proofOfReserveExecutorV3.getAssets();

    (
      bool areAllReservesBacked,
      bool[] memory unbackedAssetsFlags
    ) = proofOfReserveAggregator.areAllReservesBacked(assets);

    assertFalse(areAllReservesBacked);

    for (uint256 i = 0; i < assets.length; i++) {
      DataTypes.ReserveConfigurationMap memory configuration = AaveV3Ethereum
        .POOL
        .getConfiguration(assets[i]);
      bool isFrozen = ReserveConfiguration.getFrozen(configuration);

      // if it is flagging unbacked, it should flag frozen after emergency action
      assertEq(unbackedAssetsFlags[i], isFrozen);
    }
  }

  function test_isEmergencyActionPossibleAssetsBacked() public {
    _mintBacked(AaveV3EthereumAssets.USDT_UNDERLYING, 1 ether);

    assertFalse(proofOfReserveExecutorV3.isEmergencyActionPossible());
  }

  function test_isEmergencyActionPossibleAssetUnbacked() public {
    _mintUnbacked(AaveV3EthereumAssets.USDT_UNDERLYING, 1 ether);

    assertTrue(proofOfReserveExecutorV3.isEmergencyActionPossible());
  }

  function test_areAllReservesBacked() public {
    _mintBacked(AaveV3EthereumAssets.USDT_UNDERLYING, 1 ether);
    assertTrue(proofOfReserveExecutorV3.areAllReservesBacked());

    _mintUnbacked(AaveV3EthereumAssets.USDT_UNDERLYING, 2 ether);
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

  function _skipEnabledAssets(address[] memory assets) internal pure {
    for (uint256 i = 0; i < assets.length; i++) {
      vm.assume(assets[i] != AaveV3EthereumAssets.USDT_UNDERLYING);
      vm.assume(assets[i] != AaveV3EthereumAssets.USDC_UNDERLYING);
      vm.assume(assets[i] != AaveV3EthereumAssets.WBTC_UNDERLYING);
    }
  }
}
