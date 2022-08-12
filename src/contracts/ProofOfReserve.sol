// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAaveProofOfReserve} from '../interfaces/IAaveProofOfReserve.sol';
import {KeeperCompatible} from 'lib/chainlink-brownie-contracts/contracts/src/v0.8/KeeperCompatible.sol';
import {Ownable} from 'lib/solidity-utils/src/contracts/oz-common/Ownable.sol';

contract ProofOfReserveKeeper is IAaveProofOfReserve, Ownable {
  mapping(address => address) public proofOfReserves;

  function addReserve(address asset, address reserveFeed) public onlyOwner {
    // isOwnable
    proofOfReserves[asset] = reserveFeed;
  }

  function removeReserve(address asset) public onlyOwner {
    proofOfReserves[asset] = address(0);
  }

  function checkMarket(address pool, PoolVersion version) public {
    return true;
  }

  function executeEmergencyAction(address pool, PoolVersion version) public {}
}
