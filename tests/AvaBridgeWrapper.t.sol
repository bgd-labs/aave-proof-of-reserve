// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';
import {IERC20Metadata} from 'solidity-utils/contracts/oz-common/interfaces/IERC20Metadata.sol';
import {AvaBridgeWrapper} from '../src/contracts/AvaBridgeWrapper.sol';

contract AvaBridgeWrapperTest is Test {
  uint256 private avalancheFork;

  address private constant AAVEE =
    address(0x63a72806098Bd3D9520cC43356dD78afe5D386D9);
  address private constant AAVEE_DEPRECATED =
    address(0x8cE2Dee54bB9921a2AE0A63dBb2DF8eD88B91dD9);
  address private constant DAIE =
    address(0xd586E7F844cEa2F87f50152665BCbc2C279D8d70);
  address private constant DAIE_DEPRECATED =
    address(0xbA7dEebBFC5fA1100Fb055a87773e1E99Cd3507a);

  function setUp() public {
    avalancheFork = vm.createFork('https://api.avax.network/ext/bc/C/rpc');
    vm.selectFork(avalancheFork);
  }

  function testTotalSupplyAAVEe() public {
    // Arrange
    IERC20Metadata aavee = IERC20Metadata(AAVEE);
    IERC20Metadata aaveeDeprecated = IERC20Metadata(AAVEE_DEPRECATED);
    AvaBridgeWrapper bridgeWrapper = new AvaBridgeWrapper(
      AAVEE,
      AAVEE_DEPRECATED
    );

    // Act + Assert
    assertEq(
      bridgeWrapper.totalSupply(),
      aavee.totalSupply() + aaveeDeprecated.totalSupply()
    );
    assertEq(bridgeWrapper.name(), aavee.name());
    assertEq(bridgeWrapper.symbol(), aavee.symbol());
    assertEq(bridgeWrapper.decimals(), aavee.decimals());
  }

  function testTotalSupplyDAIe() public {
    // Arrange
    IERC20Metadata daie = IERC20Metadata(DAIE);
    IERC20Metadata daieDeprecated = IERC20Metadata(DAIE_DEPRECATED);
    AvaBridgeWrapper bridgeWrapper = new AvaBridgeWrapper(
      DAIE,
      DAIE_DEPRECATED
    );

    // Act + Assert
    assertEq(
      bridgeWrapper.totalSupply(),
      daie.totalSupply() + daieDeprecated.totalSupply()
    );
    assertEq(bridgeWrapper.name(), daie.name());
    assertEq(bridgeWrapper.symbol(), daie.symbol());
    assertEq(bridgeWrapper.decimals(), daie.decimals());
  }
}
