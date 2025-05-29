// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DataTypes as DataTypesV2} from 'aave-address-book/AaveV2.sol';

library ReserveConfigurationV2 {
  uint256 constant FROZEN_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant BORROWING_MASK =             0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant STABLE_BORROWING_MASK =      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFF; // prettier-ignore

  uint256 constant IS_FROZEN_START_BIT_POSITION = 57;
  uint256 constant BORROWING_ENABLED_START_BIT_POSITION = 58;
  uint256 constant STABLE_BORROWING_ENABLED_START_BIT_POSITION = 59;

  function setFrozen(
    DataTypesV2.ReserveConfigurationMap memory self,
    bool frozen
  ) internal pure {
    self.data =
      (self.data & FROZEN_MASK) |
      (uint256(frozen ? 1 : 0) << IS_FROZEN_START_BIT_POSITION);
  }

  function getFrozen(
    DataTypesV2.ReserveConfigurationMap memory self
  ) internal pure returns (bool) {
    return (self.data & ~FROZEN_MASK) != 0;
  }

  function setStableRateBorrowingEnabled(
    DataTypesV2.ReserveConfigurationMap memory self,
    bool enabled
  ) internal pure {
    self.data =
      (self.data & STABLE_BORROWING_MASK) |
      (uint256(enabled ? 1 : 0) << STABLE_BORROWING_ENABLED_START_BIT_POSITION);
  }

  function getStableRateBorrowingEnabled(
    DataTypesV2.ReserveConfigurationMap memory self
  ) internal pure returns (bool) {
    return (self.data & ~STABLE_BORROWING_MASK) != 0;
  }

  function setBorrowingEnabled(
    DataTypesV2.ReserveConfigurationMap memory self,
    bool enabled
  ) internal pure {
    self.data =
      (self.data & BORROWING_MASK) |
      (uint256(enabled ? 1 : 0) << BORROWING_ENABLED_START_BIT_POSITION);
  }

  function getBorrowingEnabled(
    DataTypesV2.ReserveConfigurationMap memory self
  ) internal pure returns (bool) {
    return (self.data & ~BORROWING_MASK) != 0;
  }
}
