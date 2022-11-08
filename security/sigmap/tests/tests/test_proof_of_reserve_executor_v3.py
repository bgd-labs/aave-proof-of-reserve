"""
Tests for `ProofOfReserveExecutorV3.sol` contract
These tests were duplicated from `test_proof_of_reserve_executor_v2.py` and updated to use V3 contracts.
"""

from brownie import reverts

# Tests `enableAssets()`
def test_enable_assets(owner, constants, usdc, usdt, pool_addresses_provider_v3, ProofOfReserveAggregator, ProofOfReserveExecutorV3):
    ## Setup
    proof_of_reserve_aggregator = owner.deploy(ProofOfReserveAggregator)

    proof_of_reserve_executor_v3 = owner.deploy(ProofOfReserveExecutorV3, pool_addresses_provider_v3, proof_of_reserve_aggregator)

    ## Action
    # Enable USDC
    tx = proof_of_reserve_executor_v3.enableAssets([usdc], {'from': owner})

    ## Validation
    assert tx.events['AssetStateChanged']['asset'] == usdc
    assert tx.events['AssetStateChanged']['enabled']
    assert proof_of_reserve_executor_v3.getAssets() == [usdc]

    ## Action
    # Enable [USDC, USDT] - USDC is already enabled
    tx = proof_of_reserve_executor_v3.enableAssets([usdc, usdt], {'from': owner})

    ## Validation
    assert len(tx.events['AssetStateChanged']) == 1
    assert tx.events['AssetStateChanged']['asset'] == usdt
    assert tx.events['AssetStateChanged']['enabled']
    assert proof_of_reserve_executor_v3.getAssets() == [usdc, usdt]


# Tests `disableAssets()`
def test_disable_assets(owner, constants, usdc, usdt, pool_addresses_provider_v3, ProofOfReserveAggregator, ProofOfReserveExecutorV3):
    ## Setup
    proof_of_reserve_aggregator = owner.deploy(ProofOfReserveAggregator)

    proof_of_reserve_executor_v3 = owner.deploy(ProofOfReserveExecutorV3, pool_addresses_provider_v3, proof_of_reserve_aggregator)

    # Enable USDC
    proof_of_reserve_executor_v3.enableAssets([usdc], {'from': owner})

    ## Action
    # Disable [USDT, USDC]
    tx = proof_of_reserve_executor_v3.disableAssets([usdt, usdc], {'from': owner})

    ## Validation
    assert tx.events['AssetStateChanged']['asset'] == usdc
    assert not tx.events['AssetStateChanged']['enabled']
    assert proof_of_reserve_executor_v3.getAssets() == []


# Tests `areAllReservesBacked()`
def test_are_all_reserves_backed(owner, usdc, usdt, pool_addresses_provider_v3, ProofOfReserveAggregator, MockAggregator, ProofOfReserveExecutorV3):
    ## Setup
    # Deployments
    proof_of_reserve_aggregator = owner.deploy(ProofOfReserveAggregator)
    proof_of_reserve_feed_usdc = owner.deploy(MockAggregator)
    proof_of_reserve_feed_usdt = owner.deploy(MockAggregator)
    proof_of_reserve_executor_v3 = owner.deploy(ProofOfReserveExecutorV3, pool_addresses_provider_v3, proof_of_reserve_aggregator)

    # Enable PoR feeds
    proof_of_reserve_aggregator.enableProofOfReserveFeed(usdc, proof_of_reserve_feed_usdc, {'from': owner})
    proof_of_reserve_aggregator.enableProofOfReserveFeed(usdt, proof_of_reserve_feed_usdt, {'from': owner})

    # Set feed answers
    feed_answer_usdc = usdc.totalSupply()
    proof_of_reserve_feed_usdc.setAnswer(feed_answer_usdc)

    feed_answer_usdt = usdt.totalSupply()
    proof_of_reserve_feed_usdt.setAnswer(feed_answer_usdt)

    # Enable [USDC, USDT] in Executor V3
    proof_of_reserve_executor_v3.enableAssets([usdc, usdt], {'from': owner})

    ## Action
    # Valid
    are_all_reserves_backed = proof_of_reserve_executor_v3.areAllReservesBacked()

    ## Validation
    assert are_all_reserves_backed

    ## Setup
    # Set feed answers
    feed_answer_usdc = usdc.totalSupply() - 1 # Reserve is not backed
    proof_of_reserve_feed_usdc.setAnswer(feed_answer_usdc)

    ## Action
    # Invalid
    are_all_reserves_backed = proof_of_reserve_executor_v3.areAllReservesBacked()

    ## Validation
    assert not are_all_reserves_backed


# Tests `areAllReservesBacked()` when asset list is empty
def test_are_all_reserves_backed_empty(owner, pool_addresses_provider_v3, ProofOfReserveAggregator, ProofOfReserveExecutorV3):
    proof_of_reserve_aggregator = owner.deploy(ProofOfReserveAggregator)
    proof_of_reserve_executor_v3 = owner.deploy(ProofOfReserveExecutorV3, pool_addresses_provider_v3, proof_of_reserve_aggregator)

    assert proof_of_reserve_executor_v3.areAllReservesBacked()


# Tests `executeEmergencyAction()` 
def test_execute_emergency_admin(owner, usdc, usdt, pool_addresses_provider_v3, acl_manager_v3, ProofOfReserveAggregator, MockAggregator, ProofOfReserveExecutorV3):
    ## Setup
    # Deployments
    proof_of_reserve_aggregator = owner.deploy(ProofOfReserveAggregator)
    proof_of_reserve_feed_usdc = owner.deploy(MockAggregator)
    proof_of_reserve_feed_usdt = owner.deploy(MockAggregator)
    proof_of_reserve_executor_v3 = owner.deploy(ProofOfReserveExecutorV3, pool_addresses_provider_v3, proof_of_reserve_aggregator)

    # Enable PoR feeds
    proof_of_reserve_aggregator.enableProofOfReserveFeed(usdc, proof_of_reserve_feed_usdc, {'from': owner})
    proof_of_reserve_aggregator.enableProofOfReserveFeed(usdt, proof_of_reserve_feed_usdt, {'from': owner})

    # Set feed answers
    feed_answer_usdc = usdc.totalSupply() - 1000 # Reserve not backed
    proof_of_reserve_feed_usdc.setAnswer(feed_answer_usdc)

    feed_answer_usdt = usdt.totalSupply()
    proof_of_reserve_feed_usdt.setAnswer(feed_answer_usdt)

    # Enable [USDC, USDT] in Executor V3
    proof_of_reserve_executor_v3.enableAssets([usdc, usdt], {'from': owner})

    # Grant `RISK_ADMIN_ROLE` to new executor V3
    acl_admin = '0xa35b76e4935449e33c56ab24b23fcd3246f13470'
    acl_manager_v3.addRiskAdmin(proof_of_reserve_executor_v3, {'from': acl_admin})

    ## Action
    # Execute emergency action
    tx = proof_of_reserve_executor_v3.executeEmergencyAction()

    ## Validation
    assert 'EmergencyActionExecuted' in tx.events
    assert tx.events['AssetIsNotBacked']['asset'] == usdc

    reserves = [
        '0xd586e7f844cea2f87f50152665bcbc2c279d8d70',
        '0x5947bb275c521040051d82396192181b413227a3',
        '0xb97ef9ef8734c71904d8002f8b6bc66dd9c48a6e',
        '0x50b7545627a5162f82a992c33b87adc75187b218',
        '0x49d5c2bdffac6ce2bfdb6640f4f80f226bc10bab',
        '0x9702230a8ea53601f5cd2dc00fdbc13d4df4a8c7',
        '0x63a72806098bd3d9520cc43356dd78afe5d386d9',
        '0xb31f66aa3c1e785363f0875a1b74e27b85fd66c7',
        '0x2b2c81e08f1af8835a78bb2a90ae924ace0ea4be',
        '0xd24c2ad096400b6fbcd2ad8b24e7acbc21a1da64',
        '0x5c49b268c9841aff1cc3b0a418ff5c3442ee3f3b',
        '0x152b9d0fdc40c096757f570a51e494bd4b943e50',
    ]

    for (i, reserve) in enumerate(reserves):
        assert tx.events['ReserveStableRateBorrowing'][i]['asset'] == reserves[i]
        assert tx.events['ReserveStableRateBorrowing'][i]['enabled'] == False
        assert tx.events['ReserveBorrowing'][i]['asset'] == reserves[i]
        assert tx.events['ReserveBorrowing'][i]['enabled'] == False

    assert tx.gas_used < 5_000_000


# Tests `executeEmergencyAction()` when all reserves as backed
def test_execute_emergency_admin_backed(owner, usdc, usdt, pool_addresses_provider_v3, acl_manager_v3, ProofOfReserveAggregator, MockAggregator, ProofOfReserveExecutorV3):
    ## Setup
    # Deployments
    proof_of_reserve_aggregator = owner.deploy(ProofOfReserveAggregator)
    proof_of_reserve_feed_usdc = owner.deploy(MockAggregator)
    proof_of_reserve_feed_usdt = owner.deploy(MockAggregator)
    proof_of_reserve_executor_v3 = owner.deploy(ProofOfReserveExecutorV3, pool_addresses_provider_v3, proof_of_reserve_aggregator)

    # Enable PoR feeds
    proof_of_reserve_aggregator.enableProofOfReserveFeed(usdc, proof_of_reserve_feed_usdc, {'from': owner})
    proof_of_reserve_aggregator.enableProofOfReserveFeed(usdt, proof_of_reserve_feed_usdt, {'from': owner})

    # Set feed answers
    feed_answer_usdc = usdc.totalSupply()
    proof_of_reserve_feed_usdc.setAnswer(feed_answer_usdc)

    feed_answer_usdt = usdt.totalSupply()
    proof_of_reserve_feed_usdt.setAnswer(feed_answer_usdt)

    # Enable [USDC, USDT] in Executor V3
    proof_of_reserve_executor_v3.enableAssets([usdc, usdt], {'from': owner})

    # Grant `RISK_ADMIN_ROLE` to new executor V3
    acl_admin = '0xa35b76e4935449e33c56ab24b23fcd3246f13470'
    acl_manager_v3.addRiskAdmin(proof_of_reserve_executor_v3, {'from': acl_admin})

    ## Action
    # Execute emergency action
    tx = proof_of_reserve_executor_v3.executeEmergencyAction()

    ## Validation
    assert not 'EmergencyActionExecuted' in tx.events
    assert not 'AssetIsNotBacked' in tx.events
    assert not 'StableRateDisabledOnReserve' in tx.events
    assert not 'BorrowingDisabledOnReserve' in tx.events

    assert tx.gas_used < 5_000_000

