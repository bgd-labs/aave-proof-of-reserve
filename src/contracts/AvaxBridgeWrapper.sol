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
  IERC20Metadata public immutable CURRENT_BRIDGE;
  // contract for the deprecated bridge
  IERC20 public immutable DEPRECATED_BRIDGE;

  /**
   * @notice Constructor.
   * @param currentBridgeAddress The address of the actual bridge for token
   * @param deprecatedBridgeAddress The address of the deprecated bridge for token
   */
  constructor(address currentBridgeAddress, address deprecatedBridgeAddress) {
    CURRENT_BRIDGE = IERC20Metadata(currentBridgeAddress);
    DEPRECATED_BRIDGE = IERC20(deprecatedBridgeAddress);
  }

  /// @inheritdoc IReservesProvider
  function getTotalReserves() external view returns (uint256) {
    return CURRENT_BRIDGE.totalSupply() + DEPRECATED_BRIDGE.totalSupply();
  }

  /// @inheritdoc IReservesProvider
  function name() external view returns (string memory) {
    return CURRENT_BRIDGE.name();
  }

  /// @inheritdoc IReservesProvider
  function symbol() external view returns (string memory) {
    return CURRENT_BRIDGE.symbol();
  }

  /// @inheritdoc IReservesProvider
  function decimals() external view returns (uint8) {
    return CURRENT_BRIDGE.decimals();
  }
}
