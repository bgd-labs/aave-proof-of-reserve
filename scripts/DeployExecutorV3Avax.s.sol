// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';
import {AaveV3Avalanche, AaveV3AvalancheAssets} from 'aave-address-book/AaveV3Avalanche.sol';
import {GovernanceV3Avalanche} from 'aave-address-book/GovernanceV3Avalanche.sol';
import {ProofOfReserveExecutorV3} from '../src/contracts/ProofOfReserveExecutorV3.sol';

contract Deploy is Script {
  function run() external {
    vm.startBroadcast();

    address[] memory assets = new address[](5);
    assets[0] = AaveV3AvalancheAssets.AAVEe_UNDERLYING;
    assets[1] = AaveV3AvalancheAssets.WETHe_UNDERLYING;
    assets[2] = AaveV3AvalancheAssets.DAIe_UNDERLYING;
    assets[3] = AaveV3AvalancheAssets.LINKe_UNDERLYING;
    assets[4] = AaveV3AvalancheAssets.WBTCe_UNDERLYING;

    ProofOfReserveExecutorV3 executor = new ProofOfReserveExecutorV3(
      address(AaveV3Avalanche.POOL_ADDRESSES_PROVIDER),
      AaveV3Avalanche.PROOF_OF_RESERVE_AGGREGATOR
    );

    executor.enableAssets(assets);

    // send ownership to governance executor lvl 1
    executor.transferOwnership(GovernanceV3Avalanche.EXECUTOR_LVL_1);

    vm.stopBroadcast();
  }
}
