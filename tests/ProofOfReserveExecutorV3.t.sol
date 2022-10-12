// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';

import {AggregatorV3Interface} from 'chainlink-brownie-contracts/interfaces/AggregatorV3Interface.sol';
import {IPool} from '../src/dependencies/IPool.sol';
import {IPoolAddressesProvider} from '../src/dependencies/IPoolAddressesProvider.sol';
import {IACLManager} from './helpers/IACLManager.sol';
import {ProofOfReserveAggregator} from '../src/contracts/ProofOfReserveAggregator.sol';
import {ProofOfReserveExecutorV3} from '../src/contracts/ProofOfReserveExecutorV3.sol';
import {AvaxBridgeWrapper} from '../src/contracts/AvaxBridgeWrapper.sol';

contract ProofOfReserveExecutorV3Test is Test {
  ProofOfReserveAggregator private proofOfReserveAggregator;
  ProofOfReserveExecutorV3 private proofOfReserveExecutorV3;
  AvaxBridgeWrapper private bridgeWrapper;

  uint256 private avalancheFork;
  address private constant ADDRESS_PROVIDER =
    0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb;

  address private constant ASSET_1 = address(1234);
  address private constant PROOF_OF_RESERVE_FEED_1 = address(4321);

  address private constant AAVEE = 0x63a72806098Bd3D9520cC43356dD78afe5D386D9;
  address private constant AAVEE_DEPRECATED =
    0x8cE2Dee54bB9921a2AE0A63dBb2DF8eD88B91dD9;
  address private constant PORF_AAVE =
    0x14C4c668E34c09E1FBA823aD5DB47F60aeBDD4F7;
  address private constant BTCB = 0x152b9d0FdC40C096757F570A51E494bd4b943E50;
  address private constant PORF_BTCB =
    0x99311B4bf6D8E3D3B4b9fbdD09a1B0F4Ad8e06E9;

  address private constant DAIE = 0xd586E7F844cEa2F87f50152665BCbc2C279D8d70;
  address private constant PORF_DAIE =
    0x976D7fAc81A49FA71EF20694a3C56B9eFB93c30B;

  address private constant LINKE = 0x5947BB275c521040051D82396192181b413227A3;
  address private constant PORF_LINKE =
    0x943cEF1B112Ca9FD7EDaDC9A46477d3812a382b6;

  address private constant WBTCE = 0x50b7545627a5162F82A992c33b87aDc75187B218;
  address private constant PORF_WBTCE =
    0xebEfEAA58636DF9B20a4fAd78Fad8759e6A20e87;

  address private constant WETHE = 0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB;
  address private constant PORF_WETHE =
    0xDDaf9290D057BfA12d7576e6dADC109421F31948;

  event AssetStateChanged(address indexed asset, bool enabled);
  event AssetIsNotBacked(address indexed asset);
  event EmergencyActionExecuted();

  function setUp() public {
    avalancheFork = vm.createFork('https://api.avax.network/ext/bc/C/rpc');
    vm.selectFork(avalancheFork);
    proofOfReserveAggregator = new ProofOfReserveAggregator();
    proofOfReserveExecutorV3 = new ProofOfReserveExecutorV3(
      ADDRESS_PROVIDER,
      address(proofOfReserveAggregator)
    );
    bridgeWrapper = new AvaxBridgeWrapper(AAVEE, AAVEE_DEPRECATED);
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
    emit AssetIsNotBacked(address(bridgeWrapper));

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
    proofOfReserveAggregator.enableProofOfReserveFeed(
      address(bridgeWrapper),
      PORF_AAVE
    );
    proofOfReserveAggregator.enableProofOfReserveFeed(BTCB, PORF_BTCB);
    proofOfReserveAggregator.enableProofOfReserveFeed(WBTCE, PORF_WBTCE);
    proofOfReserveAggregator.enableProofOfReserveFeed(DAIE, PORF_DAIE);
    proofOfReserveAggregator.enableProofOfReserveFeed(WETHE, PORF_WETHE);
    proofOfReserveAggregator.enableProofOfReserveFeed(LINKE, PORF_LINKE);
  }

  function enableAssetsOnExecutor() private {
    address[] memory assets = new address[](6);
    assets[0] = address(bridgeWrapper);
    assets[1] = BTCB;
    assets[2] = WBTCE;
    assets[3] = DAIE;
    assets[4] = WETHE;
    assets[5] = LINKE;

    proofOfReserveExecutorV3.enableAssets(assets);
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
