// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';

import {ProofOfReserve} from '../src/contracts/ProofOfReserve.sol';

contract ProofOfReserveTest is Test {
  ProofOfReserve public proofOfReserve;

  function setUp() public {
    proofOfReserve = new ProofOfReserve();
  }
}
