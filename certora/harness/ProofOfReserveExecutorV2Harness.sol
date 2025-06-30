// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../munged/contracts/ProofOfReserveExecutorV2.sol';
import {IProofOfReserveExecutor} from '../munged/interfaces/IProofOfReserveExecutor.sol';

contract ProofOfReserveExecutorV2Harness is ProofOfReserveExecutorV2 {
  using EnumerableSet for EnumerableSet.AddressSet;
    
  constructor(
    address poolAddressesProviderAddress,
    address proofOfReserveAggregatorAddress,
    address owner
  )
    ProofOfReserveExecutorV2(
      poolAddressesProviderAddress,
      proofOfReserveAggregatorAddress,
      owner
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
    return _enabledAssets.contains(asset);
  }

  function getAssetsLength() public view returns (uint256) {
    return _enabledAssets.length();
  }

  function getAsset(uint256 index) public view returns (address) {
    if (index >= _enabledAssets.length()) {
      return address(0);
    }
    return _enabledAssets.at(index);
  }

  function _disableBorrowing() internal override {
    _disableBorrowingCalled = true;
  }


  
  function get_values_len() external view returns (uint256) {
    return _enabledAssets.length();
  }

  function get_value(uint256 index) external view returns (address) {
    return _enabledAssets.at(index);
  }

  function contains(address asset) external view returns (bool) {
    return _enabledAssets.contains(asset);
  }
}
