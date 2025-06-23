// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../munged/contracts/ProofOfReserveExecutorV2.sol';
import {IProofOfReserveExecutor} from '../munged/interfaces/IProofOfReserveExecutor.sol';

contract ProofOfReserveExecutorV2Harness is ProofOfReserveExecutorV2 {
  constructor(
    address poolAddressesProviderAddress,
    address proofOfReserveAggregatorAddress
  )
    ProofOfReserveExecutorV2(
      poolAddressesProviderAddress,
      proofOfReserveAggregatorAddress
    )
  {}

  bool public _disableBorrowingCalled = false;

  function enableAsset(address asset) public {
    address[] memory assetArr = new address[](1);
    assetArr[0] = asset;
    this.enableAssets(assetArr);
  }

  function disableAsset(address asset) public {
    address[] memory assetArr = new address[](1);
    assetArr[0] = asset;
    this.disableAssets(assetArr);
  }

  function getAssetState(address asset) public view returns (bool) {
    return _assetsState[asset];
  }

  function getAssetsLength() public view returns (uint256) {
    return _assets.length;
  }

  function getAsset(uint256 index) public view returns (address) {
    if (index >= _assets.length) {
      return address(0);
    }
    return _assets[index];
  }

  function _disableBorrowing() internal override {
    _disableBorrowingCalled = true;
  }
}
