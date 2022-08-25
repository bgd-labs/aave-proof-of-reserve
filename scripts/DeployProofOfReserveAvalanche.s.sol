// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';
import {ProofOfReserveAggregator} from '../src/contracts/ProofOfReserveAggregator.sol';
import {ProofOfReserveExecutorV2} from '../src/contracts/ProofOfReserveExecutorV2.sol';

contract Deploy is Script {
  address public constant ADDRESS_PROVIDER_V2 =
    address(0xb6A86025F0FE1862B372cb0ca18CE3EDe02A318f);
  address public constant ADDRESS_PROVIDER_V3 =
    address(0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb);

  function run() external {
    vm.startBroadcast();

    ProofOfReserveAggregator proofOfReserveAggregator = new ProofOfReserveAggregator();

    new ProofOfReserveExecutorV2(
      ADDRESS_PROVIDER_V2,
      address(proofOfReserveAggregator)
    );

    new ProofOfReserveExecutorV3(
      ADDRESS_PROVIDER_V3,
      address(proofOfReserveAggregator)
    );

    vm.stopBroadcast();
  }
}
