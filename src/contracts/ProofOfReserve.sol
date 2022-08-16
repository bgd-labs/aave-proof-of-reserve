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
  mapping(address => address) internal _proofOfReserveList;
  address[] internal _assets;

  function enableProofOfReserveFeed(address asset, address proofOfReserveFeed)
    public
    onlyOwner
  {
    if (_proofOfReserveList[asset] == address(0)) {
      _assets.push(asset);
    }

    _proofOfReserveList[asset] = proofOfReserveFeed;
    emit ProofOfReserveFeedStateChanged(asset, proofOfReserveFeed, true);
  }

  function disableProofOfReserveFeed(address asset) public onlyOwner {
    delete _proofOfReserveList[asset];
    _deleteAssetFromArray(asset);
    emit ProofOfReserveFeedStateChanged(asset, address(0), false);
  }

  function _deleteAssetFromArray(address asset) internal {
    for (uint256 i = 0; i < _assets.length; i++) {
      if (_assets[i] == asset) {
        if (i != _assets.length - 1) {
          _assets[i] = _assets[_assets.length - 1];
        }

        _assets.pop();
        break;
      }
    }
  }

  function areAllReservesBacked() public view returns (bool) {
    return _areAllReservesBacked();
  }

  function _areAllReservesBacked() internal view returns (bool) {
    for (uint256 i = 0; i < _assets.length; i++) {
      address assetAddress = _assets[i];
      address feedAddress = _proofOfReserveList[assetAddress];

      if (feedAddress != address(0)) {
        (, int256 answer, , , ) = AggregatorV3Interface(feedAddress)
          .latestRoundData();

        if (answer < 0 || int256(IERC20(assetAddress).totalSupply()) > answer) {
          return false;
        }
      }
    }

    return true;
  }

  function executeEmergencyAction(IPool pool, PoolVersion version) public {
    if (!_areAllReservesBacked()) {
      _disableBorrowing(pool, version);
      // TODO: emit event for every unbacked reserve
      emit EmergencyActionExecuted(msg.sender);
    }
  }

  function _disableBorrowing(IPool pool, PoolVersion version) internal {
    address[] memory reservesList = pool.getReservesList();

    if (version == PoolVersion.V2) {
      _disableBorrowingV2(pool, reservesList);
    } else if (version == PoolVersion.V3) {
      _disableBorrowingV3(pool, reservesList);
    }
  }

  function _disableBorrowingV2(IPool pool, address[] memory reservesList)
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

  function _disableBorrowingV3(IPool pool, address[] memory reservesList)
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
