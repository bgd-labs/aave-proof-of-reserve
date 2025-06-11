// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';

import {MockERC20} from './mocks/MockERC20.sol';
import {MockPoRFeed} from './mocks/MockPoRFeed.sol';
import {MockPoolV2, MockPoolV3} from './mocks/MockPool.sol';
import {MockAddressesProvider} from './mocks/MockAddressesProvider.sol';
import {AvaxBridgeWrapper} from '../../src/contracts/AvaxBridgeWrapper.sol';
import {MockPoolConfiguratorV2, MockPoolConfiguratorV3} from './mocks/MockPoolConfigurator.sol';
import {ProofOfReserveAggregator} from '../../src/contracts/ProofOfReserveAggregator.sol';
import {ProofOfReserveExecutorV2} from '../../src/contracts/ProofOfReserveExecutorV2.sol';
import {ProofOfReserveExecutorV3} from '../../src/contracts/ProofOfReserveExecutorV3.sol';
import {IProofOfReserveExecutor} from '../../src/interfaces/IProofOfReserveExecutor.sol';

abstract contract PoRBaseTest is Test {
  address public asset_1;
  address public asset_2;
  address public deprecated_asset_3;
  address public current_asset_3;

  address public feed_1;
  address public feed_2;
  address public feed_3;

  address public bridgeWrapper;
  MockAddressesProvider public addressesProvider;
  ProofOfReserveAggregator public proofOfReserveAggregator;

  MockPoolV2 public poolV2;
  MockPoolConfiguratorV2 public poolConfiguratorV2;
  ProofOfReserveExecutorV2 public proofOfReserveExecutorV2;

  MockPoolV3 public poolV3;
  MockPoolConfiguratorV3 public poolConfiguratorV3;
  ProofOfReserveExecutorV3 public proofOfReserveExecutorV3;

  address public defaultAdmin = vm.addr(0x1000);

  uint256 public assetsHolderPrivateKey = 0x4000;
  address public assetsHolder = vm.addr(assetsHolderPrivateKey);

  function setUp() public virtual {}

  function _deployTokensAndFeeds() internal {
    asset_1 = address(new MockERC20('asset 1', 'A1'));
    asset_2 = address(new MockERC20('asset 2', 'A2'));

    deprecated_asset_3 = address(new MockERC20('asset 3', 'A3'));
    current_asset_3 = address(new MockERC20('asset 3', 'A3'));
    bridgeWrapper = address(
      new AvaxBridgeWrapper(current_asset_3, deprecated_asset_3)
    );

    feed_1 = address(new MockPoRFeed());
    feed_2 = address(new MockPoRFeed());
    feed_3 = address(new MockPoRFeed());

    vm.label(asset_1, 'asset_1');
    vm.label(asset_2, 'asset_2');
    vm.label(current_asset_3, 'current_asset_3');
    vm.label(deprecated_asset_3, 'deprecated_asset_3');
    vm.label(address(bridgeWrapper), 'bridgeWrapper');
    vm.label(feed_1, 'feed_1');
    vm.label(feed_2, 'feed_2');
    vm.label(feed_3, 'feed_3');
  }

  function _setUpV2(bool enableAssets) internal {
    _deployTokensAndFeeds();

    addressesProvider = new MockAddressesProvider();
    poolV2 = new MockPoolV2(address(addressesProvider));
    poolConfiguratorV2 = new MockPoolConfiguratorV2(poolV2);

    addressesProvider.setAddressesV2(
      address(poolV2),
      address(poolConfiguratorV2)
    );

    vm.startPrank(defaultAdmin);

    proofOfReserveAggregator = new ProofOfReserveAggregator();
    proofOfReserveExecutorV2 = new ProofOfReserveExecutorV2(
      address(addressesProvider),
      address(proofOfReserveAggregator),
      defaultAdmin
    );
    vm.stopPrank();

    if (enableAssets) {
      _configureProofOfReserveForAssets(proofOfReserveExecutorV2);
      _initPoolReserves();
    }
  }

  function _setUpV3(bool enableAssets) internal {
    _deployTokensAndFeeds();

    addressesProvider = new MockAddressesProvider();
    poolV3 = new MockPoolV3(address(addressesProvider));
    poolConfiguratorV3 = new MockPoolConfiguratorV3(poolV3);

    addressesProvider.setAddressesV3(
      address(poolV3),
      address(poolConfiguratorV3)
    );

    vm.startPrank(defaultAdmin);

    proofOfReserveAggregator = new ProofOfReserveAggregator();
    proofOfReserveExecutorV3 = new ProofOfReserveExecutorV3(
      address(addressesProvider),
      address(proofOfReserveAggregator),
      defaultAdmin
    );
    vm.stopPrank();

    if (enableAssets) {
      _configureProofOfReserveForAssets(proofOfReserveExecutorV3);
      _initPoolReserves();
    }
  }

  function _configureProofOfReserveForAssets(
    IProofOfReserveExecutor proofOfReserveExecutor
  ) internal {
    vm.startPrank(defaultAdmin);

    address[] memory assets = new address[](3);
    assets[0] = asset_1;
    assets[1] = asset_2;
    assets[2] = current_asset_3;
    proofOfReserveExecutor.enableAssets(assets);
    proofOfReserveAggregator.enableProofOfReserveFeed(asset_1, feed_1);
    proofOfReserveAggregator.enableProofOfReserveFeed(asset_2, feed_2);
    proofOfReserveAggregator.enableProofOfReserveFeedWithBridgeWrapper(
      current_asset_3,
      feed_3,
      bridgeWrapper
    );

    vm.stopPrank();
  }

  function _mintBacked(address asset, uint256 amount) internal {
    _mintUnbacked(asset, amount);
    _setPoRAnswer(asset, int256(MockERC20(asset).totalSupply()));
  }

  function _mintUnbacked(address asset, uint256 amount) internal {
    MockERC20(asset).mint(assetsHolder, amount);
  }

  function _burn(address asset, uint256 amount) internal {
    MockERC20(asset).burn(assetsHolder, amount);
  }

  function _setPoRAnswer(address asset, int256 answer) internal {
    if (asset == asset_1) {
      MockPoRFeed(feed_1).setAnswer(answer);
    } else if (asset == asset_2) {
      MockPoRFeed(feed_2).setAnswer(answer);
    } else {
      MockPoRFeed(feed_3).setAnswer(answer);
    }
  }

  function _initPoolReserves() internal virtual {}
}
