certoraRun certora/harness/ProofOfReserveExecutorV3Harness.sol certora/harness/PORaggregatorDummy.sol certora/harness/configuratorDummy.sol \
    --verify ProofOfReserveExecutorV3Harness:certora/specs/executorV3.spec \
    --link ProofOfReserveExecutorV3Harness:_proofOfReserveAggregator=PORaggregatorDummy \
    --link ProofOfReserveExecutorV3Harness:_configurator=configuratorDummy \
    --solc solc8.16 \
    --optimistic_loop \
    --loop_iter 3 \
    --msg "ProofOfReserveExecutorV3" \
    --staging abakst/static-array-memcopy-loops \
    --rule integrityOfExecuteEmergencyAction \
    --packages solidity-utils=lib/solidity-utils/src chainlink-brownie-contracts=lib/chainlink-brownie-contracts/contracts/src/v0.8/ aave-address-book=lib/aave-address-book/src/ forge-std=lib/forge-std/src/ 
    