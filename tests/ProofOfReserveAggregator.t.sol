// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PoRBaseTest} from './utils/PoRBaseTest.sol';
import {IProofOfReserveAggregator} from '../src/interfaces/IProofOfReserveAggregator.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {Math} from '@openzeppelin/contracts/utils/math/Math.sol';
import {MockPoRFeed} from './utils/mocks/MockPoRFeed.sol';

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
    uint16 margin,
    uint256 excess
  ) public {
    margin = uint16(bound(margin, 0, proofOfReserveAggregator.MAX_MARGIN()));

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
    excess = bound(excess, 0, _percentMulDivUp(answer, margin));
    _mintUnbacked(tokenList.usdx, excess);

    address[] memory assets = proofOfReserveExecutorV3.getAssets();

    (bool areReservesBacked, ) = proofOfReserveAggregator.areAllReservesBacked(
      assets
    );
    assertTrue(areReservesBacked);
  }

  function test_areAllReservesBackedTotalSupplyAboveMargin(
    uint256 answer,
    uint16 margin,
    uint256 excess
  ) public {
    test_areAllReservesBackedTotalSupplyWithinMargin(answer, margin, excess);

    // get current asset margin from the test above
    margin = proofOfReserveAggregator.getMarginForAsset(tokenList.usdx);
    // get current answer
    int256 answer = MockPoRFeed(feed_1).latestAnswer();
    // calculate excess within margin
    uint256 excessWithinMargin = _percentMulDivUp(uint256(answer), margin);

    excess = bound(excess, excessWithinMargin + 1, type(uint128).max);

    // mint excess above margin
    _mintUnbacked(tokenList.usdx, excess);

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

  function test_enableProofOfReserveFeed(
    address asset,
    address feed,
    uint16 margin
  ) public {
    vm.assume(feed != address(0));
    _skipAddresses(asset);

    margin = uint16(bound(margin, 0, proofOfReserveAggregator.MAX_MARGIN()));

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

    assertEq(
      proofOfReserveAggregator.getProofOfReserveFeedForAsset(asset),
      feed
    );
    assertEq(proofOfReserveAggregator.getMarginForAsset(asset), margin);
    assertEq(
      proofOfReserveAggregator.getBridgeWrapperForAsset(asset),
      address(0)
    );
  }

  function test_enableProofOfReserveFeedInvalidMargin(
    address asset,
    uint16 margin
  ) public {
    _skipAddresses(asset);

    margin = uint16(
      bound(margin, proofOfReserveAggregator.MAX_MARGIN() + 1, type(uint16).max)
    );

    vm.prank(defaultAdmin);

    vm.expectRevert(
      abi.encodeWithSelector(IProofOfReserveAggregator.InvalidMargin.selector)
    );
    proofOfReserveAggregator.enableProofOfReserveFeed(asset, feed_1, margin);
  }

  function test_enableProofOfReserveFeedAlreadyEnable(
    address asset,
    address feed,
    uint16 margin
  ) public {
    _skipAddresses(asset);
    vm.assume(feed != address(0));

    margin = uint16(bound(margin, 0, proofOfReserveAggregator.MAX_MARGIN()));

    vm.startPrank(defaultAdmin);
    proofOfReserveAggregator.enableProofOfReserveFeed(asset, feed, margin);

    vm.expectRevert(
      abi.encodeWithSelector(
        IProofOfReserveAggregator.FeedAlreadyEnabled.selector
      )
    );
    proofOfReserveAggregator.enableProofOfReserveFeed(asset, feed, margin);
  }

  function test_enableProofOfReserveFeedZeroAddress(address asset, address feed, uint16 margin) public {
    margin = uint16(bound(margin, 0, proofOfReserveAggregator.MAX_MARGIN()));
    _skipAddresses(asset);
    vm.assume(feed != address(0));

    vm.startPrank(defaultAdmin);
    vm.expectRevert(
      abi.encodeWithSelector(IProofOfReserveAggregator.ZeroAddress.selector)
    );
    proofOfReserveAggregator.enableProofOfReserveFeed(
      address(0),
      feed,
      margin
    );

    vm.expectRevert(
      abi.encodeWithSelector(IProofOfReserveAggregator.ZeroAddress.selector)
    );
    proofOfReserveAggregator.enableProofOfReserveFeed(
      asset,
      address(0),
      margin
    );
  }

  function test_enableProofOfReserveFeedOnlyOwner(
    address caller,
    address asset,
    address feed,
    uint16 margin
  ) public {
    vm.assume(caller != defaultAdmin);
    vm.prank(caller);
    vm.expectRevert(
      abi.encodeWithSelector(
        Ownable.OwnableUnauthorizedAccount.selector,
        caller
      )
    );
    proofOfReserveAggregator.enableProofOfReserveFeed(asset, feed, margin);
  }

  function test_enableProofOfReserveFeedWithBridgeWrapper(
    address asset,
    address feed,
    address _bridgeWrapper,
    uint16 margin
  ) public {
    vm.assume(feed != address(0));
    vm.assume(_bridgeWrapper != address(0));
    _skipAddresses(asset);
    margin = uint16(bound(margin, 0, proofOfReserveAggregator.MAX_MARGIN()));

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

    assertEq(
      proofOfReserveAggregator.getProofOfReserveFeedForAsset(asset),
      feed
    );
    assertEq(proofOfReserveAggregator.getMarginForAsset(asset), margin);
    assertEq(
      proofOfReserveAggregator.getBridgeWrapperForAsset(asset),
      _bridgeWrapper
    );
  }

  function test_enableProofOfReserveFeedWithBridgeWrapperInvalidMargin(
    address asset,
    uint16 margin
  ) public {
    _skipAddresses(asset);

    margin = uint16(
      bound(margin, proofOfReserveAggregator.MAX_MARGIN() + 1, type(uint16).max)
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

  function test_setAssetMargin(uint16 margin) public {
    margin = uint16(bound(margin, 0, proofOfReserveAggregator.MAX_MARGIN()));

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

  function test_setAssetMarginInvalidMargin(uint16 margin) public {
    margin = uint16(
      bound(margin, proofOfReserveAggregator.MAX_MARGIN() + 1, type(uint16).max)
    );

    vm.prank(defaultAdmin);

    vm.expectRevert(
      abi.encodeWithSelector(IProofOfReserveAggregator.InvalidMargin.selector)
    );
    proofOfReserveAggregator.setAssetMargin(tokenList.usdx, margin);
  }

  function test_setAssetMarginOnlyOwner(
    address caller,
    address asset,
    uint16 margin
  ) public {
    vm.assume(caller != defaultAdmin);

    vm.prank(caller);

    vm.expectRevert(
      abi.encodeWithSelector(
        Ownable.OwnableUnauthorizedAccount.selector,
        caller
      )
    );
    proofOfReserveAggregator.setAssetMargin(asset, margin);
  }

  function test_disableProofOfReserveFeed(address asset, address feed) public {
    test_enableProofOfReserveFeed(asset, feed, DEFAULT_MARGIN);
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
