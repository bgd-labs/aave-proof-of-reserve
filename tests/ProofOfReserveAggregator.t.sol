// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PoRBaseTest} from './utils/PoRBaseTest.sol';
import {IProofOfReserveAggregator} from '../src/interfaces/IProofOfReserveAggregator.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {Math} from '@openzeppelin/contracts/utils/math/Math.sol';

contract ProofOfReserveAggregatorTest is PoRBaseTest {
  using Math for uint256;

  uint256 public constant PERCENTAGE_FACTOR = 100_00;

  function setUp() public override {
    _setUpV3({enableAssets: true});
  }

  function test_areAllReservesBacked() public {
    address[] memory assets = proofOfReserveExecutorV3.getAssets();
    _mintBacked(asset_1, 1 ether);

    (
      bool areReservesBacked,
      bool[] memory unbackedAssetsFlags
    ) = proofOfReserveAggregator.areAllReservesBacked(assets);

    assertTrue(areReservesBacked);

    for (uint256 i = 0; i < unbackedAssetsFlags.length; i++) {
      assertFalse(unbackedAssetsFlags[i]);
    }
  }

  function test_areAllReservesBackedTotalSupplyWithinMargin(
    uint256 answer,
    uint256 margin
  ) public {
    margin = bound(margin, 0, proofOfReserveAggregator.MAX_MARGIN());
  
    // avoid div by zero
    uint256 maxAnswer = margin == 0
      ? (type(uint128).max - 1)
      : ((type(uint128).max - 1) / margin);
    
    answer = bound(answer, 0, maxAnswer);

    // change asset_1 margin
    vm.startPrank(defaultAdmin);
    proofOfReserveAggregator.disableProofOfReserveFeed(address(asset_1));
    proofOfReserveAggregator.enableProofOfReserveFeed(
      address(asset_1),
      address(feed_1),
      margin
    );

    // mint backed what PoR reported
    _mintBacked(asset_1, answer);
    // mint excess unbacked
    uint256 excess = _percentMulDiv(answer, margin);
    _mintUnbacked(asset_1, excess);

    address[] memory assets = proofOfReserveExecutorV3.getAssets();

    (bool areReservesBacked, ) = proofOfReserveAggregator.areAllReservesBacked(
      assets
    );
    assertTrue(areReservesBacked);
  }

  function test_areAllReservesBackedTotalSupply1WeiAboveMargin(
    uint256 answer,
    uint256 margin
  ) public {
    test_areAllReservesBackedTotalSupplyWithinMargin(answer, margin);

    // mint 1 wei above margin
    _mintUnbacked(asset_1, 1);
    
    address[] memory assets = proofOfReserveExecutorV3.getAssets();

    (bool areReservesBacked, ) = proofOfReserveAggregator.areAllReservesBacked(
      assets
    );
    assertFalse(areReservesBacked);
  }

  function test_areAllReservesBackedOneNotBacked() public {
    _mintBacked(asset_1, 1 ether);
    _mintBacked(asset_2, 1 ether);
    _mintUnbacked(current_asset_3, 1 ether);

    address[] memory assets = proofOfReserveExecutorV3.getAssets();
    (
      bool areReservesBacked,
      bool[] memory unbackedAssetsFlags
    ) = proofOfReserveAggregator.areAllReservesBacked(assets);

    assertFalse(areReservesBacked);

    assertFalse(unbackedAssetsFlags[0]);
    assertFalse(unbackedAssetsFlags[1]);
    assertTrue(unbackedAssetsFlags[2]);
  }

  function test_areAllReservesBackedNegativeAnswer(int256 answer) public {
    answer = bound(answer, -type(int256).max, -1);
    _setPoRAnswer(asset_1, answer);

    address[] memory assets = proofOfReserveExecutorV3.getAssets();
    (
      bool areReservesBacked,
      bool[] memory unbackedAssetsFlags
    ) = proofOfReserveAggregator.areAllReservesBacked(assets);

    assertFalse(areReservesBacked);

    assertTrue(unbackedAssetsFlags[0]);
    assertFalse(unbackedAssetsFlags[1]);
    assertFalse(unbackedAssetsFlags[2]);
  }

  function test_areAllReservesBackedTotalSupplyTooBig(
    uint256 totalSupply
  ) public {
    totalSupply = bound(totalSupply, type(uint128).max, type(uint256).max);
    _mintUnbacked(asset_1, totalSupply);

    address[] memory assets = proofOfReserveExecutorV3.getAssets();
    (
      bool areReservesBacked,
      bool[] memory unbackedAssetsFlags
    ) = proofOfReserveAggregator.areAllReservesBacked(assets);

    assertFalse(areReservesBacked);

    assertTrue(unbackedAssetsFlags[0]);
    assertFalse(unbackedAssetsFlags[1]);
    assertFalse(unbackedAssetsFlags[2]);
  }

  function test_enableProofOfReserveFeed(address asset, uint256 margin) public {
    _skipAddresses(asset);

    margin = bound(margin, 0, proofOfReserveAggregator.MAX_MARGIN());

    vm.prank(defaultAdmin);

    vm.expectEmit();
    emit IProofOfReserveAggregator.ProofOfReserveFeedStateChanged(
      asset,
      address(feed_1),
      address(0),
      margin,
      true
    );
    proofOfReserveAggregator.enableProofOfReserveFeed(
      asset,
      address(feed_1),
      margin
    );
  }

  function test_enableProofOfReserveFeedInvalidMargin(
    address asset,
    uint256 margin
  ) public {
    _skipAddresses(asset);

    margin = bound(
      margin,
      proofOfReserveAggregator.MAX_MARGIN() + 1,
      type(uint256).max
    );

    vm.prank(defaultAdmin);

    vm.expectRevert(
      abi.encodeWithSelector(IProofOfReserveAggregator.InvalidMargin.selector)
    );
    proofOfReserveAggregator.enableProofOfReserveFeed(
      address(asset),
      address(feed_1),
      margin
    );
  }

  function test_enableProofOfReserveFeedAlreadyEnable(address asset) public {
    _skipAddresses(asset);
    vm.startPrank(defaultAdmin);
    proofOfReserveAggregator.enableProofOfReserveFeed(
      asset,
      address(feed_1),
      DEFAULT_MARGIN
    );

    vm.expectRevert(
      abi.encodeWithSelector(
        IProofOfReserveAggregator.FeedAlreadyEnabled.selector
      )
    );
    proofOfReserveAggregator.enableProofOfReserveFeed(
      asset,
      address(feed_1),
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
    uint256 margin
  ) public {
    _skipAddresses(asset);
    margin = bound(margin, 0, proofOfReserveAggregator.MAX_MARGIN());

    vm.prank(defaultAdmin);

    vm.expectEmit();
    emit IProofOfReserveAggregator.ProofOfReserveFeedStateChanged(
      asset,
      address(feed_1),
      address(bridgeWrapper),
      margin,
      true
    );
    proofOfReserveAggregator.enableProofOfReserveFeedWithBridgeWrapper(
      asset,
      address(feed_1),
      address(bridgeWrapper),
      margin
    );
  }

  function test_enableProofOfReserveFeedWithBridgeWrapperInvalidMargin(
    address asset,
    uint256 margin
  ) public {
    _skipAddresses(asset);

    margin = bound(
      margin,
      proofOfReserveAggregator.MAX_MARGIN() + 1,
      type(uint256).max
    );

    vm.prank(defaultAdmin);

    vm.expectRevert(
      abi.encodeWithSelector(IProofOfReserveAggregator.InvalidMargin.selector)
    );
    proofOfReserveAggregator.enableProofOfReserveFeedWithBridgeWrapper(
      address(asset),
      address(feed_1),
      address(bridgeWrapper),
      margin
    );
  }

  function test_enableProofOfReserveFeedWithBridgeWrapperAlreadyEnable(
    address asset
  ) public {
    _skipAddresses(asset);

    vm.startPrank(defaultAdmin);
    proofOfReserveAggregator.enableProofOfReserveFeedWithBridgeWrapper(
      asset,
      address(feed_3),
      address(bridgeWrapper),
      DEFAULT_MARGIN
    );

    vm.expectRevert(
      abi.encodeWithSelector(
        IProofOfReserveAggregator.FeedAlreadyEnabled.selector
      )
    );
    proofOfReserveAggregator.enableProofOfReserveFeedWithBridgeWrapper(
      asset,
      address(feed_3),
      address(bridgeWrapper),
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

  function test_disableProofOfReserveFeed(address asset) public {
    test_enableProofOfReserveFeed(asset, DEFAULT_MARGIN);
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

  function test_getters() public view {
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
    assertEq(
      proofOfReserveAggregator.getMarginForAsset(address(current_asset_3)),
      DEFAULT_MARGIN
    );
  }

  function _percentMulDiv(
    uint256 value,
    uint256 percent
  ) internal pure returns (uint256) {
    return value.mulDiv(percent, PERCENTAGE_FACTOR);
  }

  function _skipAddresses(address asset) internal view {
    vm.assume(asset != address(asset_1));
    vm.assume(asset != address(asset_2));
    vm.assume(asset != address(current_asset_3));
    vm.assume(asset != address(0));
  }
}
