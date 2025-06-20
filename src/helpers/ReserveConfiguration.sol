// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {DataTypes as DataTypesV2} from 'aave-address-book/AaveV2.sol';
import {DataTypes as DataTypesV3} from 'aave-address-book/AaveV3.sol';

/**
 * @title ReserveConfiguration library Adapted
 * @author BGD Labs
 * @notice Implements the bitmap logic to handle the reserve configuration
 * @dev Adapted version to support both V2 and V3 configurations with minimal
 * bitmap logic required by the ProofOfReserveExecutor contract.
 */
library ReserveConfiguration {
  uint256 internal constant FROZEN_MASK =                0x0000000000000000000000000000000000000000000000000200000000000000; // prettier-ignore
  uint256 internal constant BORROWING_MASK =             0x0000000000000000000000000000000000000000000000000400000000000000; // prettier-ignore

  /**
   * @dev Gets the borrowing state of the reserve
   * @param self The V2 reserve configuration
   * @return The borrowing state
   **/
  function getBorrowingEnabled(
    DataTypesV2.ReserveConfigurationMap memory self
  ) internal pure returns (bool) {
    return (self.data & BORROWING_MASK) != 0;
  }

  /**
   * @dev Gets the frozen state of the reserve
   * @param self The V2 reserve configuration
   * @return The frozen state
   **/
  function getFrozen(DataTypesV2.ReserveConfigurationMap memory self) internal pure returns (bool) {
    return (self.data & FROZEN_MASK) != 0;
  }

  /**
   * @dev Gets the frozen state of the reserve
   * @param self The V3 reserve configuration
   * @return The frozen state
   **/
  function getFrozen(DataTypesV3.ReserveConfigurationMap memory self) internal pure returns (bool) {
    return (self.data & FROZEN_MASK) != 0;
  }
}
