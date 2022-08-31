// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {AggregatorV3Interface} from 'chainlink-brownie-contracts/interfaces/AggregatorV3Interface.sol';
import {Test} from 'forge-std/Test.sol';
import 'forge-std/console.sol';

import {ProofOfReserveAggregator} from '../src/contracts/ProofOfReserveAggregator.sol';
import {ProofOfReserveExecutorV3} from '../src/contracts/ProofOfReserveExecutorV3.sol';

import {IPool} from '../src/dependencies/IPool.sol';
import {IPoolAddressesProvider} from '../src/dependencies/IPoolAddressesProvider.sol';
import {IACLManager} from './helpers/IACLManager.sol';

contract ProofOfReserveExecutorV3Test is Test {
  ProofOfReserveAggregator private proofOfReserveAggregator;
  ProofOfReserveExecutorV3 private proofOfReserveExecutorV3;

  uint256 private avalancheFork;
  address private constant ADDRESS_PROVIDER =
    0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb;

  address private constant ASSET_1 = address(1234);
  address private constant PROOF_OF_RESERVE_FEED_1 = address(4321);

  address private constant AAVEE = 0x63a72806098Bd3D9520cC43356dD78afe5D386D9;
  address private constant PORF_AAVE =
    0x14C4c668E34c09E1FBA823aD5DB47F60aeBDD4F7;
  address private constant BTCB = 0x152b9d0FdC40C096757F570A51E494bd4b943E50;
  address private constant PORF_BTCB =
    0x99311B4bf6D8E3D3B4b9fbdD09a1B0F4Ad8e06E9;

  event AssetStateChanged(address indexed asset, bool enabled);
  event AssetIsNotBacked(address indexed asset);
  event EmergencyActionExecuted();

  function setUp() public {
    avalancheFork = vm.createFork('https://avalancherpc.com');
    vm.selectFork(avalancheFork);
    proofOfReserveAggregator = new ProofOfReserveAggregator();
    proofOfReserveExecutorV3 = new ProofOfReserveExecutorV3(
      ADDRESS_PROVIDER,
      address(proofOfReserveAggregator)
    );
  }

  function testExecuteEmergencyActionAllBacked() public {
    enableFeedsOnRegistry();
    enableAssetsOnExecutor();

    bool isBorrowingEnabled = proofOfReserveExecutorV3
      .isBorrowingEnabledForAtLeastOneAsset();

    assertEq(isBorrowingEnabled, true);
  }

  function testExecuteEmergencyActionV3() public {
    enableFeedsOnRegistry();
    enableAssetsOnExecutor();

    vm.mockCall(
      PORF_AAVE,
      abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
      abi.encode(1, 1, 1, 1, 1)
    );

    vm.mockCall(
      PORF_BTCB,
      abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
      abi.encode(1, 1, 1, 1, 1)
    );

    vm.expectEmit(true, false, false, true);
    emit AssetIsNotBacked(AAVEE);

    vm.expectEmit(true, false, false, true);
    emit AssetIsNotBacked(BTCB);

    vm.expectEmit(false, false, false, true);
    emit EmergencyActionExecuted();

    setRiskAdmin();

    proofOfReserveExecutorV3.executeEmergencyAction();

    bool isBorrowingEnabled = proofOfReserveExecutorV3
      .isBorrowingEnabledForAtLeastOneAsset();
    assertEq(isBorrowingEnabled, false);
  }

  // emergency action - executed and events are emmited

  function enableFeedsOnRegistry() private {
    proofOfReserveAggregator.enableProofOfReserveFeed(AAVEE, PORF_AAVE);
    proofOfReserveAggregator.enableProofOfReserveFeed(BTCB, PORF_BTCB);
  }

  function enableAssetsOnExecutor() private {
    proofOfReserveExecutorV3.enableAsset(AAVEE);
    proofOfReserveExecutorV3.enableAsset(BTCB);
  }

  function setRiskAdmin() private {
    IPoolAddressesProvider addressesProvider = IPoolAddressesProvider(
      ADDRESS_PROVIDER
    );
    IACLManager aclManager = IACLManager(addressesProvider.getACLManager());
    vm.prank(addressesProvider.getACLAdmin());
    aclManager.addRiskAdmin(address(proofOfReserveExecutorV3));
  }
}
