// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {ProofOfReserve} from '../src/contracts/ProofOfReserve.sol';

contract ProofOfReserveTest is Test {
  ProofOfReserve public proofOfReserve;
  uint256 avalancheFork;

  address constant OWNER = address(1234);
  address constant ASSET_1 = address(1234);
  address constant PROOF_OF_RESERVE_FEED_1 = address(4321);

  // asset2
  // PROOF_OF_RESERVE_FEED_1
  // proofOfReserveFeed2
  event ProofOfReserveFeedStateChanged(
    address indexed asset,
    address indexed proofOfReserveFeed,
    bool enabled
  );

  function setUp() public {
    // avalancheFork = vm.createFork('https://avalancherpc.com');
    // vm.selectFork(avalancheFork);
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
    (bool result, bool[] memory backedAssetsFlags) = proofOfReserve
      .areAllReservesBacked(assets);

    assertEq(backedAssetsFlags.length, 0);
    assertEq(result, true);
  }

  // all reserves backed - assets in array and in contract are different

  // all reserves backed - true

  // all reserves backed - false
}
