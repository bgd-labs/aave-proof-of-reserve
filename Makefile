# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

# deps
update:; forge update

# Build & test
build  :; forge build --sizes --via-ir
test   :; forge test -vvv

# Deploy
deploy-proof-of-reserve-avalanche :;  forge script scripts/DeployProofOfReserveAvax.s.sol:Deploy --rpc-url avalanche --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify --etherscan-api-key ${ETHERSCAN_API_KEY} -vvvv
deploy-proof-of-reserve-ledger :; forge script scripts/DeployProofOfReserveAvax.s.sol:Deploy --rpc-url ${RPC_URL} --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify --etherscan-api-key ${ETHERSCAN_API_KEY} -vvvv
deploy-proof-of-reserve-pk :; forge script scripts/DeployProofOfReserveAvax.s.sol:Deploy --rpc-url ${RPC_URL} --broadcast --legacy --private-key ${PRIVATE_KEY} --verify --etherscan-api-key ${ETHERSCAN_API_KEY} -vvvv

# verify
verify-proof-of-reserve-avalanche :;  forge script scripts/Deploy.s.sol:DeployProofOfReserveAvax --rpc-url avalanche --legacy --verify --etherscan-api-key ${ETHERSCAN_API_KEY} -vvvv
verify-proof-of-reserve :;  forge script scripts/Deploy.s.sol:DeployProofOfReserveAvax --rpc-url ${RPC_URL} --legacy --verify --etherscan-api-key ${ETHERSCAN_API_KEY} -vvvv