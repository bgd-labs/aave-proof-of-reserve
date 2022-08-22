// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {AggregatorV3Interface} from 'chainlink-brownie-contracts/interfaces/AggregatorV3Interface.sol';
import {Test} from 'forge-std/Test.sol';

import {ProofOfReserve} from '../src/contracts/ProofOfReserve.sol';
import {ProofOfReserveExecutorV2} from '../src/contracts/ProofOfReserveExecutorV2.sol';

import {IPool, ReserveConfigurationMap} from '../src/dependencies/IPool.sol';
import {IPoolAddressProvider} from '../src/dependencies/IPoolAddressProvider.sol';
import {ReserveConfiguration} from './ReserveConfiguration.sol';

contract ProofOfReserveTest is Test {
  ProofOfReserve private proofOfReserve;
  ProofOfReserveExecutorV2 private proofOfReserveExecutorV2;
  uint256 private avalancheFork;
  address private constant POOL = 0x4F01AeD16D97E3aB5ab2B501154DC9bb0F1A5A2C;

  address private constant USER = address(9999);
  address private constant ASSET_1 = address(1234);
  address private constant PROOF_OF_RESERVE_FEED_1 = address(4321);

  address private constant AAVEE = 0x63a72806098Bd3D9520cC43356dD78afe5D386D9;
  address private constant PORF_AAVE =
    0x14C4c668E34c09E1FBA823aD5DB47F60aeBDD4F7;
  address private constant BTCB = 0x152b9d0FdC40C096757F570A51E494bd4b943E50;
  address private constant PORF_BTCB =
    0x99311B4bf6D8E3D3B4b9fbdD09a1B0F4Ad8e06E9;

  event AssetStateChanged(address indexed asset, bool enabled);
  event AssetIsNotBacked(address indexed asset);
  event EmergencyActionExecuted(address indexed user);

  function setUp() public {
    avalancheFork = vm.createFork('https://avalancherpc.com');
    vm.selectFork(avalancheFork);
    proofOfReserve = new ProofOfReserve();
    proofOfReserveExecutorV2 = new ProofOfReserveExecutorV2(
      POOL,
      address(proofOfReserve)
    );
  }

  function testAssetIsEnabled() public {
    address[] memory enabledAssets = proofOfReserveExecutorV2.getAssets();
    assertEq(enabledAssets.length, 0);

    vm.expectEmit(true, false, false, true);
    emit AssetStateChanged(ASSET_1, true);

    proofOfReserveExecutorV2.enableAsset(ASSET_1);

    enabledAssets = proofOfReserveExecutorV2.getAssets();
    assertEq(enabledAssets.length, 1);
    assertEq(enabledAssets[0], ASSET_1);
  }

  function testAssetIsEnabledTwice() public {
    proofOfReserveExecutorV2.enableAsset(ASSET_1);
    proofOfReserveExecutorV2.enableAsset(ASSET_1);

    address[] memory enabledAssets = proofOfReserveExecutorV2.getAssets();
    assertEq(enabledAssets.length, 1);
    assertEq(enabledAssets[0], ASSET_1);
  }

  function testAssetIsEnabledWhenNotOwner() public {
    vm.expectRevert(bytes('Ownable: caller is not the owner'));
    vm.prank(address(0));
    proofOfReserveExecutorV2.enableAsset(ASSET_1);
  }

  function testAssetIsDisabled() public {
    proofOfReserveExecutorV2.enableAsset(ASSET_1);

    address[] memory enabledAssets = proofOfReserveExecutorV2.getAssets();

    assertEq(enabledAssets[0], ASSET_1);

    vm.expectEmit(true, false, false, true);
    emit AssetStateChanged(ASSET_1, false);

    proofOfReserveExecutorV2.disableAsset(ASSET_1);
    enabledAssets = proofOfReserveExecutorV2.getAssets();
    assertEq(enabledAssets.length, 0);
  }

  function testAssetIsDisabledWhenNotOwner() public {
    vm.expectRevert(bytes('Ownable: caller is not the owner'));
    vm.prank(address(0));
    proofOfReserveExecutorV2.disableAsset(ASSET_1);
  }

  function testAreAllReservesBackedEmptyArray() public {
    bool result = proofOfReserveExecutorV2.areAllReservesBacked();

    assertEq(result, true);
  }

  function testAreAllReservesBackedAaveBtc() public {
    enableFeedsOnRegistry();
    enableAssetsOnExecutor();

    bool result = proofOfReserveExecutorV2.areAllReservesBacked();

    assertEq(result, true);
  }

  function testNotAllReservesBacked() public {
    enableFeedsOnRegistry();
    enableAssetsOnExecutor();

    vm.mockCall(
      PORF_AAVE,
      abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
      abi.encode(1, 1, 1, 1, 1)
    );

    bool result = proofOfReserveExecutorV2.areAllReservesBacked();

    assertEq(result, false);
  }

  function testExecuteEmergencyActionAllBacked() public {
    enableFeedsOnRegistry();
    enableAssetsOnExecutor();

    bool result = isBorrowingEnabledAtLeastOnOneAsset();

    assertEq(result, true);
  }

  function testExecuteEmergencyAction() public {
    enableFeedsOnRegistry();
    enableAssetsOnExecutor();

    vm.mockCall(
      PORF_AAVE,
      abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
      abi.encode(1, 1, 1, 1, 1)
    );

    vm.mockCall(
      PORF_BTCB,
      abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
      abi.encode(1, 1, 1, 1, 1)
    );

    vm.expectEmit(true, false, false, true);
    emit AssetIsNotBacked(AAVEE);

    vm.expectEmit(true, false, false, true);
    emit AssetIsNotBacked(BTCB);

    vm.expectEmit(true, false, false, true);
    emit EmergencyActionExecuted(USER);

    setPoolAdmin();

    vm.prank(USER);
    proofOfReserveExecutorV2.executeEmergencyAction();

    bool result = isBorrowingEnabledAtLeastOnOneAsset();

    assertEq(result, false);
  }

  // emergency action - executed and events are emmited

  function enableFeedsOnRegistry() private {
    proofOfReserve.enableProofOfReserveFeed(AAVEE, PORF_AAVE);
    proofOfReserve.enableProofOfReserveFeed(BTCB, PORF_BTCB);
  }

  function enableAssetsOnExecutor() private {
    proofOfReserveExecutorV2.enableAsset(AAVEE);
    proofOfReserveExecutorV2.enableAsset(BTCB);
  }

  function setPoolAdmin() private {
    IPool pool = IPool(POOL);
    IPoolAddressProvider addressProvider = pool.getAddressesProvider();
    vm.prank(addressProvider.getPoolAdmin());

    addressProvider.setPoolAdmin(address(proofOfReserveExecutorV2));
  }

  function isBorrowingEnabledAtLeastOnOneAsset() private view returns (bool) {
    IPool pool = IPool(POOL);
    address[] memory allAssets = pool.getReservesList();
    bool result = false;

    for (uint256 i; i < allAssets.length; i++) {
      ReserveConfigurationMap memory configuration = pool.getConfiguration(
        allAssets[i]
      );

      (, , bool borrowingEnabled, ) = ReserveConfiguration.getFlags(
        configuration
      );

      result = result || borrowingEnabled;
    }

    return result;
  }
}
