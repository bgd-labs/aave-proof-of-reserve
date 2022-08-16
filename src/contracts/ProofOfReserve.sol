// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AggregatorV3Interface} from 'chainlink-brownie-contracts/interfaces/AggregatorV3Interface.sol';
import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {IAaveProofOfReserve} from '../interfaces/IAaveProofOfReserve.sol';
import {IPool} from '../dependencies/IPool.sol';
import {IPoolAddressProvider} from '../dependencies/IPoolAddressProvider.sol';
import {IPoolConfigurator} from '../dependencies/IPoolConfigurator.sol';

contract ProofOfReserve is IAaveProofOfReserve, Ownable {
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

  function areAllReservesBacked(address poolAddress)
    public
    view
    returns (bool)
  {
    IPool pool = IPool(poolAddress);
    address[] memory reservesList = pool.getReservesList();

    address unbackedReserve = getUnbackedReserve(reservesList);

    return (unbackedReserve == address(0));
  }

  function getUnbackedReserve(address[] memory reservesList)
    internal
    view
    returns (address)
  {
    for (uint256 i = 0; i < reservesList.length; i++) {
      address assetAddress = reservesList[i];
      address feedAddress = proofOfReserveList[assetAddress];

      if (feedAddress != address(0)) {
        AggregatorV3Interface aggregator = AggregatorV3Interface(feedAddress);
        IERC20 token = IERC20(assetAddress);

        (, int256 answer, , , ) = aggregator.latestRoundData();

        if (answer > int256(token.totalSupply())) {
          return assetAddress;
        }
      }
    }

    return address(0);
  }

  function executeEmergencyAction(address poolAddress, PoolVersion version)
    public
  {
    IPool pool = IPool(poolAddress);
    address[] memory reservesList = pool.getReservesList();

    address unbackedReserve = getUnbackedReserve(reservesList);

    if (unbackedReserve != address(0)) {
      disableBorrowing(pool, version, reservesList);
      emit EmergencyActionExecuted(unbackedReserve, msg.sender);
    }
  }

  function disableBorrowing(
    IPool pool,
    PoolVersion version,
    address[] memory reservesList
  ) private {
    if (version == PoolVersion.V2) {
      disableBorrowingV2(pool, reservesList);
    } else if (version == PoolVersion.V3) {
      disableBorrowingV3(pool, reservesList);
    }
  }

  function disableBorrowingV2(IPool pool, address[] memory reservesList)
    internal
  {
    IPoolAddressProvider addressProvider = pool.getAddressesProvider();
    IPoolConfigurator configurator = IPoolConfigurator(
      addressProvider.getLendingPoolConfigurator()
    );

    for (uint256 i = 0; i < reservesList.length; i++) {
      configurator.disableBorrowingOnReserve(reservesList[i]);
    }
  }

  function disableBorrowingV3(IPool pool, address[] memory reservesList)
    internal
  {
    IPoolAddressProvider addressProvider = pool.ADDRESSES_PROVIDER();
    IPoolConfigurator configurator = IPoolConfigurator(
      addressProvider.getPoolConfigurator()
    );

    for (uint256 i = 0; i < reservesList.length; i++) {
      configurator.setReserveBorrowing(reservesList[i], false);
    }
  }
}
