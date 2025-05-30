// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';

contract MockERC20 is ERC20 {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

  function mint(address to, uint value) external {
    _mint(to, value);
  }

  function burn(address from, uint value) external {
    _burn(from, value);
  }
}