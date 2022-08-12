// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAaveProofOfReserve} from '../interfaces/IAaveProofOfReserve.sol';
import {AggregatorV3Interface} from 'lib/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import {Ownable} from 'lib/solidity-utils/src/contracts/oz-common/Ownable.sol';
import {IERC20} from 'lib/solidity-utils/src/contracts/oz-common/interfaces/IERC20.sol';
import {IPool} from 'lib/aave-v3-core/contracts/interfaces/IPool.sol';

contract ProofOfReserveKeeper is IAaveProofOfReserve, Ownable {
  mapping(address => address) public proofOfReserveList;

  function addReserve(address reserve, address proofOfReserveFeed)
    public
    onlyOwner
  {
    proofOfReserveList[reserve] = proofOfReserveFeed;
  }

  function removeReserve(address reserve) public onlyOwner {
    proofOfReserveList[reserve] = address(0);
  }

  function anyReserveIsNotProofed(address poolAddress)
    public
    view
    returns (bool)
  {
    IPool pool = IPool(poolAddress);
    address[] reservesList = pool.getReservesList();

    return anyReseveFromListIsNotProofed(reservesList);
  }

  function anyReseveFromListIsNotProofed(address[] reservesList) private {
    for (uint256 i = 0; i < reservesList.length; i++) {
      address assetAddress = reservesList[i];
      address feedAddress = proofOfReserveList[assetAddress];

      if (feed != address(0)) {
        AggregatorV3Interface aggregator = AggregatorV3Interface(feedAddress);
        IERC20 token = IERC20(assetAddress);

        (, int256 answer, , , ) = aggregator.latestRoundData();

        if (answer > token.totalSupply()) {
          return true;
        }
      }
    }

    return false;
  }

  function executeEmergencyAction(address poolAddress) public {
    IPool pool = IPool(poolAddress);
    address[] reservesList = pool.getReservesList();
  }
}
