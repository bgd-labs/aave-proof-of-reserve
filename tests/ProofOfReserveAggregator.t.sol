// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PoRBaseTest} from './utils/PoRBaseTest.sol';
import {IProofOfReserveAggregator} from '../src/interfaces/IProofOfReserveAggregator.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

contract ProofOfReserveAggregatorTest is PoRBaseTest {
  function setUp() public override {
    _setUpV3({enableAssets: false});
  }

  function test_enableProofOfReserveFeed(
    address asset,
    address feed,
    uint16 _margin
  ) public {
    vm.assume(asset != address(0) && feed != address(0));
    uint256 margin = bound(_margin, 0, proofOfReserveAggregator.MAX_MARGIN());
    vm.prank(defaultAdmin);

    vm.expectEmit();
    emit IProofOfReserveAggregator.ProofOfReserveFeedStateChanged(
      asset,
      feed,
      address(0),
      margin,
      true
    );
    proofOfReserveAggregator.enableProofOfReserveFeed(asset, feed, margin);
  }

  function test_enableProofOfReserveFeedAlreadyEnable(
    address asset,
    address feed
  ) public {
    vm.assume(asset != address(0) && feed != address(0));
    vm.startPrank(defaultAdmin);
    proofOfReserveAggregator.enableProofOfReserveFeed(
      asset,
      feed,
      DEFAULT_MARGIN
    );

    vm.expectRevert(
      abi.encodeWithSelector(
        IProofOfReserveAggregator.FeedAlreadyEnabled.selector
      )
    );
    proofOfReserveAggregator.enableProofOfReserveFeed(
      asset,
      feed,
      DEFAULT_MARGIN
    );
  }

  function test_enableProofOfReserveFeedZeroAddress() public {
    vm.startPrank(defaultAdmin);
    vm.expectRevert(
      abi.encodeWithSelector(IProofOfReserveAggregator.ZeroAddress.selector)
    );
    proofOfReserveAggregator.enableProofOfReserveFeed(
      address(0),
      address(feed_1),
      DEFAULT_MARGIN
    );

    vm.expectRevert(
      abi.encodeWithSelector(IProofOfReserveAggregator.ZeroAddress.selector)
    );
    proofOfReserveAggregator.enableProofOfReserveFeed(
      address(asset_1),
      address(0),
      DEFAULT_MARGIN
    );
  }

  function test_enableProofOfReserveFeedOnlyOwner(address caller) public {
    vm.assume(caller != defaultAdmin);
    vm.prank(caller);
    vm.expectRevert(
      abi.encodeWithSelector(
        Ownable.OwnableUnauthorizedAccount.selector,
        caller
      )
    );
    proofOfReserveAggregator.enableProofOfReserveFeed(
      address(asset_1),
      address(feed_1),
      DEFAULT_MARGIN
    );
  }

  function test_enableProofOfReserveFeedWithBridgeWrapper(
    address asset,
    address feed,
    address _bridgeWrapper,
    uint16 _margin
  ) public {
    vm.assume(
      asset != address(0) && feed != address(0) && _bridgeWrapper != address(0)
    );
    uint256 margin = bound(_margin, 0, proofOfReserveAggregator.MAX_MARGIN());
    vm.prank(defaultAdmin);

    vm.expectEmit();
    emit IProofOfReserveAggregator.ProofOfReserveFeedStateChanged(
      asset,
      feed,
      _bridgeWrapper,
      margin,
      true
    );
    proofOfReserveAggregator.enableProofOfReserveFeedWithBridgeWrapper(
      asset,
      feed,
      _bridgeWrapper,
      margin
    );
  }

  function test_enableProofOfReserveFeedWithBridgeWrapperAlreadyEnable(
    address asset,
    address feed,
    address _bridgeWrapper
  ) public {
    vm.assume(
      asset != address(0) && feed != address(0) && _bridgeWrapper != address(0)
    );
    vm.startPrank(defaultAdmin);
    proofOfReserveAggregator.enableProofOfReserveFeedWithBridgeWrapper(
      asset,
      feed,
      _bridgeWrapper,
      DEFAULT_MARGIN
    );

    vm.expectRevert(
      abi.encodeWithSelector(
        IProofOfReserveAggregator.FeedAlreadyEnabled.selector
      )
    );
    proofOfReserveAggregator.enableProofOfReserveFeedWithBridgeWrapper(
      asset,
      feed,
      _bridgeWrapper,
      DEFAULT_MARGIN
    );
  }

  function test_enableProofOfReserveFeedWithBridgeWrapperZeroAddress() public {
    vm.startPrank(defaultAdmin);
    vm.expectRevert(
      abi.encodeWithSelector(IProofOfReserveAggregator.ZeroAddress.selector)
    );
    proofOfReserveAggregator.enableProofOfReserveFeedWithBridgeWrapper(
      address(0),
      address(feed_3),
      address(bridgeWrapper),
      DEFAULT_MARGIN
    );

    vm.expectRevert(
      abi.encodeWithSelector(IProofOfReserveAggregator.ZeroAddress.selector)
    );
    proofOfReserveAggregator.enableProofOfReserveFeedWithBridgeWrapper(
      address(current_asset_3),
      address(0),
      address(bridgeWrapper),
      DEFAULT_MARGIN
    );

    vm.expectRevert(
      abi.encodeWithSelector(IProofOfReserveAggregator.ZeroAddress.selector)
    );
    proofOfReserveAggregator.enableProofOfReserveFeedWithBridgeWrapper(
      address(current_asset_3),
      address(feed_3),
      address(0),
      DEFAULT_MARGIN
    );
  }

  function test_enableProofOfReserveFeedWithBridgeWrapperOnlyOwner(
    address caller
  ) public {
    vm.assume(caller != defaultAdmin);

    vm.prank(caller);

    vm.expectRevert(
      abi.encodeWithSelector(
        Ownable.OwnableUnauthorizedAccount.selector,
        caller
      )
    );
    proofOfReserveAggregator.enableProofOfReserveFeedWithBridgeWrapper(
      address(current_asset_3),
      address(feed_3),
      address(bridgeWrapper),
      DEFAULT_MARGIN
    );
  }

  function test_disableProofOfReserveFeed(address asset, address feed) public {
    test_enableProofOfReserveFeed(
      asset,
      feed,
      uint16(proofOfReserveAggregator.MAX_MARGIN())
    );
    vm.prank(defaultAdmin);

    vm.expectEmit();
    emit IProofOfReserveAggregator.ProofOfReserveFeedStateChanged(
      asset,
      address(0),
      address(0),
      0,
      false
    );
    proofOfReserveAggregator.disableProofOfReserveFeed(asset);
  }

  function test_disableProofOfReserveFeedOnlyOwner(address caller) public {
    vm.assume(caller != defaultAdmin);

    vm.prank(caller);

    vm.expectRevert(
      abi.encodeWithSelector(
        Ownable.OwnableUnauthorizedAccount.selector,
        caller
      )
    );
    proofOfReserveAggregator.disableProofOfReserveFeed(address(asset_1));
  }

  function test_areAllReservesBacked() public {
    _configureProofOfReserveForAssets(proofOfReserveExecutorV3);

    address[] memory assets = new address[](3);
    assets[0] = address(asset_1);
    assets[1] = address(asset_2);
    assets[2] = address(current_asset_3);

    (
      bool areReservesBacked,
      bool[] memory unbackedAssetsFlags
    ) = proofOfReserveAggregator.areAllReservesBacked(assets);

    assertTrue(areReservesBacked);

    for (uint256 i = 0; i < unbackedAssetsFlags.length; i++) {
      assertFalse(unbackedAssetsFlags[i]);
    }
  }

  function test_areAllReservesBackedOneNotBacked() public {
    _configureProofOfReserveForAssets(proofOfReserveExecutorV3);

    address[] memory assets = new address[](3);
    assets[0] = address(asset_1);
    assets[1] = address(asset_2);
    assets[2] = address(current_asset_3);

    _mintBacked(asset_1, 1 ether);
    _mintBacked(asset_2, 1 ether);
    _mintUnbacked(current_asset_3, 1 ether);

    (
      bool areReservesBacked,
      bool[] memory unbackedAssetsFlags
    ) = proofOfReserveAggregator.areAllReservesBacked(assets);

    assertFalse(areReservesBacked);

    assertFalse(unbackedAssetsFlags[0]);
    assertFalse(unbackedAssetsFlags[1]);
    assertTrue(unbackedAssetsFlags[2]);
  }

  function test_getters() public {
    test_enableProofOfReserveFeedWithBridgeWrapper(
      address(current_asset_3),
      address(feed_3),
      address(bridgeWrapper),
      uint16(proofOfReserveAggregator.MAX_MARGIN())
    );

    assertEq(
      proofOfReserveAggregator.getProofOfReserveFeedForAsset(
        address(current_asset_3)
      ),
      address(feed_3)
    );
    assertEq(
      proofOfReserveAggregator.getBridgeWrapperForAsset(
        address(current_asset_3)
      ),
      address(bridgeWrapper)
    );
  }
}
