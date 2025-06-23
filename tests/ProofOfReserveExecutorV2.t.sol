// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';

import {AaveV2Avalanche} from 'aave-address-book/AaveV2Avalanche.sol';
import {AggregatorInterface} from 'aave-v3-origin/contracts/dependencies/chainlink/AggregatorInterface.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ProofOfReserveAggregator} from '../src/contracts/ProofOfReserveAggregator.sol';
import {ProofOfReserveExecutorV2} from '../src/contracts/ProofOfReserveExecutorV2.sol';
import {AvaxBridgeWrapper} from '../src/contracts/AvaxBridgeWrapper.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

contract ProofOfReserveExecutorV2Test is Test {
  ProofOfReserveAggregator private proofOfReserveAggregator;
  ProofOfReserveExecutorV2 private proofOfReserveExecutorV2;
  AvaxBridgeWrapper private bridgeWrapper;

  address private constant ASSET_1 = address(1234);
  address private constant PROOF_OF_RESERVE_FEED_1 = address(4321);

  address private constant AAVEE = 0x63a72806098Bd3D9520cC43356dD78afe5D386D9;
  address private constant AAVEE_DEPRECATED =
    0x8cE2Dee54bB9921a2AE0A63dBb2DF8eD88B91dD9;
  address private constant PORF_AAVE =
    0x14C4c668E34c09E1FBA823aD5DB47F60aeBDD4F7;

  address private constant BTCB = 0x152b9d0FdC40C096757F570A51E494bd4b943E50;
  address private constant PORF_BTCB =
    0x99311B4bf6D8E3D3B4b9fbdD09a1B0F4Ad8e06E9;

  event AssetStateChanged(address indexed asset, bool enabled);
  event AssetIsNotBacked(address indexed asset);
  event EmergencyActionExecuted();

  function setUp() public {
    vm.createSelectFork('avalanche', 62513100);
    proofOfReserveAggregator = new ProofOfReserveAggregator();
    proofOfReserveExecutorV2 = new ProofOfReserveExecutorV2(
      address(AaveV2Avalanche.POOL_ADDRESSES_PROVIDER),
      address(proofOfReserveAggregator)
    );

    // TODO: change to proof of reserve admin
    setPoolAdmin();

    bridgeWrapper = new AvaxBridgeWrapper(AAVEE, AAVEE_DEPRECATED);
  }

  function testAssetsAreEnabled() public {
    address[] memory enabledAssets = proofOfReserveExecutorV2.getAssets();
    assertEq(enabledAssets.length, 0);

    vm.expectEmit(true, false, false, true);
    emit AssetStateChanged(ASSET_1, true);

    vm.expectEmit(true, false, false, true);
    emit AssetStateChanged(AAVEE, true);

    address[] memory assets = new address[](2);
    assets[0] = ASSET_1;
    assets[1] = AAVEE;

    proofOfReserveExecutorV2.enableAssets(assets);

    enabledAssets = proofOfReserveExecutorV2.getAssets();
    assertEq(enabledAssets.length, 2);
    assertEq(enabledAssets[0], ASSET_1);
    assertEq(enabledAssets[1], AAVEE);
  }

  function testAssetAreEnabledTwice() public {
    address[] memory assets1 = new address[](1);
    address[] memory assets2 = new address[](1);
    assets1[0] = ASSET_1;
    assets2[0] = ASSET_1;

    proofOfReserveExecutorV2.enableAssets(assets1);
    proofOfReserveExecutorV2.enableAssets(assets2);

    address[] memory enabledAssets = proofOfReserveExecutorV2.getAssets();
    assertEq(enabledAssets.length, 1);
    assertEq(enabledAssets[0], ASSET_1);
  }

  function testAssetsAreEnabledWhenNotOwner() public {
    vm.expectRevert(
      bytes(
        abi.encodeWithSelector(
          Ownable.OwnableUnauthorizedAccount.selector,
          address(0)
        )
      )
    );
    vm.prank(address(0));

    address[] memory assets = new address[](1);
    assets[0] = ASSET_1;

    proofOfReserveExecutorV2.enableAssets(assets);
  }

  function testAssetsAreDisabled() public {
    address[] memory assets = new address[](3);
    assets[0] = ASSET_1;
    assets[1] = BTCB;
    assets[2] = AAVEE;

    proofOfReserveExecutorV2.enableAssets(assets);
    address[] memory enabledAssets = proofOfReserveExecutorV2.getAssets();

    assertEq(enabledAssets[0], ASSET_1);
    assertEq(enabledAssets[1], BTCB);
    assertEq(enabledAssets[2], AAVEE);

    vm.expectEmit(true, false, false, true);
    emit AssetStateChanged(ASSET_1, false);

    vm.expectEmit(true, false, false, true);
    emit AssetStateChanged(AAVEE, false);

    address[] memory assetsToDisable = new address[](2);
    assetsToDisable[0] = ASSET_1;
    assetsToDisable[1] = AAVEE;

    proofOfReserveExecutorV2.disableAssets(assetsToDisable);
    enabledAssets = proofOfReserveExecutorV2.getAssets();
    assertEq(enabledAssets.length, 1);
    assertEq(enabledAssets[0], BTCB);
  }

  function testAssetAreDisabledWhenNotOwner() public {
    vm.expectRevert(
      bytes(
        abi.encodeWithSelector(
          Ownable.OwnableUnauthorizedAccount.selector,
          address(0)
        )
      )
    );
    vm.prank(address(0));

    address[] memory assets = new address[](1);
    assets[0] = ASSET_1;
    proofOfReserveExecutorV2.disableAssets(assets);
  }

  function testAreAllReservesBackedEmptyArray() public {
    bool areAllReservesBacked = proofOfReserveExecutorV2.areAllReservesBacked();

    assertEq(areAllReservesBacked, true);
  }

  function testAreAllReservesBackedAaveBtc() public {
    enableFeedsOnRegistry();
    enableAssetsOnExecutor();

    bool areAllReservesBacked = proofOfReserveExecutorV2.areAllReservesBacked();

    assertEq(areAllReservesBacked, true);
  }

  function testNotAllReservesBacked() public {
    enableFeedsOnRegistry();
    enableAssetsOnExecutor();

    vm.mockCall(
      PORF_AAVE,
      abi.encodeWithSelector(AggregatorInterface.latestRoundData.selector),
      abi.encode(1, 1, 1, 1, 1)
    );

    proofOfReserveExecutorV2.executeEmergencyAction();

    bool isBorrowingEnabled = proofOfReserveExecutorV2.areAllReservesBacked();

    assertEq(isBorrowingEnabled, false);
  }

  function testExecuteEmergencyActionAllBacked() public {
    enableFeedsOnRegistry();
    enableAssetsOnExecutor();

    proofOfReserveExecutorV2.executeEmergencyAction();

    bool isBorrowingEnabled = proofOfReserveExecutorV2
      .isEmergencyActionPossible();

    assertEq(isBorrowingEnabled, true);
  }

  function testExecuteEmergencyActionV2() public {
    // Arrange
    enableFeedsOnRegistry();
    enableAssetsOnExecutor();

    vm.mockCall(
      PORF_AAVE,
      abi.encodeWithSelector(AggregatorInterface.latestRoundData.selector),
      abi.encode(1, 99, 1, 1, 1)
    );

    vm.mockCall(
      address(bridgeWrapper),
      abi.encodeWithSelector(IERC20.totalSupply.selector),
      abi.encode(100)
    );

    vm.mockCall(
      PORF_BTCB,
      abi.encodeWithSelector(AggregatorInterface.latestRoundData.selector),
      abi.encode(1, 1, 1, 1, 1)
    );

    vm.expectEmit(true, false, false, true);
    emit AssetIsNotBacked(AAVEE);

    vm.expectEmit(true, false, false, true);
    emit AssetIsNotBacked(BTCB);

    vm.expectEmit(false, false, false, true);
    emit EmergencyActionExecuted();

    // Act
    proofOfReserveExecutorV2.executeEmergencyAction();

    // Assert
    bool isEmergencyActionPossible = proofOfReserveExecutorV2
      .isEmergencyActionPossible();

    assertEq(isEmergencyActionPossible, false);
  }

  // emergency action - executed and events are emmited

  function enableFeedsOnRegistry() private {
    proofOfReserveAggregator.enableProofOfReserveFeedWithBridgeWrapper(
      AAVEE,
      PORF_AAVE,
      address(bridgeWrapper)
    );
    proofOfReserveAggregator.enableProofOfReserveFeed(BTCB, PORF_BTCB);
  }

  function enableAssetsOnExecutor() private {
    address[] memory assets = new address[](2);
    assets[0] = AAVEE;
    assets[1] = BTCB;

    proofOfReserveExecutorV2.enableAssets(assets);
  }

  function setPoolAdmin() private {
    vm.prank(AaveV2Avalanche.POOL_ADDRESSES_PROVIDER.getPoolAdmin());

    AaveV2Avalanche.POOL_ADDRESSES_PROVIDER.setPoolAdmin(
      address(proofOfReserveExecutorV2)
    );
  }
}
