// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';

import {AggregatorV3Interface} from 'chainlink-brownie-contracts/interfaces/AggregatorV3Interface.sol';
import {ProofOfReserveAggregator} from '../src/contracts/ProofOfReserveAggregator.sol';
import {AvaxBridgeWrapper} from '../src/contracts/AvaxBridgeWrapper.sol';

contract ProofOfReserveAggregatorTest is Test {
  ProofOfReserveAggregator public proofOfReserveAggregator;
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

  event ProofOfReserveFeedStateChanged(
    address indexed asset,
    address indexed proofOfReserveFeed,
    address indexed bridgeWrapper,
    bool enabled
  );

  function setUp() public {
    vm.createSelectFork('avalanche');
    proofOfReserveAggregator = new ProofOfReserveAggregator();
    bridgeWrapper = new AvaxBridgeWrapper(AAVEE, AAVEE_DEPRECATED);
  }

  function testProofOfReserveFeedIsEnabled() public {
    address proofOfReserveFeed = proofOfReserveAggregator
      .getProofOfReserveFeedForAsset(ASSET_1);
    assertEq(proofOfReserveFeed, address(0));

    vm.expectEmit(true, true, false, true);
    emit ProofOfReserveFeedStateChanged(
      ASSET_1,
      PROOF_OF_RESERVE_FEED_1,
      address(0),
      true
    );

    proofOfReserveAggregator.enableProofOfReserveFeed(
      ASSET_1,
      PROOF_OF_RESERVE_FEED_1
    );
    proofOfReserveFeed = proofOfReserveAggregator.getProofOfReserveFeedForAsset(
        ASSET_1
      );
    assertEq(proofOfReserveFeed, PROOF_OF_RESERVE_FEED_1);
  }

  function testProofOfReserveFeedIsEnabledWithZeroAsserAddress() public {
    vm.expectRevert(bytes('INVALID_ASSET'));
    proofOfReserveAggregator.enableProofOfReserveFeed(
      address(0),
      PROOF_OF_RESERVE_FEED_1
    );
  }

  function testProofOfReserveFeedIsEnabledWithZeroPoRAddress() public {
    vm.expectRevert(bytes('INVALID_PROOF_OF_RESERVE_FEED'));
    proofOfReserveAggregator.enableProofOfReserveFeed(ASSET_1, address(0));
  }

  function testProofOfReserveFeedIsEnabledWhenNotOwner() public {
    vm.expectRevert(bytes('Ownable: caller is not the owner'));
    vm.prank(address(0));
    proofOfReserveAggregator.enableProofOfReserveFeed(
      ASSET_1,
      PROOF_OF_RESERVE_FEED_1
    );
  }

  function testProofOfReserveFeedWithBridgeWrapperIsEnabled() public {
    address proofOfReserveFeed = proofOfReserveAggregator
      .getProofOfReserveFeedForAsset(AAVEE);
    assertEq(proofOfReserveFeed, address(0));

    vm.expectEmit(true, true, false, true);
    emit ProofOfReserveFeedStateChanged(
      AAVEE,
      PORF_AAVE,
      address(bridgeWrapper),
      true
    );

    proofOfReserveAggregator.enableProofOfReserveFeedWithBridgeWrapper(
      AAVEE,
      PORF_AAVE,
      address(bridgeWrapper)
    );
    proofOfReserveFeed = proofOfReserveAggregator.getProofOfReserveFeedForAsset(
        AAVEE
      );
    assertEq(proofOfReserveFeed, PORF_AAVE);
  }

  function testProofOfReserveFeedWithBridgeWrapperIsEnabledWithZeroAsserAddress()
    public
  {
    vm.expectRevert(bytes('INVALID_ASSET'));
    proofOfReserveAggregator.enableProofOfReserveFeedWithBridgeWrapper(
      address(0),
      PORF_AAVE,
      address(bridgeWrapper)
    );
  }

  function testProofOfReserveFeedWithBridgeWrapperIsEnabledWithZeroPoRAddress()
    public
  {
    vm.expectRevert(bytes('INVALID_PROOF_OF_RESERVE_FEED'));
    proofOfReserveAggregator.enableProofOfReserveFeedWithBridgeWrapper(
      AAVEE,
      address(0),
      address(bridgeWrapper)
    );
  }

  function testProofOfReserveFeedWithBridgeWrapperIsEnabledWithZeroBridgeAddress()
    public
  {
    vm.expectRevert(bytes('INVALID_BRIDGE_WRAPPER'));
    proofOfReserveAggregator.enableProofOfReserveFeedWithBridgeWrapper(
      AAVEE,
      PORF_AAVE,
      address(0)
    );
  }

  function testProofOfReserveFeedWithBridgeWrapperIsEnabledWhenNotOwner()
    public
  {
    vm.expectRevert(bytes('Ownable: caller is not the owner'));
    vm.prank(address(0));
    proofOfReserveAggregator.enableProofOfReserveFeedWithBridgeWrapper(
      AAVEE,
      PORF_AAVE,
      address(bridgeWrapper)
    );
  }

  function testProoOfReserveFeedIsDisabled() public {
    proofOfReserveAggregator.enableProofOfReserveFeed(
      ASSET_1,
      PROOF_OF_RESERVE_FEED_1
    );
    address proofOfReserveFeed = proofOfReserveAggregator
      .getProofOfReserveFeedForAsset(ASSET_1);
    assertEq(proofOfReserveFeed, PROOF_OF_RESERVE_FEED_1);

    vm.expectEmit(true, true, false, true);
    emit ProofOfReserveFeedStateChanged(ASSET_1, address(0), address(0), false);

    proofOfReserveAggregator.disableProofOfReserveFeed(ASSET_1);
    proofOfReserveFeed = proofOfReserveAggregator.getProofOfReserveFeedForAsset(
        ASSET_1
      );
    assertEq(proofOfReserveFeed, address(0));
  }

  function testProoOfReserveFeedIsDisabledWhenNotOwner() public {
    vm.expectRevert(bytes('Ownable: caller is not the owner'));
    vm.prank(address(0));
    proofOfReserveAggregator.disableProofOfReserveFeed(ASSET_1);
  }

  function testAreAllReservesBackedEmptyArray() public {
    address[] memory assets = new address[](0);
    (
      bool areReservesBacked,
      bool[] memory unbackedAssetsFlags
    ) = proofOfReserveAggregator.areAllReservesBacked(assets);

    assertEq(unbackedAssetsFlags.length, 0);
    assertEq(areReservesBacked, true);
  }

  function testAreAllReservesBackedDifferentAssets() public {
    addFeeds();

    address[] memory assets = new address[](2);
    assets[0] = address(0);
    assets[1] = address(1);

    (
      bool areReservesBacked,
      bool[] memory unbackedAssetsFlags
    ) = proofOfReserveAggregator.areAllReservesBacked(assets);

    assertEq(unbackedAssetsFlags.length, 2);
    assertEq(unbackedAssetsFlags[0], false);
    assertEq(unbackedAssetsFlags[1], false);
    assertEq(areReservesBacked, true);
  }

  function testAreAllReservesBackedAaveBtc() public {
    addFeeds();

    address[] memory assets = new address[](2);
    assets[0] = AAVEE;
    assets[1] = BTCB;

    (
      bool areReservesBacked,
      bool[] memory unbackedAssetsFlags
    ) = proofOfReserveAggregator.areAllReservesBacked(assets);

    assertEq(unbackedAssetsFlags.length, 2);
    assertEq(unbackedAssetsFlags[0], false);
    assertEq(unbackedAssetsFlags[1], false);
    assertEq(areReservesBacked, true);
  }

  function testNotAllReservesBacked() public {
    addFeeds();

    address[] memory assets = new address[](2);
    assets[0] = AAVEE;
    assets[1] = BTCB;

    vm.mockCall(
      PORF_AAVE,
      abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
      abi.encode(1, 1, 1, 1, 1)
    );

    (
      bool areReservesBacked,
      bool[] memory unbackedAssetsFlags
    ) = proofOfReserveAggregator.areAllReservesBacked(assets);

    assertEq(unbackedAssetsFlags.length, 2);
    assertEq(unbackedAssetsFlags[0], true);
    assertEq(unbackedAssetsFlags[1], false);
    assertEq(areReservesBacked, false);
  }

  function addFeeds() private {
    proofOfReserveAggregator.enableProofOfReserveFeed(AAVEE, PORF_AAVE);
    proofOfReserveAggregator.enableProofOfReserveFeed(BTCB, PORF_BTCB);
  }
}
