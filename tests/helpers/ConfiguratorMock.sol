// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {VersionedInitializable} from './VersionedInitializable.sol';

contract ConfiguratorMock is VersionedInitializable {
  address internal addressesProvider;

  uint256 internal constant CONFIGURATOR_REVISION = 0x2;

  function getRevision() internal pure override returns (uint256) {
    return CONFIGURATOR_REVISION;
  }

  function initialize(address provider) public initializer {
    addressesProvider = provider;
  }
}
