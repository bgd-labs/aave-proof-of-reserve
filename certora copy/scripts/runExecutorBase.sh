certoraRun certora/harness/ProofOfReserveExecutorBaseHarness.sol certora/harness/PORaggregatorDummy.sol \
    --verify ProofOfReserveExecutorBaseHarness:certora/specs/executorBase.spec \
    --link ProofOfReserveExecutorBaseHarness:_proofOfReserveAggregator=PORaggregatorDummy \
    --solc solc8.16 \
    --optimistic_loop \
    --loop_iter 3 \
    --msg "ProofOfReserveExecutorBase" \
    --staging abakst/static-array-memcopy-loops \
    --packages solidity-utils=lib/solidity-utils/src chainlink-brownie-contracts=lib/chainlink-brownie-contracts/contracts/src/v0.8/ 