// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAaveProofOfReserve} from '../interfaces/IAaveProofOfReserve.sol';
import {KeeperCompatible} from 'lib/chainlink-brownie-contracts/contracts/src/v0.8/KeeperCompatible.sol';

contract ProofOfReserveKeeper is IAaveProofOfReserve {
  mapping(address => address) public proofOfReserves;

  function addReserve(address asset, address reserveFeed) public {
    // isOwnable
    proofOfReserves[asset] = reserveFeed;
  }

  function removeReserve(address asset) public {
    proofOfReserves[asset] = address(0);
  }

  function checkMarket(address pool, PoolVersion version) public {
    return true;
  }

  function executeEmergencyAction(address pool, PoolVersion version) public {}
}
