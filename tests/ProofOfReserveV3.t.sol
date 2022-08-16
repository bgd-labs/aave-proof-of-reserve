// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';

import {ProofOfReserveV3} from '../src/contracts/ProofOfReserveV3.sol';

contract ProofOfReserveTest is Test {
  ProofOfReserveV3 public proofOfReserve;

  function setUp() public {
    proofOfReserve = new ProofOfReserveV3();
  }

  // add reserve check that it is added

  // remove reserve check removed

  // check backed - should be true

  // V2 and V3
  // add reserve
  // mock feed
  // execute emergency action
  // check that all assets borrowing is disabled
}
