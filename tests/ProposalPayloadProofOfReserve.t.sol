// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;
import {Test} from 'forge-std/Test.sol';

import {ICollectorController} from '../src/dependencies/ICollectorController.sol';
import {ProposalPayloadProofOfReserve} from '../src/proposal/ProposalPayloadProofOfReserve.sol';
import {ProofOfReserveAggregator} from '../src/contracts/ProofOfReserveAggregator.sol';
import {ProofOfReserveExecutorV2} from '../src/contracts/ProofOfReserveExecutorV2.sol';
import {ProofOfReserveExecutorV3} from '../src/contracts/ProofOfReserveExecutorV3.sol';
import {ProofOfReserveKeeper} from '../src/contracts/ProofOfReserveKeeper.sol';
import {Deploy} from '../scripts/DeployProofOfReserveAvax.s.sol';
import {MockExecutor} from './MockExecutor.sol';
import {ConfiguratorMock} from './helpers/ConfiguratorMock.sol';
import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {AaveV2Avalanche, AaveV3Avalanche} from 'aave-address-book/AaveAddressBook.sol';

contract ProposalPayloadProofOfReserveTest is Test {
  address public constant GUARDIAN =
    address(0xa35b76E4935449E33C56aB24b23fcd3246f13470);

  MockExecutor internal _executor;

  event ChainlinkUpkeepRegistered(
    string indexed name,
    uint256 indexed upkeedId
  );

  function setUp() public {
    vm.createSelectFork('avalanche', 23712421);

    MockExecutor mockExecutor = new MockExecutor();
    vm.etch(GUARDIAN, address(mockExecutor).code);

    _executor = MockExecutor(GUARDIAN);
  }

  function testExecute() public {
    // deploy all contracts
    Deploy script = new Deploy();
    script.deployContracts();

    ProofOfReserveAggregator aggregator = script.aggregator();
    ProofOfReserveExecutorV2 executorV2 = script.executorV2();
    ProofOfReserveExecutorV3 executorV3 = script.executorV3();
    ProposalPayloadProofOfReserve proposal = script.proposal();

    vm.expectEmit(true, false, false, false);
    emit ChainlinkUpkeepRegistered('AaveProofOfReserveKeeperV2', 0);

    vm.expectEmit(true, false, false, false);
    emit ChainlinkUpkeepRegistered('AaveProofOfReserveKeeperV3', 0);

    // Execute proposal
    _executor.execute(address(proposal));

    // Assert
    (
      address[] memory assets,
      address[] memory proofOfReserveFeeds
    ) = _getAssetsAndFeeds();

    for (uint256 i; i < assets.length; ++i) {
      address enabledFeed = aggregator.getProofOfReserveFeedForAsset(assets[i]);
      assertEq(enabledFeed, proofOfReserveFeeds[i]);
    }

    bool areAllReservesBacked = executorV2.areAllReservesBacked();
    assertTrue(areAllReservesBacked);

    areAllReservesBacked = executorV3.areAllReservesBacked();
    assertTrue(areAllReservesBacked);

    AaveV3Avalanche.ACL_MANAGER.isRiskAdmin(address(executorV3));
  }

  function _getAssetsAndFeeds()
    internal
    pure
    returns (address[] memory, address[] memory)
  {
    address[] memory assets = new address[](6);
    address[] memory proofOfReserveFeeds = new address[](6);

    // AAVE.e
    assets[0] = 0x63a72806098Bd3D9520cC43356dD78afe5D386D9;
    proofOfReserveFeeds[0] = 0x14C4c668E34c09E1FBA823aD5DB47F60aeBDD4F7;

    // WETH.e
    assets[1] = 0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB;
    proofOfReserveFeeds[1] = 0xDDaf9290D057BfA12d7576e6dADC109421F31948;

    // DAI.e
    assets[2] = 0xd586E7F844cEa2F87f50152665BCbc2C279D8d70;
    proofOfReserveFeeds[2] = 0x976D7fAc81A49FA71EF20694a3C56B9eFB93c30B;

    // LINK.e
    assets[3] = 0x5947BB275c521040051D82396192181b413227A3;
    proofOfReserveFeeds[3] = 0x943cEF1B112Ca9FD7EDaDC9A46477d3812a382b6;

    // WBTC.e
    assets[4] = 0x50b7545627a5162F82A992c33b87aDc75187B218;
    proofOfReserveFeeds[4] = 0xebEfEAA58636DF9B20a4fAd78Fad8759e6A20e87;

    // BTC.b
    assets[5] = 0x152b9d0FdC40C096757F570A51E494bd4b943E50;
    proofOfReserveFeeds[5] = 0x99311B4bf6D8E3D3B4b9fbdD09a1B0F4Ad8e06E9;

    return (assets, proofOfReserveFeeds);
  }
}

// check:
// 	2) assets are enabled in aggregator v2
// 	3) assets are enabled in aggregator v3
// 	4) LendingPoolConfigurator is upgraded
// 	5) ExecutorV2 is PROOF_OF_RESERVE_ADMIN
// 	6) ExecutorV3 has risk admin role
// 	7) UpkeepV2 created
// 	8) UpkeepV3 created

// 	9) call something ?
