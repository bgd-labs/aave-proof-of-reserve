// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PoRBaseTest} from './utils/PoRBaseTest.sol';
import {IProofOfReserveAggregator} from '../src/interfaces/IProofOfReserveAggregator.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

contract ProofOfReserveAggregatorTest is PoRBaseTest {
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

  function test_enableProofOfReserveFeed(address asset) public {
    _skipAddresses(asset);
    vm.prank(defaultAdmin);

    vm.expectEmit();
    emit IProofOfReserveAggregator.ProofOfReserveFeedStateChanged(
      asset,
      feed_1,
      address(0),
      true
    );
    proofOfReserveAggregator.enableProofOfReserveFeed(asset, feed_1);
  }

  function test_enableProofOfReserveFeedAlreadyEnable(address asset) public {
    _skipAddresses(asset);
    vm.startPrank(defaultAdmin);
    proofOfReserveAggregator.enableProofOfReserveFeed(asset, feed_1);

    vm.expectRevert(
      abi.encodeWithSelector(
        IProofOfReserveAggregator.FeedAlreadyEnabled.selector
      )
    );
    proofOfReserveAggregator.enableProofOfReserveFeed(asset, feed_1);
  }

  function test_enableProofOfReserveFeedZeroAddress() public {
    vm.startPrank(defaultAdmin);
    vm.expectRevert(
      abi.encodeWithSelector(IProofOfReserveAggregator.ZeroAddress.selector)
    );
    proofOfReserveAggregator.enableProofOfReserveFeed(address(0), feed_1);

    vm.expectRevert(
      abi.encodeWithSelector(IProofOfReserveAggregator.ZeroAddress.selector)
    );
    proofOfReserveAggregator.enableProofOfReserveFeed(
      tokenList.usdx,
      address(0)
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
    proofOfReserveAggregator.enableProofOfReserveFeed(tokenList.usdx, feed_1);
  }

  function test_enableProofOfReserveFeedWithReserveProvider(
    address asset
  ) public {
    _skipAddresses(asset);
    vm.prank(defaultAdmin);

    vm.expectEmit();
    emit IProofOfReserveAggregator.ProofOfReserveFeedStateChanged(
      asset,
      feed_1,
      bridgeWrapper,
      true
    );
    proofOfReserveAggregator.enableProofOfReserveFeedWithReserveProvider(
      asset,
      feed_1,
      bridgeWrapper
    );
  }

  function test_enableProofOfReserveFeedWithReserveProviderAlreadyEnable(
    address asset
  ) public {
    _skipAddresses(asset);

    vm.startPrank(defaultAdmin);
    proofOfReserveAggregator.enableProofOfReserveFeedWithReserveProvider(
      asset,
      feed_3,
      bridgeWrapper
    );

    vm.expectRevert(
      abi.encodeWithSelector(
        IProofOfReserveAggregator.FeedAlreadyEnabled.selector
      )
    );
    proofOfReserveAggregator.enableProofOfReserveFeedWithReserveProvider(
      asset,
      feed_3,
      bridgeWrapper
    );
  }

  function test_enableProofOfReserveFeedWithReserveProviderZeroAddress()
    public
  {
    vm.startPrank(defaultAdmin);
    vm.expectRevert(
      abi.encodeWithSelector(IProofOfReserveAggregator.ZeroAddress.selector)
    );
    proofOfReserveAggregator.enableProofOfReserveFeedWithReserveProvider(
      address(0),
      feed_3,
      bridgeWrapper
    );

    vm.expectRevert(
      abi.encodeWithSelector(IProofOfReserveAggregator.ZeroAddress.selector)
    );
    proofOfReserveAggregator.enableProofOfReserveFeedWithReserveProvider(
      current_asset_3,
      address(0),
      bridgeWrapper
    );

    vm.expectRevert(
      abi.encodeWithSelector(IProofOfReserveAggregator.ZeroAddress.selector)
    );
    proofOfReserveAggregator.enableProofOfReserveFeedWithReserveProvider(
      current_asset_3,
      feed_3,
      address(0)
    );
  }

  function test_enableProofOfReserveFeedWithReserveProviderOnlyOwner(
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
    proofOfReserveAggregator.enableProofOfReserveFeedWithReserveProvider(
      current_asset_3,
      feed_3,
      bridgeWrapper
    );
  }

  function test_disableProofOfReserveFeed(address asset) public {
    test_enableProofOfReserveFeed(asset);
    vm.prank(defaultAdmin);

    vm.expectEmit();
    emit IProofOfReserveAggregator.ProofOfReserveFeedStateChanged(
      asset,
      address(0),
      address(0),
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
      proofOfReserveAggregator.getReservesProviderForAsset(tokenList.wbtc),
      bridgeWrapper
    );
  }

  function _skipAddresses(address asset) internal view {
    vm.assume(asset != tokenList.usdx);
    vm.assume(asset != tokenList.weth);
    vm.assume(asset != tokenList.wbtc);
    vm.assume(asset != address(0));
  }
}
