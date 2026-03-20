# Aave Proof of Reserve

![proof-of-reserve1](https://github.com/user-attachments/assets/0c1f80d3-6a0a-41d5-8e03-859d17f23345)

<br>

## Proof of Reserve overview

Proof of Reserve introduces a reliable way of verifying asset collateralization on-chain.

The Aave Proof of Reserve system is an extra safeguard for Pool reserves, monitoring the collateralization data published by the [Chainlink Proof of Reserve feeds](https://chain.link/proof-of-reserve). The system can quickly isolate an undercollateralized reserve, thereby protecting the remaining reserves in the pool.

A Proof of Reserve feed can report two types of reserves based on where assets are held:

- **Off-chain** reserves can be characterized as reserves stored in the real world, for example, US dollars in a bank backing issued stablecoins.
- **Cross-chain** reserves refer to assets in blockchain "A" that serve as backing for assets in another blockchain, "B". For example, Bitcoin is stored in a BTC wallet, which issues BTC on Ethereum, or Aave tokens locked in a bridge, backing Aave on an L2 chain.

<br>

## Proof of Reserve key components

The Aave Proof of Reserve comprises two main components:

- `ProofOfReserveAggregator`: This contract keeps a registry of assets and their related Chainlink Proof of Reserve data feeds. It verifies whether each asset is fully backed by comparing its total supply to the reserves reported by the respective Chainlink feed, and flags any assets that are not.
- `ProofOfReserveExecutor`: This contract executes emergency actions for reserves flagged as unbacked by the ProofOfReserveAggregator, freezing those reserves and, in the V2 version, also disabling borrowing for all pool assets.

<br>

Other components of the Proof of Reserve system:

- `AvaxBridgeWrapper`: An Avalanche-specific contract that aggregates the total supply of a bridged asset across its current and deprecated bridge contracts, providing a unified totalSupply for use by the ProofOfReserveAggregator.
- `ProofOfReserveKeeper`: Chainlink automation that monitors the reserves and can perform emergency actions through the ProofOfReserveExecutor.

<br>

## Technical overview of the smart contracts

![proof-of-reserve contracts overview](./aave-proof-of-reserve-contracts-high-level.png)

### `ProofOfReserveAggregator`

The ProofOfReserveAggregator is the contract responsible for keeping the list of assets, their Proof of Reserve Chainlink feed, and their bridge wrapper in the case of assets with deprecated bridges. It is mainly used by each ProofOfReserveExecutor to validate whether any of the reserves set in this contract are undercollateralized by checking against its Proof of Reserve feed.

#### Access Control

The contract uses OZ ownable for access control, which will be assigned to the Aave governance. The owner's role is to configure new assets, their Chainlink Proof of Reserve feeds, and if necessary, their bridge wrapper. It's also possible to remove assets.

#### Key Functions

- **`areAllReservesBacked`**

  - **purpose**: It flags whether all provided assets with Proof of Reserve enabled are still backed or not.
  - **functionality**:
    - Permissionless view function that iterates through a list of assets and checks the backing status of each.
    - It verifies whether the PoR feed’s latest answer is non-negative and whether the asset’s total supply does not exceed the feed’s reported supply. If either condition fails, the asset is flagged as unbacked.
    - Returns a boolean indicating if all reserves are backed, and a list flagging each asset's backing status.

- **`enableProofOfReserveFeed`**

  - **purpose**: Adds a new reserve and its Proof of Reserve configuration with Chainlink PoR feed
  - **functionality**:
    - Only the owner can call this function.
    - It validates that this asset PoR was not previously configured, the addresses of the asset and feed are not the zero address.
    - Stores in the assetsData mapping the feed address.

- **`enableProofOfReserveFeedWithBridgeWrapper`**

  - **purpose**: Adds a new reserve with a bridge wrapper and its Proof of Reserve configuration with Chainlink PoR feed.
  - **functionality**:
    - Only the owner can call this function.
    - It validates that this asset PoR was not previously configured, the addresses of the asset, and feed and bridge wrapper are not the zero address.
    - Stores in the assetsData mapping the bridge wrapper address and feed address.

- **`disableProofOfReserveFeed`**

  - **purpose**: Removes a reserve with PoR enabled.
  - **functionality**:
    - Only the owner can call this function.
    - Deletes the asset’s PoR feed and bridge wrapper from storage.

<br>

### `ProofOfReserveExecutor`

#### Access Control

- The contract uses OZ ownable for access control, which will be assigned to the Aave governance. The owner's role is to enable or disable assets that will be monitored by the Executor.

#### Key Functions

- **`isEmergencyActionPossible`**

  - **purpose**: Determines whether the emergency action can be performed, with logic specific to each pool.
  - **functionality**:
    - Permissionless view function that uses the configured ProofOfReserveAggregator to check the collateralization status of the enabled assets in this contract.
    - For unbacked reserves, it checks whether the reserve is already frozen, and if it is not, the emergency action can be triggered.
    - The Executor V2 includes an additional step that verifies whether any pool V2 reserves are borrowable. If so, the emergency action can also be triggered.

- **`executeEmergencyAction`**

  - **purpose**: Performs the emergency action, with logic specific to each pool.
  - **functionality**:
    - Permissionless function that uses the configured ProofOfReserveAggregator to get the collateralization status of the enabled assets in this contract and freeze undercollateralized reserves.
    - The Executor V2 includes an additional action that turns off borrowing of all pool V2 reserves.
    - For Executors to be able to perform the emergency action they must be granted pool specific roles:
      - On V2: a `PROOF_OF_RESERVE_ADMIN` role must be granted to the Executor V2 via the Addresses Provider V2. Additionally, the Lending Pool Configurator must be upgraded to support the `PROOF_OF_RESERVE_ADMIN` role, enabling it to freeze reserves and disable borrowing.
      - On V3: The `EMERGENCY_ADMIN_ROLE` must be granted to the Executor via the ACL Manager, allowing the Executor V3 to perform the freeze action.

- **`enableAssets`**

  - **purpose**: Adds a list of reserves to be included in the monitoring and will be eligible for the emergency action.
  - **functionality**:
    - Only the owner can call this function.
    - It verifies that the reserve was not enabled before being stored in the assets array.

- **`disableAssets`**

  - **purpose**: Removes a reserve from the assets list that are monitored by this contract.
  - **functionality**:
    - Only the owner can call this function.
    - It verifies if the reserve is enabled and deletes it from the assets array.

  <br>

### `AvaxBridgeWrapper`

This contract is specific for the Avalanche network, as several reserves have a deprecated bridge coexisting with the actual one. This bridge wrapper contract is used to return to the ProofOfReserveAggregator the correct total supply of a reserve with deprecated bridges by summing the total supply of the actual and deprecated bridges.

#### Access Control

- The bridge addresses are set in the constructor during the deployment, meaning that this contract does not provide any setters that could change bridge addresses.

#### Key Functions

- **`totalSupply`**

  - **purpose**: Returns the real total supply of a cross-chain reserve.
  - **functionality**:
    - Permissionless view function that sums the total supply of the actual and deprecated bridge for the reserve to which this contract was deployed.

  <br>

### `ProofOfReserveKeeper`

This contract is Chainlink Automation compatible, which will execute the emergency action by constantly monitoring the Aave Proof of Reserve system through the Executors.

#### Key Functions

- **`checkUpkeep`**
  - **purpose**: Getter checked by Chainlink Automation to determine whether an emergency action should be performed by a specific ProofOfReserveExecutor.
  - **functionality**:
    - Accepts as input the encoded address of a ProofOfReserveExecutor contract and calls `areAllReservesBacked()` and `isEmergencyActionPossible()` to confirm that if a reserve is undercollateralized the emergency action can be triggered.
    - Returns true if both conditions are met. False otherwise.
- **`performUpkeep`**

  - **purpose**: Called by Chainlink Automation after the `checkUpkeep` indicates that the emergency action can be executed.
  - **functionality**:
    - Accepts as input the encoded address of a ProofOfReserveExecutor contract in which the emergency action will be performed and calls the `executeEmergencyAction()` function in the specific Executor.

  <br>

# Misc system's properties

- A reserve is considered unbacked if the data provided by the feed is less than the reserve's total supply.
- A reserve must be enabled in the Proof of Reserve Aggregator and Executor for the Emergency action to be possible.
- Reserves cannot be duplicated in the system.
- A reserve can only be enabled or disabled by the owner of the contracts.
- The Emergency action is permissionless and can be performed by anyone if the Aggregator flags at least one reserve as unbacked and unfrozen.

<br>

# Security

## Audits

- [SigmaPrime](./security/sigmap/audit-report-round-2.md)
- [Certora](./security/Certora)

## Assets covered

Currently, the Proof of Reserves is active on the Avalanche Network, covering the following assets:

| Asset Symbol                                                                      | PoR Feed                                                                              | Bridge Wrapper                                                                            |
| --------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| [AAVE.e](https://snowscan.xyz/address/0x63a72806098Bd3D9520cC43356dD78afe5D386D9) | [AAVE.e PoR](https://snowscan.xyz/address/0x14C4c668E34c09E1FBA823aD5DB47F60aeBDD4F7) | [AAVE.e Wrapper](https://snowscan.xyz/address/0xADE6CBA6c45aa8E9d0337cAc3D2619eabc39D901) |
| [WETH.e](https://snowscan.xyz/address/0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB) | [WETH.e PoR](https://snowscan.xyz/address/0xDDaf9290D057BfA12d7576e6dADC109421F31948) | [WETH.e Wrapper](https://snowscan.xyz/address/0x8B6851156023f4f5A66F68BEA80851c3D905Ac93) |
| [DAI.e](https://snowscan.xyz/address/0xd586E7F844cEa2F87f50152665BCbc2C279D8d70)  | [DAI.e PoR](https://snowscan.xyz/address/0x976D7fAc81A49FA71EF20694a3C56B9eFB93c30B)  | [DAI.e Wrapper](https://snowscan.xyz/address/0x004F81e8880A40cf605C72e785a3F98eF16EcbF3)  |
| [LINK.e](https://snowscan.xyz/address/0x5947BB275c521040051D82396192181b413227A3) | [LINK.e PoR](https://snowscan.xyz/address/0x943cEF1B112Ca9FD7EDaDC9A46477d3812a382b6) | [LINK.e Wrapper](https://snowscan.xyz/address/0x42c5A9CCd4626251f3E64a08a9968023A34e84dE) |
| [WBTC.e](https://snowscan.xyz/address/0x50b7545627a5162F82A992c33b87aDc75187B218) | [WBTC.e PoR](https://snowscan.xyz/address/0xebEfEAA58636DF9B20a4fAd78Fad8759e6A20e87) | [WBTC.e Wrapper](https://snowscan.xyz/address/0xac3AF0f4A52C577Cc2C241dF51a01FDe3D06D93B) |

# Development

```bash
# Install foundry dependencies
forge install

# Install node dependencies
npm i

# Run tests
forge test
```

## License

Copyright © 2026, Aave DAO, represented by its governance smart contracts.

Created by [BGD Labs](https://bgdlabs.com/).

The [BUSL1.1](./LICENSE) license of this repository allows for any usage of the software, if respecting the Additional Use Grant limitations, forbidding any use case damaging anyhow the Aave DAO's interests.
Interfaces and other components required for integrations are explicitly MIT licensed.
