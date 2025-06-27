// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {PoRBaseTest} from './utils/PoRBaseTest.sol';
import {ReserveConfigurationV2} from './utils/ReserveConfigurationV2.sol';
import {DataTypes} from 'aave-address-book/AaveV2.sol';
import {AaveV2Ethereum, AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';

contract ProofOfReserveExecutorV2Test is PoRBaseTest {
  using ReserveConfigurationV2 for DataTypes.ReserveConfigurationMap;

  function setUp() public override {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 22746000);

    _setUpIntegrationTest();
  }

  function test_executeEmergencyActionAssetsBacked() public {
    _mintBacked(AaveV2EthereumAssets.USDT_UNDERLYING, 1 ether);

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
    _mintUnbacked(AaveV2EthereumAssets.USDT_UNDERLYING, 1 ether);

    proofOfReserveExecutorV2.executeEmergencyAction();

    address[] memory assets = proofOfReserveExecutorV2.getAssets();
    (
      bool areAllReservesBacked,
      bool[] memory unbackedAssetsFlags
    ) = proofOfReserveAggregator.areAllReservesBacked(assets);

    assertFalse(areAllReservesBacked);

    for (uint256 i = 0; i < assets.length; i++) {
      DataTypes.ReserveConfigurationMap memory configuration = AaveV2Ethereum
        .POOL
        .getConfiguration(assets[i]);
      bool isFrozen = ReserveConfigurationV2.getFrozen(configuration);

      // if it is flagging unbacked, it should flag frozen after emergency action
      assertEq(unbackedAssetsFlags[i], isFrozen);
    }
  }

  function test_isEmergencyActionPossibleAssetsBacked() public {
    _mintBacked(AaveV2EthereumAssets.USDT_UNDERLYING, 1 ether);

    assertFalse(proofOfReserveExecutorV2.isEmergencyActionPossible());
  }

  function test_isEmergencyActionPossibleAssetUnbacked() public {
    _mintUnbacked(AaveV2EthereumAssets.USDT_UNDERLYING, 1 ether);

    assertTrue(proofOfReserveExecutorV2.isEmergencyActionPossible());
  }

  function test_isEmergencyActionPossibleAssetBorrowEnabled() public {
    vm.prank(AaveV2Ethereum.POOL_ADDRESSES_PROVIDER.getPoolAdmin());

    AaveV2Ethereum.POOL_CONFIGURATOR.enableBorrowingOnReserve(
      AaveV2EthereumAssets.USDT_UNDERLYING,
      true
    );

    assertTrue(proofOfReserveExecutorV2.isEmergencyActionPossible());
  }
}
