// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';

import {ProofOfReserve} from '../src/contracts/ProofOfReserve.sol';

contract ProofOfReserveTest is Test {
  ProofOfReserve public proofOfReserve;

  function setUp() public {
    proofOfReserve = new ProofOfReserve();
  }

  function testNumberIs42() public {
    address[] memory assets = new address[](0);
    (bool result, bool[] memory backedAssetsFlags) = proofOfReserve
      .areAllReservesBacked(assets);

    assertEq(backedAssetsFlags.length, 0);
    assertEq(result, true);
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
