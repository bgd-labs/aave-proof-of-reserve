# Aave Proof of Reserve overview

Repository containing the necessary smart contracts to propose Proof of Reserve for AAVE v2/v3 pools.

Proof-of-Reserve is a system by Chainlink that allows for reliable monitoring of reserve assets, and usage of that data feed directly on-chain. If anomaly will be detected for a single asset, the system will try to apply the highest possible protections on the pool.

![proof-of-reserve overview](./proof-of-reserve.png)

Below is the general flow of the proof of reserve check:

1. Anyone can call publicly opened method executeEmergencyAction() of the Executor for the desired pool.
2. The Executor asks the Aggregator if any of the reserves is unhealthy at the moment.
3. Aggregator compares total supply against Chainlink's Proof of Reserve feed for every token enabled in prior.
4. If at least one reserve is compromised, then
   - for Aave V2 Executor disables borrowing for every asset on the pool and freezes only the exploited assets.
   - for V3 the broken asset is freezed.

## Aggregator

A common [ProofOfReserveAggregator](./src/contracts/ProofOfReserveAggregator.sol) smart contract, acting as a registry of pairs (asset address, proof of reserve feed address) and also implementing and exposing a areAllReservesBacked() function, which, for a list of asset addresses does the validation of **proof of reserve feed value ≥ total supply of the asset**. If any asset passed on the list of inputs will not fulfill that requirement, the result of areAllReservesBacked() will be false. It is also possible to use the bridge wrapper to get the total supply, if the asset has two bridges on the network.

This contract is common, to be used by both Aave v2 and v3 systems, each one with different pool logic.

## Executors

- Each Aave v2 and Aave v3 pools will have their own associated smart contract implementing [ProofOfReserveExecutorBase](./src/contracts/ProofOfReserveExecutorBase.sol), exposing mainly 2 functions:
  1. areAllReservesBacked(). Returning at any time if all the assets with a proof of reserve feed associated are properly backed.
  2. executeEmergencyAction(). Callable by anybody and allowing to execute the appropriate protective actions on the Aave pool if areAllReservesBacked() would be returning a false value.
- The action to be executed on v2 is stopping borrowing of all the assets and freezing only the assets which did not pass proof of reserve validation.
- on v3 the assets which did not pass proof of reserve validations will be freezed and their LTV will be set to 0.
- The [ProofOfReserveExecutorV3](./src/contracts/ProofOfReserveExecutorV3.sol) of Aave v3 will have riskAdmin permissions from the Aave v3 protocol, allowing this way to adjust LTV when the defined conditions are met.
- To allow the [ProofOfReserveExecutorV2](./src/contracts/ProofOfReserveExecutorV2.sol) of Aave v2 to halt borrowing and freeze exploited reserves, as the permissions system on Aave v2 is less granular than in v3, we have added a new role PROOF_OF_RESERVE_ADMIN on the v2 addresses provider smart contract, and updated the pool configurator contract to allow both the pool admin (previously) and the new proof of reserve admin (the ProofOfReserveExecutor of v2) to disable borrowing and freeze reserve.
- The addition/removal of assets with a proof of reserve will be controlled via the standard Aave governance procedures. Everything else (monitoring if all reserves are backed, execute the emergency action if not) is completely permissionless, algorithmically defined.

## Keeper

[ProofOfReserveKeeper](./src/contracts/ProofOfReserveKeeper.sol) contract which is compatible with [Chainlink ~~Keeper~~ Automation](https://docs.chain.link/docs/chainlink-automation/introduction/) to add more assurances on the execution timing.

> `performUpkeep()` won't be executed if it will consume more than 5m gas. Currently gas consumption is about 500k for six assets; eye should be kept on this metric upon adding of every new asset.

## AvaxBridgeWrapper

As for several assets on the Avalanche network deprecated bridge co-exist with the actual one, [AvaxBridgeWrapper](./src/contracts/AvaxBridgeWrapper.sol) was implemented to return the sum of supplies.

# Assets to be protected by PoR

| Asset                                                                           |                                                          PoR feed                                                          | Bridge Wrapper |
| ------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------: | -------------: |
| [AAVE.e](https://snowtrace.io/token/0x63a72806098bd3d9520cc43356dd78afe5d386d9) |   [0x14C4c668E34c09E1FBA823aD5DB47F60aeBDD4F7](https://snowtrace.io/address/0x14c4c668e34c09e1fba823ad5db47f60aebdd4f7)    | To be deployed |
| [WETH.e](https://snowtrace.io/token/0x49d5c2bdffac6ce2bfdb6640f4f80f226bc10bab) | [0xDDaf9290D057BfA12d7576e6dADC109421F31948](https://snowtrace.io/address/0xddaf9290d057bfa12d7576e6dadc109421f31948#code) | To be deployed |
| [DAI.e](https://snowtrace.io/token/0xd586e7f844cea2f87f50152665bcbc2c279d8d70)  |   [0x976D7fAc81A49FA71EF20694a3C56B9eFB93c30B](https://snowtrace.io/address/0x976d7fac81a49fa71ef20694a3c56b9efb93c30b)    | To be deployed |
| [LINK.e](https://snowtrace.io/token/0x5947bb275c521040051d82396192181b413227a3) |   [0x943cEF1B112Ca9FD7EDaDC9A46477d3812a382b6](https://snowtrace.io/address/0x943cef1b112ca9fd7edadc9a46477d3812a382b6)    | To be deployed |
| [WBTC.e](https://snowtrace.io/token/0x50b7545627a5162f82a992c33b87adc75187b218) |   [0xebEfEAA58636DF9B20a4fAd78Fad8759e6A20e87](https://snowtrace.io/address/0xebefeaa58636df9b20a4fad78fad8759e6a20e87)    | To be deployed |
| [BTC.b](https://snowtrace.io/token/0x152b9d0FdC40C096757F570A51E494bd4b943E50)  |   [0x99311B4bf6D8E3D3B4b9fbdD09a1B0F4Ad8e06E9](https://snowtrace.io/address/0x99311b4bf6d8e3d3b4b9fbdd09a1b0f4ad8e06e9)    |              - |

# Deployment

1. [DeployProofOfReserveAvax.s.sol](./scripts/DeployProofOfReserveAvax.s.sol): This script will deploy Aggregator, Executors, Keeper, all Bridge Wrappers and two proposal contracts.
2. [ProposalPayloadProofOfReserve](./src/proposal/ProposalPayloadProofOfReserve.sol) will

- enable proof of reserve feeds and assets in Aggregator, ExecutorV2 and ExecutorV3 contracts
- set ExecutorV3 as the Risk Admin
- register Chainlink Automation for v2 and v3

3. [UpgradeAaveV2ConfiguratorPayload](./src/proposal/UpgradeAaveV2ConfiguratorPayload.sol) will

- deploy new implementation of the V2 Pool Configurator contract
- set ExecutorV2 as PROOF_OF_RESERVE_ADMIN

# Security

Audit reports:

[SigmaPrime](./security/sigmap/audit-report-round-2.md)

[Certora](./security/Certora)

To add a new `PROOF_OF_RESERVE_ADMIN` role to the V2 pool new implementation of the LendingPoolConfigurator contract is deployed. Difference between current implementation and the new one is [here](./diffs/avalanche_configurator_%200xc7938af7EC68C3d5aC3a396E28661B3E366b8fcf.md).

# SetUp

This repo has forge and npm dependencies, so you will need to install foundry then run:

```
forge install
```

and also run:

```
npm i
```

# Tests

To run the tests just run:

```
forge test
```
