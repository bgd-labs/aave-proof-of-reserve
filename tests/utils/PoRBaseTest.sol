// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';
import {MockERC20} from './mocks/MockERC20.sol';
import {MockPoRFeed} from './mocks/MockPoRFeed.sol';
import {AvaxBridgeWrapper} from '../../src/contracts/AvaxBridgeWrapper.sol';
import {ProofOfReserveAggregator} from '../../src/contracts/ProofOfReserveAggregator.sol';
import {ProofOfReserveExecutorV2} from '../../src/contracts/ProofOfReserveExecutorV2.sol';
import {ProofOfReserveExecutorV3} from '../../src/contracts/ProofOfReserveExecutorV3.sol';
import {IProofOfReserveExecutor} from '../../src/interfaces/IProofOfReserveExecutor.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveV2Ethereum} from 'aave-address-book/AaveV2Ethereum.sol';

abstract contract PoRBaseTest is Test {
  address public asset_1;
  address public asset_2;
  address public deprecated_asset_3;
  address public current_asset_3;

  address public feed_1;
  address public feed_2;
  address public feed_3;

  address public bridgeWrapper;
  ProofOfReserveAggregator public proofOfReserveAggregator;
  ProofOfReserveExecutorV2 public proofOfReserveExecutorV2;
  ProofOfReserveExecutorV3 public proofOfReserveExecutorV3;

  address public defaultAdmin = vm.addr(0x1000);

  uint256 public assetsHolderPrivateKey = 0x4000;
  address public assetsHolder = vm.addr(assetsHolderPrivateKey);

  uint16 public constant DEFAULT_MARGIN = 5_00;

  bool isAggregatorTest;

  function setUp() public virtual {}

  function _deployTokens() internal {
    asset_1 = address(new MockERC20('asset 1', 'A1'));
    asset_2 = address(new MockERC20('asset 2', 'A2'));

    deprecated_asset_3 = address(new MockERC20('asset 3', 'A3'));
    current_asset_3 = address(new MockERC20('asset 3', 'A3'));
    bridgeWrapper = address(
      new AvaxBridgeWrapper(current_asset_3, deprecated_asset_3)
    );

    vm.label(asset_1, 'asset_1');
    vm.label(asset_2, 'asset_2');
    vm.label(current_asset_3, 'current_asset_3');
    vm.label(deprecated_asset_3, 'deprecated_asset_3');
    vm.label(bridgeWrapper, 'bridgeWrapper');
  }

  function _deployFeeds() internal {
    feed_1 = address(new MockPoRFeed());
    feed_2 = address(new MockPoRFeed());
    feed_3 = address(new MockPoRFeed());

    vm.label(feed_1, 'feed_1');
    vm.label(feed_2, 'feed_2');
    vm.label(feed_3, 'feed_3');
  }

  function _setUpIntegrationTest() internal {
    _deployFeeds();

    vm.startPrank(defaultAdmin);

    // deploy PoR
    proofOfReserveAggregator = new ProofOfReserveAggregator(defaultAdmin);
    proofOfReserveExecutorV2 = new ProofOfReserveExecutorV2(
      address(AaveV2Ethereum.POOL_ADDRESSES_PROVIDER),
      address(proofOfReserveAggregator),
      defaultAdmin
    );
    proofOfReserveExecutorV3 = new ProofOfReserveExecutorV3(
      address(AaveV3Ethereum.POOL_ADDRESSES_PROVIDER),
      address(proofOfReserveAggregator),
      defaultAdmin
    );

    // deploy bridge wrapper
    deprecated_asset_3 = address(new MockERC20('asset 3', 'A3'));
    bridgeWrapper = address(
      new AvaxBridgeWrapper(
        AaveV3EthereumAssets.WBTC_UNDERLYING,
        deprecated_asset_3
      )
    );

    vm.stopPrank();

    // give emergency admin to executorV3 and poolAdmin to executor V2
    vm.startPrank(address(AaveV3Ethereum.ACL_ADMIN));
    AaveV3Ethereum.ACL_MANAGER.addEmergencyAdmin(
      address(proofOfReserveExecutorV3)
    );
    AaveV2Ethereum.POOL_ADDRESSES_PROVIDER.setPoolAdmin(
      address(proofOfReserveExecutorV2)
    );

    vm.stopPrank();

    // setup assets PoR
    address[] memory assets = new address[](3);
    assets[0] = AaveV3EthereumAssets.USDT_UNDERLYING;
    assets[1] = AaveV3EthereumAssets.USDC_UNDERLYING;
    assets[2] = AaveV3EthereumAssets.WBTC_UNDERLYING;

    vm.startPrank(defaultAdmin);
    proofOfReserveExecutorV2.enableAssets(assets);
    proofOfReserveExecutorV3.enableAssets(assets);

    proofOfReserveAggregator.enableProofOfReserveFeed(
      AaveV3EthereumAssets.USDT_UNDERLYING,
      feed_1,
      DEFAULT_MARGIN
    );
    proofOfReserveAggregator.enableProofOfReserveFeed(
      AaveV3EthereumAssets.USDC_UNDERLYING,
      feed_2,
      DEFAULT_MARGIN
    );
    proofOfReserveAggregator.enableProofOfReserveFeedWithBridgeWrapper(
      AaveV3EthereumAssets.WBTC_UNDERLYING,
      feed_3,
      bridgeWrapper,
      DEFAULT_MARGIN
    );

    // set feeds answer
    MockPoRFeed(feed_1).setAnswer(
      int256(MockERC20(AaveV3EthereumAssets.USDT_UNDERLYING).totalSupply())
    );
    MockPoRFeed(feed_2).setAnswer(
      int256(MockERC20(AaveV3EthereumAssets.USDC_UNDERLYING).totalSupply())
    );
    MockPoRFeed(feed_3).setAnswer(
      int256(MockERC20(AaveV3EthereumAssets.WBTC_UNDERLYING).totalSupply())
    );

    vm.stopPrank();
  }

  function _setUpAggregatorTest() internal {
    isAggregatorTest = true;
    _deployTokens();
    _deployFeeds();

    // deploy aggregator and enable assets PoR
    vm.startPrank(defaultAdmin);
    proofOfReserveAggregator = new ProofOfReserveAggregator(defaultAdmin);
    proofOfReserveAggregator.enableProofOfReserveFeed(
      asset_1,
      feed_1,
      DEFAULT_MARGIN
    );
    proofOfReserveAggregator.enableProofOfReserveFeed(
      asset_2,
      feed_2,
      DEFAULT_MARGIN
    );
    proofOfReserveAggregator.enableProofOfReserveFeedWithBridgeWrapper(
      current_asset_3,
      feed_3,
      bridgeWrapper,
      DEFAULT_MARGIN
    );
    vm.stopPrank();
  }

  function _mintBacked(address asset, uint256 amount) internal {
    _mintUnbacked(asset, amount);
    _setPoRAnswer(asset, int256(MockERC20(asset).totalSupply()));
  }

  function _mintUnbacked(address asset, uint256 amount) internal {
    if (isAggregatorTest) {
      MockERC20(asset).mint(assetsHolder, amount);
    } else {
      deal(asset, assetsHolder, amount, true);
    }
  }

  function _burn(address asset, uint256 amount) internal {
    MockERC20(asset).burn(assetsHolder, amount);
  }

  function _setPoRAnswer(address asset, int256 answer) internal {
    if (asset == asset_1 || asset == AaveV3EthereumAssets.USDT_UNDERLYING) {
      MockPoRFeed(feed_1).setAnswer(answer);
    } else if (
      asset == asset_2 || asset == AaveV3EthereumAssets.USDC_UNDERLYING
    ) {
      MockPoRFeed(feed_2).setAnswer(answer);
    } else {
      MockPoRFeed(feed_3).setAnswer(answer);
    }
  }
}
