certoraRun certora/harness/ProofOfReserveExecutorV2Harness.sol certora/harness/PORaggregatorDummy.sol \
    --verify ProofOfReserveExecutorV2Harness:certora/specs/executorV2.spec \
    --link ProofOfReserveExecutorV2Harness:_proofOfReserveAggregator=PORaggregatorDummy \
    --optimistic_loop \
    --loop_iter 3 \
    --solc solc8.27 \
    --cloud \
    --packages solidity-utils=lib/aave-helpers/lib/aave-address-book/lib/aave-v3-origin/lib/solidity-utils/src @openzeppelin/contracts=lib/aave-helpers/lib/aave-address-book/lib/aave-v3-origin/lib/solidity-utils/lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts aave-address-book=lib/aave-helpers/lib/aave-address-book/src forge-std=lib/aave-v3-origin=lib/aave-helpers/lib/aave-address-book/lib/aave-v3-origin/src forge-std/src/ \
    --msg "ProofOfReserveExecutorV2"
    