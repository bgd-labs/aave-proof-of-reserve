// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MockPoRFeed {
  int256 internal _answer;

  function setAnswer(int256 answer) external {
    _answer = answer;
  }

  function latestAnswer() public view returns (int256) {
    return _answer;
  }

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return (0, _answer, 0, 0, 0);
  }
}
