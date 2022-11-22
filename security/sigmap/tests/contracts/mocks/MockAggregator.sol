// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MockAggregator {
  int256 public s_answer;

  function setAnswer(int256 answer) public {
    s_answer = answer;
  }

  function decimals() external pure returns (uint8) {
    return 8;
  }

  function description() external pure returns (string memory) {
    return "mock";
  }

  function version() external pure returns (uint256) {
    return 3;
  }

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    ) {
      return (_roundId, s_answer, block.timestamp, block.timestamp, _roundId);
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
    ) {
      return (1, s_answer, block.timestamp, block.timestamp, 1);
    }
}
