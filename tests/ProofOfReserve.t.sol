// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';

import {ProofOfReserve} from '../src/contracts/ProofOfReserve.sol';
import {AggregatorV3Interface} from 'chainlink-brownie-contracts/interfaces/AggregatorV3Interface.sol';

contract ProofOfReserveTest is Test {
  ProofOfReserve public proofOfReserve;
  uint256 private avalancheFork;

  address private constant OWNER = address(1234);
  address private constant ASSET_1 = address(1234);
  address private constant PROOF_OF_RESERVE_FEED_1 = address(4321);

  address private constant AAVEE = 0x63a72806098Bd3D9520cC43356dD78afe5D386D9;
  address private constant PORF_AAVE =
    0x14C4c668E34c09E1FBA823aD5DB47F60aeBDD4F7;
  address private constant BTCB = 0x152b9d0FdC40C096757F570A51E494bd4b943E50;
  address private constant PORF_BTCB =
    0x99311B4bf6D8E3D3B4b9fbdD09a1B0F4Ad8e06E9;

  event ProofOfReserveFeedStateChanged(
    address indexed asset,
    address indexed proofOfReserveFeed,
    bool enabled
  );

  function setUp() public {
    // TODO: we do not need to create fork for every test
    avalancheFork = vm.createFork('https://avalancherpc.com');
    vm.selectFork(avalancheFork);
    proofOfReserve = new ProofOfReserve();
  }

  function testProoOfReserveFeedIsEnabled() public {
    address proofOfReserveFeed = proofOfReserve.getProofOfReserveFeedForAsset(
      ASSET_1
    );
    assertEq(proofOfReserveFeed, address(0));

    vm.expectEmit(true, true, false, true);
    emit ProofOfReserveFeedStateChanged(ASSET_1, PROOF_OF_RESERVE_FEED_1, true);

    proofOfReserve.enableProofOfReserveFeed(ASSET_1, PROOF_OF_RESERVE_FEED_1);
    proofOfReserveFeed = proofOfReserve.getProofOfReserveFeedForAsset(ASSET_1);
    assertEq(proofOfReserveFeed, PROOF_OF_RESERVE_FEED_1);
  }

  function testProoOfReserveFeedIsEnabledWhenNotOwner() public {
    vm.expectRevert(bytes('Ownable: caller is not the owner'));
    vm.prank(address(0));
    proofOfReserve.enableProofOfReserveFeed(ASSET_1, PROOF_OF_RESERVE_FEED_1);
  }

  function testProoOfReserveFeedIsDisabled() public {
    proofOfReserve.enableProofOfReserveFeed(ASSET_1, PROOF_OF_RESERVE_FEED_1);
    address proofOfReserveFeed = proofOfReserve.getProofOfReserveFeedForAsset(
      ASSET_1
    );
    assertEq(proofOfReserveFeed, PROOF_OF_RESERVE_FEED_1);

    vm.expectEmit(true, true, false, true);
    emit ProofOfReserveFeedStateChanged(ASSET_1, address(0), false);

    proofOfReserve.disableProofOfReserveFeed(ASSET_1);
    proofOfReserveFeed = proofOfReserve.getProofOfReserveFeedForAsset(ASSET_1);
    assertEq(proofOfReserveFeed, address(0));
  }

  function testProoOfReserveFeedIsDisabledWhenNotOwner() public {
    vm.expectRevert(bytes('Ownable: caller is not the owner'));
    vm.prank(address(0));
    proofOfReserve.disableProofOfReserveFeed(ASSET_1);
  }

  function testAreAllReservesBackedEmptyArray() public {
    address[] memory assets = new address[](0);
    (bool result, bool[] memory unbackedAssetsFlags) = proofOfReserve
      .areAllReservesBacked(assets);

    assertEq(unbackedAssetsFlags.length, 0);
    assertEq(result, true);
  }

  function testAreAllReservesBackedDifferentAssets() public {
    addFeedsToContract();

    address[] memory assets = new address[](2);
    assets[0] = address(0);
    assets[1] = address(1);

    (bool result, bool[] memory unbackedAssetsFlags) = proofOfReserve
      .areAllReservesBacked(assets);

    assertEq(unbackedAssetsFlags.length, 2);
    assertEq(unbackedAssetsFlags[0], false);
    assertEq(unbackedAssetsFlags[1], false);
    assertEq(result, true);
  }

  function testAreAllReservesBackedAaveBtc() public {
    addFeedsToContract();

    address[] memory assets = new address[](2);
    assets[0] = AAVEE;
    assets[1] = BTCB;

    (bool result, bool[] memory unbackedAssetsFlags) = proofOfReserve
      .areAllReservesBacked(assets);

    assertEq(unbackedAssetsFlags.length, 2);
    assertEq(unbackedAssetsFlags[0], false);
    assertEq(unbackedAssetsFlags[1], false);
    assertEq(result, true);
  }

  function testNotAllReservesBacked() public {
    addFeedsToContract();

    address[] memory assets = new address[](2);
    assets[0] = AAVEE;
    assets[1] = BTCB;

    vm.mockCall(
      0x14C4c668E34c09E1FBA823aD5DB47F60aeBDD4F7,
      abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
      abi.encode(1, 1, 1, 1, 1)
    );

    (bool result, bool[] memory unbackedAssetsFlags) = proofOfReserve
      .areAllReservesBacked(assets);

    assertEq(unbackedAssetsFlags.length, 2);
    assertEq(unbackedAssetsFlags[0], true);
    assertEq(unbackedAssetsFlags[1], false);
    assertEq(result, false);
  }

  function addFeedsToContract() private {
    proofOfReserve.enableProofOfReserveFeed(AAVEE, PORF_AAVE);
    proofOfReserve.enableProofOfReserveFeed(BTCB, PORF_BTCB);
  }
}
