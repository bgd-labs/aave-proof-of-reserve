certoraRun certora/harness/ProofOfReserveExecutorV3Harness.sol certora/harness/PORaggregatorDummy.sol certora/harness/configuratorDummy.sol \
    --verify ProofOfReserveExecutorV3Harness:certora/specs/executorV3.spec \
    --link ProofOfReserveExecutorV3Harness:_proofOfReserveAggregator=PORaggregatorDummy \
    --link ProofOfReserveExecutorV3Harness:_configurator=configuratorDummy \
    --optimistic_loop \
    --loop_iter 3 \
    --solc solc8.27 \
    --cloud \
    --packages solidity-utils/=lib/aave-helpers/lib/aave-address-book/lib/aave-v3-origin/lib/solidity-utils/src/ aave-address-book/=lib/aave-helpers/lib/aave-address-book/src/ forge-std=lib/forge-std/src/ \
    --msg "ProofOfReserveExecutorV3"
    