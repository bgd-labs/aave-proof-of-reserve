// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';
import {IERC20Metadata} from '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import {AvaxBridgeWrapper} from '../src/contracts/AvaxBridgeWrapper.sol';

contract AvaxBridgeWrapperTest is Test {
  address private constant AAVEE =
    address(0x63a72806098Bd3D9520cC43356dD78afe5D386D9);
  address private constant AAVEE_DEPRECATED =
    address(0x8cE2Dee54bB9921a2AE0A63dBb2DF8eD88B91dD9);
  address private constant DAIE =
    address(0xd586E7F844cEa2F87f50152665BCbc2C279D8d70);
  address private constant DAIE_DEPRECATED =
    address(0xbA7dEebBFC5fA1100Fb055a87773e1E99Cd3507a);

  function setUp() public {
    vm.createSelectFork('avalanche', 62513100);
  }

  function testTotalSupplyAAVEe() public {
    checkTotalSupplyAndMetadata(AAVEE, AAVEE_DEPRECATED);
  }

  function testTotalSupplyDAIe() public {
    checkTotalSupplyAndMetadata(DAIE, DAIE_DEPRECATED);
  }

  function checkTotalSupplyAndMetadata(
    address token,
    address deprecatedToken
  ) private {
    // Arrange
    IERC20Metadata bridge = IERC20Metadata(token);
    IERC20Metadata deprecatedBridge = IERC20Metadata(deprecatedToken);
    AvaxBridgeWrapper bridgeWrapper = new AvaxBridgeWrapper(
      token,
      deprecatedToken
    );

    // Act + Assert
    assertEq(
      bridgeWrapper.totalSupply(),
      bridge.totalSupply() + deprecatedBridge.totalSupply()
    );
    assertEq(bridgeWrapper.name(), bridge.name());
    assertEq(bridgeWrapper.symbol(), bridge.symbol());
    assertEq(bridgeWrapper.decimals(), bridge.decimals());
  }
}
