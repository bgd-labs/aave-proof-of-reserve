certoraRun certora/harness/ProofOfReserveAggregatorHarness.sol \
    --verify ProofOfReserveAggregatorHarness:certora/specs/aggregator.spec \
    --optimistic_loop \
    --loop_iter 3 \
    --solc solc8.16 \
    --cloud \
    --packages solidity-utils=lib/solidity-utils/src chainlink-brownie-contracts=lib/chainlink-brownie-contracts/contracts/src/v0.8/ \
    --msg "ProofOfReserveAggregator"