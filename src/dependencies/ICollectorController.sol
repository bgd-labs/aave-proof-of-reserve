// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface ICollectorController {
  function transfer(
    IERC20 token,
    address recipient,
    uint256 amount
  ) external;
}
