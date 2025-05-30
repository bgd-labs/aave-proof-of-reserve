// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IReservesProvider {
  /**
   * @dev Returns the total reserve of the asset.
   * Can be used to track: 
   *   - tokens with multiple bridges.
   *   - underlying assets of LSTs and LRTs
   *   - any custom method that returns the asset reserves.
   */
  function getTotalReserves() external view returns (uint256);

  /**
   * @dev Returns the name of the token.
   */
  function name() external view returns (string memory);

  /**
   * @dev Returns the symbol of the token.
   */
  function symbol() external view returns (string memory);

  /**
   * @dev Returns the decimals places of the token.
   */
  function decimals() external view returns (uint8);
}
