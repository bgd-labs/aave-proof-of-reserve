// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';

import {Deploy} from '../scripts/DeployProofOfReserveAvax.s.sol';

contract DeployProofOfReserveAvaxTest is Test {
  function setUp() public {
    vm.createSelectFork('avalanche');
  }

  function testAAA() public {
    Deploy script = new Deploy();
    script.run();

    assertEq(address(script.aggregator()), address(0));
  }
}
