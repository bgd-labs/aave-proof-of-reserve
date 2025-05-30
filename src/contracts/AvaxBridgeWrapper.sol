// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IERC20Metadata} from '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

import {IReservesProvider} from '../interfaces/IReservesProvider.sol';

/**
 * @author BGD Labs
 * @dev Contract to wrap total supply of bridged tokens on Avalanche as there can possibly be
 * two bridges for one asset
 */
contract AvaxBridgeWrapper is IReservesProvider {
  // contract for the actual bridge
  IERC20Metadata public immutable currentBridge;
  // contract for the deprecated bridge
  IERC20 public immutable deprecatedBridge;

  /**
   * @notice Constructor.
   * @param currentBridgeAddress The address of the actual bridge for token
   * @param deprecatedBridgeAddress The address of the deprecated bridge for token
   */
  constructor(address currentBridgeAddress, address deprecatedBridgeAddress) {
    currentBridge = IERC20Metadata(currentBridgeAddress);
    deprecatedBridge = IERC20(deprecatedBridgeAddress);
  }

  /// @inheritdoc IReservesProvider
  function getTotalReserves() external view returns (uint256) {
    return currentBridge.totalSupply() + deprecatedBridge.totalSupply();
  }

  /// @inheritdoc IReservesProvider
  function name() external view returns (string memory) {
    return currentBridge.name();
  }

  /// @inheritdoc IReservesProvider
  function symbol() external view returns (string memory) {
    return currentBridge.symbol();
  }

  /// @inheritdoc IReservesProvider
  function decimals() external view returns (uint8) {
    return currentBridge.decimals();
  }
}
