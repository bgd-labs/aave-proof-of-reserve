"""
Tests for `ProofOfReserveExecutorV3.sol` contract
These tests were duplicated from `test_proof_of_reserve_executor_v2.py` and updated to use V3 contracts.
"""

from brownie import reverts

# Tests `enableAssets()`
def test_enable_assets(owner, constants, aave_token, dai, pool_addresses_provider_v3, ProofOfReserveAggregator, ProofOfReserveExecutorV3):
    ## Setup
    proof_of_reserve_aggregator = owner.deploy(ProofOfReserveAggregator)

    proof_of_reserve_executor_v3 = owner.deploy(ProofOfReserveExecutorV3, pool_addresses_provider_v3, proof_of_reserve_aggregator)

    ## Action
    # Enable aave
    tx = proof_of_reserve_executor_v3.enableAssets([aave_token], {'from': owner})

    ## Validation
    assert tx.events['AssetStateChanged']['asset'] == aave_token
    assert tx.events['AssetStateChanged']['enabled']
    assert proof_of_reserve_executor_v3.getAssets() == [aave_token]

    ## Action
    # Enable [aave, dai] - aave is already enabled
    tx = proof_of_reserve_executor_v3.enableAssets([aave_token, dai], {'from': owner})

    ## Validation
    assert len(tx.events['AssetStateChanged']) == 1
    assert tx.events['AssetStateChanged']['asset'] == dai
    assert tx.events['AssetStateChanged']['enabled']
    assert proof_of_reserve_executor_v3.getAssets() == [aave_token, dai]


# Tests `disableAssets()`
def test_disable_assets(owner, constants, aave_token, dai, pool_addresses_provider_v3, ProofOfReserveAggregator, ProofOfReserveExecutorV3):
    ## Setup
    proof_of_reserve_aggregator = owner.deploy(ProofOfReserveAggregator)

    proof_of_reserve_executor_v3 = owner.deploy(ProofOfReserveExecutorV3, pool_addresses_provider_v3, proof_of_reserve_aggregator)

    # Enable aave
    proof_of_reserve_executor_v3.enableAssets([aave_token], {'from': owner})

    ## Action
    # Disable [dai, aave]
    tx = proof_of_reserve_executor_v3.disableAssets([dai, aave_token], {'from': owner})

    ## Validation
    assert tx.events['AssetStateChanged']['asset'] == aave_token
    assert not tx.events['AssetStateChanged']['enabled']
    assert proof_of_reserve_executor_v3.getAssets() == []


# Tests `areAllReservesBacked()`
def test_are_all_reserves_backed(owner, aave_token, dai, pool_addresses_provider_v3, ProofOfReserveAggregator, MockAggregator, ProofOfReserveExecutorV3):
    ## Setup
    # Deployments
    proof_of_reserve_aggregator = owner.deploy(ProofOfReserveAggregator)
    proof_of_reserve_feed_aave = owner.deploy(MockAggregator)
    proof_of_reserve_feed_dai = owner.deploy(MockAggregator)
    proof_of_reserve_executor_v3 = owner.deploy(ProofOfReserveExecutorV3, pool_addresses_provider_v3, proof_of_reserve_aggregator)

    # Enable PoR feeds
    proof_of_reserve_aggregator.enableProofOfReserveFeed(aave_token, proof_of_reserve_feed_aave, {'from': owner})
    proof_of_reserve_aggregator.enableProofOfReserveFeed(dai, proof_of_reserve_feed_dai, {'from': owner})

    # Set feed answers
    feed_answer_aave = aave_token.totalSupply()
    proof_of_reserve_feed_aave.setAnswer(feed_answer_aave)

    feed_answer_dai = dai.totalSupply()
    proof_of_reserve_feed_dai.setAnswer(feed_answer_dai)

    # Enable [aave, dai] in Executor V3
    proof_of_reserve_executor_v3.enableAssets([aave_token, dai], {'from': owner})

    ## Action
    # Valid
    are_all_reserves_backed = proof_of_reserve_executor_v3.areAllReservesBacked()

    ## Validation
    assert are_all_reserves_backed

    ## Setup
    # Set feed answers
    feed_answer_aave = aave_token.totalSupply() - 1 # Reserve is not backed
    proof_of_reserve_feed_aave.setAnswer(feed_answer_aave)

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
def test_execute_emergency_action(owner, aave_token, dai, pool_addresses_provider_v3, acl_manager_v3, ProofOfReserveAggregator, MockAggregator, ProofOfReserveExecutorV3):
    ## Setup
    # Deployments
    proof_of_reserve_aggregator = owner.deploy(ProofOfReserveAggregator)
    proof_of_reserve_feed_aave = owner.deploy(MockAggregator)
    proof_of_reserve_feed_dai = owner.deploy(MockAggregator)
    proof_of_reserve_executor_v3 = owner.deploy(ProofOfReserveExecutorV3, pool_addresses_provider_v3, proof_of_reserve_aggregator)

    # Enable PoR feeds
    proof_of_reserve_aggregator.enableProofOfReserveFeed(aave_token, proof_of_reserve_feed_aave, {'from': owner})
    proof_of_reserve_aggregator.enableProofOfReserveFeed(dai, proof_of_reserve_feed_dai, {'from': owner})

    # Set feed answers
    feed_answer_aave = aave_token.totalSupply() - 1000 # Reserve not backed
    proof_of_reserve_feed_aave.setAnswer(feed_answer_aave)

    feed_answer_dai = dai.totalSupply()
    proof_of_reserve_feed_dai.setAnswer(feed_answer_dai)

    # Enable [aave, dai] in Executor V3
    proof_of_reserve_executor_v3.enableAssets([aave_token, dai], {'from': owner})

    # Grant `RISK_ADMIN_ROLE` to new executor V3
    acl_admin = '0xa35b76e4935449e33c56ab24b23fcd3246f13470'
    acl_manager_v3.addRiskAdmin(proof_of_reserve_executor_v3, {'from': acl_admin})

    ## Action
    # Execute emergency action
    tx = proof_of_reserve_executor_v3.executeEmergencyAction()

    ## Validation
    assert 'EmergencyActionExecuted' in tx.events
    assert tx.events['AssetIsNotBacked']['asset'] == aave_token

    assert tx.events['CollateralConfigurationChanged']['asset'] == aave_token
    assert tx.events['CollateralConfigurationChanged']['ltv'] == 0
    assert not tx.events['CollateralConfigurationChanged']['liquidationThreshold'] == 0
    assert not tx.events['CollateralConfigurationChanged']['liquidationBonus'] == 0

    assert tx.gas_used < 5_000_000


# Tests `executeEmergencyAction()` when all reserves as backed
def test_execute_emergency_action_backed(owner, aave_token, dai, pool_addresses_provider_v3, acl_manager_v3, ProofOfReserveAggregator, MockAggregator, ProofOfReserveExecutorV3):
    ## Setup
    # Deployments
    proof_of_reserve_aggregator = owner.deploy(ProofOfReserveAggregator)
    proof_of_reserve_feed_aave = owner.deploy(MockAggregator)
    proof_of_reserve_feed_dai = owner.deploy(MockAggregator)
    proof_of_reserve_executor_v3 = owner.deploy(ProofOfReserveExecutorV3, pool_addresses_provider_v3, proof_of_reserve_aggregator)

    # Enable PoR feeds
    proof_of_reserve_aggregator.enableProofOfReserveFeed(aave_token, proof_of_reserve_feed_aave, {'from': owner})
    proof_of_reserve_aggregator.enableProofOfReserveFeed(dai, proof_of_reserve_feed_dai, {'from': owner})

    # Set feed answers
    feed_answer_aave = aave_token.totalSupply()
    proof_of_reserve_feed_aave.setAnswer(feed_answer_aave)

    feed_answer_dai = dai.totalSupply()
    proof_of_reserve_feed_dai.setAnswer(feed_answer_dai)

    # Enable [aave, dai] in Executor V3
    proof_of_reserve_executor_v3.enableAssets([aave_token, dai], {'from': owner})

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

