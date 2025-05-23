certoraRun certora/harness/ProofOfReserveAggregatorHarness.sol \
    --verify ProofOfReserveAggregatorHarness:certora/specs/aggregator.spec \
    --optimistic_loop \
    --loop_iter 3 \
    --solc solc8.27 \
    --cloud \
    --packages solidity-utils/=lib/aave-helpers/lib/aave-address-book/lib/aave-v3-origin/lib/solidity-utils/src/  \
    --msg "ProofOfReserveAggregator"