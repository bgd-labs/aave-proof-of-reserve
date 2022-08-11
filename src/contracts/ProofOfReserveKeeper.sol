// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAaveProofOfReserve} from '../interfaces/IAaveProofOfReserve.sol';
import {KeeperCompatible} from 'lib/chainlink-brownie-contracts/contracts/src/v0.8/KeeperCompatible.sol';

contract ProofOfReserveKeeper is
  IAaveProofOfReserve,
  KeeperCompatibleInterface
{
  // struct Reserve {
  //   address asseet;
  //   address proofOfReserveFeed;
  // }

  address[] public assets;
  mapping(address => address) public proofOfReserves;

  function addReserve(address asset, address reserveFeed) public {
    // require risk admin access
    // should we add asset if it already exists?
    // should we use extra mapping ?
    proofOfReserves[asset] = reserveFeed;

    for (uint256 i = 0; i < assets.length; i++) {
      if (assets[i] == asset) {
        return;
      }
    }

    assets.push(bridgedAsset);
  }

  function removeReserve(address asset) public {
    // require risk admin access
    for (uint256 i = 0; i < assets.length; i++) {
      if (assets[i] == asset) {
        // remove
      }
    }
  }

  function checkUpkeep(
    bytes calldata /* checkData */
  )
    external
    view
    override
    returns (
      bool upkeepNeeded,
      bytes memory /* performData */
    )
  {
    upkeepNeeded = false;
  }

  function performUpkeep(
    bytes calldata /* performData */
  ) external override {}
}
