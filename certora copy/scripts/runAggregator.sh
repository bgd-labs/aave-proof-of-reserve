certoraRun certora/harness/ProofOfReserveAggregatorHarness.sol \
    --verify ProofOfReserveAggregatorHarness:certora/specs/aggregator.spec \
    --solc solc8.16 \
    --optimistic_loop \
    --loop_iter 3 \
    --msg "ProofOfReserveAggregator" \
    --packages solidity-utils=lib/solidity-utils/src chainlink-brownie-contracts=lib/chainlink-brownie-contracts/contracts/src/v0.8/ 