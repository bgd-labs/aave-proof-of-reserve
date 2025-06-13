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
    _mintBacked(tokenList.usdx, 1 ether);

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

    // change tokenList.usdx margin
    vm.prank(defaultAdmin);
    proofOfReserveAggregator.setAssetMargin(tokenList.usdx, margin);

    // mint backed what PoR reported
    _mintBacked(tokenList.usdx, answer);
    // mint excess unbacked
    uint256 excess = _percentMulDivUp(answer, margin);
    _mintUnbacked(tokenList.usdx, excess);

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
    _mintUnbacked(tokenList.usdx, 1);

    address[] memory assets = proofOfReserveExecutorV3.getAssets();

    (bool areReservesBacked, ) = proofOfReserveAggregator.areAllReservesBacked(
      assets
    );
    assertFalse(areReservesBacked);
  }

  function test_areAllReservesBackedOneNotBacked() public {
    _mintBacked(tokenList.usdx, 1 ether);
    _mintBacked(tokenList.weth, 1 ether);
    _mintUnbacked(tokenList.wbtc, 1 ether);

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
    _setPoRAnswer(tokenList.usdx, answer);

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
    _mintUnbacked(tokenList.usdx, totalSupply);

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
      feed_1,
      address(0),
      margin,
      true
    );
    proofOfReserveAggregator.enableProofOfReserveFeed(asset, feed_1, margin);
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
    proofOfReserveAggregator.enableProofOfReserveFeed(asset, feed_1, margin);
  }

  function test_enableProofOfReserveFeedAlreadyEnable(address asset) public {
    _skipAddresses(asset);
    vm.startPrank(defaultAdmin);
    proofOfReserveAggregator.enableProofOfReserveFeed(
      asset,
      feed_1,
      DEFAULT_MARGIN
    );

    vm.expectRevert(
      abi.encodeWithSelector(
        IProofOfReserveAggregator.FeedAlreadyEnabled.selector
      )
    );
    proofOfReserveAggregator.enableProofOfReserveFeed(
      asset,
      feed_1,
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
      feed_1,
      DEFAULT_MARGIN
    );

    vm.expectRevert(
      abi.encodeWithSelector(IProofOfReserveAggregator.ZeroAddress.selector)
    );
    proofOfReserveAggregator.enableProofOfReserveFeed(
      tokenList.usdx,
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
      tokenList.usdx,
      feed_1,
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
      feed_1,
      bridgeWrapper,
      margin,
      true
    );
    proofOfReserveAggregator.enableProofOfReserveFeedWithBridgeWrapper(
      asset,
      feed_1,
      bridgeWrapper,
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
      feed_1,
      bridgeWrapper,
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
      feed_3,
      bridgeWrapper,
      DEFAULT_MARGIN
    );

    vm.expectRevert(
      abi.encodeWithSelector(
        IProofOfReserveAggregator.FeedAlreadyEnabled.selector
      )
    );
    proofOfReserveAggregator.enableProofOfReserveFeedWithBridgeWrapper(
      asset,
      feed_3,
      bridgeWrapper,
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
      feed_3,
      bridgeWrapper,
      DEFAULT_MARGIN
    );

    vm.expectRevert(
      abi.encodeWithSelector(IProofOfReserveAggregator.ZeroAddress.selector)
    );
    proofOfReserveAggregator.enableProofOfReserveFeedWithBridgeWrapper(
      current_asset_3,
      address(0),
      bridgeWrapper,
      DEFAULT_MARGIN
    );

    vm.expectRevert(
      abi.encodeWithSelector(IProofOfReserveAggregator.ZeroAddress.selector)
    );
    proofOfReserveAggregator.enableProofOfReserveFeedWithBridgeWrapper(
      current_asset_3,
      feed_3,
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
      current_asset_3,
      feed_3,
      bridgeWrapper,
      DEFAULT_MARGIN
    );
  }

  function test_setAssetMargin(uint256 margin) public {
    margin = bound(margin, 0, proofOfReserveAggregator.MAX_MARGIN());

    vm.prank(defaultAdmin);
    vm.expectEmit();
    emit IProofOfReserveAggregator.ProofOfReserveFeedStateChanged(
      tokenList.usdx,
      feed_1,
      address(0),
      margin,
      true
    );
    proofOfReserveAggregator.setAssetMargin(tokenList.usdx, margin);
  }

  function test_setAssetMarginAssetNotEnabled(address asset) public {
    _skipAddresses(asset);

    vm.prank(defaultAdmin);

    vm.expectRevert(
      abi.encodeWithSelector(IProofOfReserveAggregator.AssetNotEnabled.selector)
    );
    proofOfReserveAggregator.setAssetMargin(asset, DEFAULT_MARGIN);
  }

  function test_setAssetMarginInvalidMargin(uint256 margin) public {
    margin = bound(
      margin,
      proofOfReserveAggregator.MAX_MARGIN() + 1,
      type(uint256).max
    );

    vm.prank(defaultAdmin);

    vm.expectRevert(
      abi.encodeWithSelector(IProofOfReserveAggregator.InvalidMargin.selector)
    );
    proofOfReserveAggregator.setAssetMargin(tokenList.usdx, margin);
  }

  function test_setAssetMarginOnlyOwner(address caller) public {
    vm.assume(caller != defaultAdmin);

    vm.prank(caller);

    vm.expectRevert(
      abi.encodeWithSelector(
        Ownable.OwnableUnauthorizedAccount.selector,
        caller
      )
    );
    proofOfReserveAggregator.setAssetMargin(tokenList.usdx, DEFAULT_MARGIN);
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
    proofOfReserveAggregator.disableProofOfReserveFeed(tokenList.usdx);
  }

  function test_getters() public view {
    assertEq(
      proofOfReserveAggregator.getProofOfReserveFeedForAsset(tokenList.wbtc),
      feed_3
    );
    assertEq(
      proofOfReserveAggregator.getBridgeWrapperForAsset(tokenList.wbtc),
      bridgeWrapper
    );
    assertEq(
      proofOfReserveAggregator.getMarginForAsset(tokenList.wbtc),
      DEFAULT_MARGIN
    );
  }

  function _percentMulDivUp(
    uint256 value,
    uint256 percent
  ) internal pure returns (uint256) {
    return value.mulDiv(percent, PERCENTAGE_FACTOR, Math.Rounding.Ceil);
  }

  function _skipAddresses(address asset) internal view {
    vm.assume(asset != tokenList.usdx);
    vm.assume(asset != tokenList.weth);
    vm.assume(asset != tokenList.wbtc);
    vm.assume(asset != address(0));
  }
}
