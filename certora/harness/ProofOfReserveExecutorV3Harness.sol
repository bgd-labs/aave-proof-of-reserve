// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../munged/contracts/ProofOfReserveExecutorV3.sol';
import {IProofOfReserveExecutor} from '../munged/interfaces/IProofOfReserveExecutor.sol';

contract ProofOfReserveExecutorV3Harness is ProofOfReserveExecutorV3 {
  using EnumerableSet for EnumerableSet.AddressSet;

  constructor(
    address poolAddressesProviderAddress,
    address proofOfReserveAggregatorAddress,
    address owner
  )
    ProofOfReserveExecutorV3(
      poolAddressesProviderAddress,
      proofOfReserveAggregatorAddress,
      owner
    )
  {}

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
