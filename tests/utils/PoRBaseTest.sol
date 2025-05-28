// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';

import {MockERC20} from './mocks/MockERC20.sol';
import {MockPoRFeed} from './mocks/MockPoRFeed.sol';
import {MockPoolV2, MockPoolV3} from './mocks/MockPool.sol';
import {MockAddressesProvider} from './mocks/MockAddressesProvider.sol';
import {MockPoolConfiguratorV2, MockPoolConfiguratorV3} from './mocks/MockPoolConfigurator.sol';
import {ProofOfReserveAggregator} from '../../src/contracts/ProofOfReserveAggregator.sol';
import {ProofOfReserveExecutorV2} from '../../src/contracts/ProofOfReserveExecutorV2.sol';
import {ProofOfReserveExecutorV3} from '../../src/contracts/ProofOfReserveExecutorV3.sol';
import {IProofOfReserveExecutor} from '../../src/interfaces/IProofOfReserveExecutor.sol';

abstract contract PoRBaseTest is Test {
  MockERC20 public asset_1;
  MockERC20 public asset_2;

  MockPoRFeed public feed_1;
  MockPoRFeed public feed_2;

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
    asset_1 = new MockERC20('asset 1', 'A1');
    asset_2 = new MockERC20('asset 2', 'A2');
    feed_1 = new MockPoRFeed();
    feed_2 = new MockPoRFeed();
  }

  function _setUpV2() internal {
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
      address(proofOfReserveAggregator)
    );

    _configureProofOfReserve(address(proofOfReserveExecutorV2));

    vm.stopPrank();
  }

  function _setUpV3() internal {
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
      address(proofOfReserveAggregator)
    );

    _configureProofOfReserve(address(proofOfReserveExecutorV3));

    vm.stopPrank();
  }

  function _configureProofOfReserve(address proofOfReserveExecutor) internal {
    address[] memory assets = new address[](2);
    assets[0] = address(asset_1);
    assets[1] = address(asset_2);
    IProofOfReserveExecutor(proofOfReserveExecutor).enableAssets(assets);
    proofOfReserveAggregator.enableProofOfReserveFeed(
      address(asset_1),
      address(feed_1)
    );
    proofOfReserveAggregator.enableProofOfReserveFeed(
      address(asset_2),
      address(feed_2)
    );
  }

  function _mintBacked(MockERC20 asset, uint256 amount) internal {
    _mint(asset, amount);
    _setPoRAnswer(asset, asset.totalSupply() + 1);
  }

  function _burnBacked(MockERC20 asset, uint256 amount) internal {
    _burn(asset, amount);
    _setPoRAnswer(asset, asset.totalSupply() + 1);
  }

  function _mint(MockERC20 asset, uint256 amount) internal {
    asset.mint(assetsHolder, amount);
  }

  function _burn(MockERC20 asset, uint256 amount) internal {
    asset.burn(assetsHolder, amount);
  }

  function _setPoRAnswer(MockERC20 asset, uint256 answer) internal {
    if (address(asset) == address(asset_1)) {
      feed_1.setAnswer(int256(answer));
    } else {
      feed_2.setAnswer(int256(answer));
    }
  }
}
