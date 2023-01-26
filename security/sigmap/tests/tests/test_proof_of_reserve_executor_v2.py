"""
Tests for `ProofOfReserveExecutorV2.sol` contract
"""

from brownie import reverts

# Tests `enableAssets()`
def test_enable_assets(owner, constants, usdc, usdt, pool_addresses_provider_v2, ProofOfReserveAggregator, ProofOfReserveExecutorV2):
    ## Setup
    proof_of_reserve_aggregator = owner.deploy(ProofOfReserveAggregator)

    proof_of_reserve_executor_v2 = owner.deploy(ProofOfReserveExecutorV2, pool_addresses_provider_v2, proof_of_reserve_aggregator)

    ## Action
    # Enable USDC
    tx = proof_of_reserve_executor_v2.enableAssets([usdc], {'from': owner})

    ## Validation
    assert tx.events['AssetStateChanged']['asset'] == usdc
    assert tx.events['AssetStateChanged']['enabled']
    assert proof_of_reserve_executor_v2.getAssets() == [usdc]

    ## Action
    # Enable [USDC, USDT] - USDC is already enabled
    tx = proof_of_reserve_executor_v2.enableAssets([usdc, usdt], {'from': owner})

    ## Validation
    assert len(tx.events['AssetStateChanged']) == 1
    assert tx.events['AssetStateChanged']['asset'] == usdt
    assert tx.events['AssetStateChanged']['enabled']
    assert proof_of_reserve_executor_v2.getAssets() == [usdc, usdt]


# Tests `disableAssets()`
def test_disable_assets(owner, constants, usdc, usdt, pool_addresses_provider_v2, ProofOfReserveAggregator, ProofOfReserveExecutorV2):
    ## Setup
    proof_of_reserve_aggregator = owner.deploy(ProofOfReserveAggregator)

    proof_of_reserve_executor_v2 = owner.deploy(ProofOfReserveExecutorV2, pool_addresses_provider_v2, proof_of_reserve_aggregator)

    # Enable USDC
    proof_of_reserve_executor_v2.enableAssets([usdc], {'from': owner})

    ## Action
    # Disable [USDT, USDC]
    tx = proof_of_reserve_executor_v2.disableAssets([usdt, usdc], {'from': owner})

    ## Validation
    assert tx.events['AssetStateChanged']['asset'] == usdc
    assert not tx.events['AssetStateChanged']['enabled']
    assert proof_of_reserve_executor_v2.getAssets() == []


# Tests `areAllReservesBacked()`
def test_are_all_reserves_backed(owner, usdc, usdt, pool_addresses_provider_v2, ProofOfReserveAggregator, MockAggregator, ProofOfReserveExecutorV2):
    ## Setup
    # Deployments
    proof_of_reserve_aggregator = owner.deploy(ProofOfReserveAggregator)
    proof_of_reserve_feed_usdc = owner.deploy(MockAggregator)
    proof_of_reserve_feed_usdt = owner.deploy(MockAggregator)
    proof_of_reserve_executor_v2 = owner.deploy(ProofOfReserveExecutorV2, pool_addresses_provider_v2, proof_of_reserve_aggregator)

    # Enable PoR feeds
    proof_of_reserve_aggregator.enableProofOfReserveFeed(usdc, proof_of_reserve_feed_usdc, {'from': owner})
    proof_of_reserve_aggregator.enableProofOfReserveFeed(usdt, proof_of_reserve_feed_usdt, {'from': owner})

    # Set feed answers
    feed_answer_usdc = usdc.totalSupply()
    proof_of_reserve_feed_usdc.setAnswer(feed_answer_usdc)

    feed_answer_usdt = usdt.totalSupply()
    proof_of_reserve_feed_usdt.setAnswer(feed_answer_usdt)

    # Enable [USDC, USDT] in Executor V2
    proof_of_reserve_executor_v2.enableAssets([usdc, usdt], {'from': owner})

    ## Action
    # Valid
    are_all_reserves_backed = proof_of_reserve_executor_v2.areAllReservesBacked()

    ## Validation
    assert are_all_reserves_backed

    ## Setup
    # Set feed answers
    feed_answer_usdc = usdc.totalSupply() - 1 # Reserve is not backed
    proof_of_reserve_feed_usdc.setAnswer(feed_answer_usdc)

    ## Action
    # Invalid
    are_all_reserves_backed = proof_of_reserve_executor_v2.areAllReservesBacked()

    ## Validation
    assert not are_all_reserves_backed


# Tests `areAllReservesBacked()` when asset list is empty
def test_are_all_reserves_backed_empty(owner, pool_addresses_provider_v2, ProofOfReserveAggregator, ProofOfReserveExecutorV2):
    proof_of_reserve_aggregator = owner.deploy(ProofOfReserveAggregator)
    proof_of_reserve_executor_v2 = owner.deploy(ProofOfReserveExecutorV2, pool_addresses_provider_v2, proof_of_reserve_aggregator)

    assert proof_of_reserve_executor_v2.areAllReservesBacked()


# Tests `executeEmergencyAction()` 
def test_execute_emergency_action(owner, usdc, usdt, pool_addresses_provider_v2, pool_v2, ProofOfReserveAggregator, MockAggregator, ProofOfReserveExecutorV2, ReserveConfiguration):
    ## Setup
    # Deployments
    proof_of_reserve_aggregator = owner.deploy(ProofOfReserveAggregator)
    proof_of_reserve_feed_usdc = owner.deploy(MockAggregator)
    proof_of_reserve_feed_usdt = owner.deploy(MockAggregator)
    proof_of_reserve_executor_v2 = owner.deploy(ProofOfReserveExecutorV2, pool_addresses_provider_v2, proof_of_reserve_aggregator)

    # Enable PoR feeds
    proof_of_reserve_aggregator.enableProofOfReserveFeed(usdc, proof_of_reserve_feed_usdc, {'from': owner})
    proof_of_reserve_aggregator.enableProofOfReserveFeed(usdt, proof_of_reserve_feed_usdt, {'from': owner})

    # Set feed answers
    feed_answer_usdc = usdc.totalSupply() - 1000 # Reserve not backed
    proof_of_reserve_feed_usdc.setAnswer(feed_answer_usdc)

    feed_answer_usdt = usdt.totalSupply()
    proof_of_reserve_feed_usdt.setAnswer(feed_answer_usdt)

    # Enable [USDC, USDT] in Executor V2
    proof_of_reserve_executor_v2.enableAssets([usdc, usdt], {'from': owner})

    # Change `PROOF_OF_RESERVE_ADMIN` to new executor v2
    provider_owner = '0x01244e7842254e3fd229cd263472076b1439d1cd'
    pool_addresses_provider_v2.setPoolAdmin(proof_of_reserve_executor_v2, {'from': provider_owner})

    ## Action
    # Execute emergency action
    tx = proof_of_reserve_executor_v2.executeEmergencyAction()

    ## Validation
    assert 'EmergencyActionExecuted' in tx.events
    assert tx.events['AssetIsNotBacked']['asset'] == usdc

    # Verify pool is frozen
    assert tx.events['ReserveFrozen']['asset'] == usdc
    config = pool_v2.getConfiguration(usdc)[0]
    assert not config & (1 << 57) == 0

    reserves = [
        '0x49d5c2bdffac6ce2bfdb6640f4f80f226bc10bab',
        '0xd586e7f844cea2f87f50152665bcbc2c279d8d70',
        '0xc7198437980c041c805a1edcba50c1ce5db95118',
        '0xa7d7079b0fead91f3e65f86e8915cb59c1a4c664',
        '0x63a72806098bd3d9520cc43356dd78afe5d386d9',
        '0x50b7545627a5162f82a992c33b87adc75187b218',
        '0xb31f66aa3c1e785363f0875a1b74e27b85fd66c7'
    ]

    for (i, reserve) in enumerate(reserves):
        assert tx.events['StableRateDisabledOnReserve'][i]['asset'] == reserves[i]
        assert tx.events['BorrowingDisabledOnReserve'][i]['asset'] == reserves[i]

    assert tx.gas_used < 5_000_000


# Tests `executeEmergencyAction()` when all reserves as backed
def test_execute_emergency_action_backed(owner, usdc, usdt, pool_addresses_provider_v2, ProofOfReserveAggregator, MockAggregator, ProofOfReserveExecutorV2):
    ## Setup
    # Deployments
    proof_of_reserve_aggregator = owner.deploy(ProofOfReserveAggregator)
    proof_of_reserve_feed_usdc = owner.deploy(MockAggregator)
    proof_of_reserve_feed_usdt = owner.deploy(MockAggregator)
    proof_of_reserve_executor_v2 = owner.deploy(ProofOfReserveExecutorV2, pool_addresses_provider_v2, proof_of_reserve_aggregator)

    # Enable PoR feeds
    proof_of_reserve_aggregator.enableProofOfReserveFeed(usdc, proof_of_reserve_feed_usdc, {'from': owner})
    proof_of_reserve_aggregator.enableProofOfReserveFeed(usdt, proof_of_reserve_feed_usdt, {'from': owner})

    # Set feed answers
    feed_answer_usdc = usdc.totalSupply()
    proof_of_reserve_feed_usdc.setAnswer(feed_answer_usdc)

    feed_answer_usdt = usdt.totalSupply()
    proof_of_reserve_feed_usdt.setAnswer(feed_answer_usdt)

    # Enable [USDC, USDT] in Executor V2
    proof_of_reserve_executor_v2.enableAssets([usdc, usdt], {'from': owner})

    # Change `PROOF_OF_RESERVE_ADMIN` to new executor v2
    provider_owner = '0x01244e7842254e3fd229cd263472076b1439d1cd'
    pool_addresses_provider_v2.setPoolAdmin(proof_of_reserve_executor_v2, {'from': provider_owner})

    ## Action
    # Execute emergency action
    tx = proof_of_reserve_executor_v2.executeEmergencyAction()

    ## Validation
    assert not 'EmergencyActionExecuted' in tx.events
    assert not 'AssetIsNotBacked' in tx.events
    assert not 'StableRateDisabledOnReserve' in tx.events
    assert not 'BorrowingDisabledOnReserve' in tx.events

    assert tx.gas_used < 5_000_000


# Tests `isEmergencyActionPossible()` 
def test_is_emergency_action_possible(owner, usdc, usdt, pool_addresses_provider_v2, ProofOfReserveAggregator, MockAggregator, ProofOfReserveExecutorV2):
    ## Setup
    # Deployments
    proof_of_reserve_aggregator = owner.deploy(ProofOfReserveAggregator)
    proof_of_reserve_feed_usdc = owner.deploy(MockAggregator)
    proof_of_reserve_feed_usdt = owner.deploy(MockAggregator)
    proof_of_reserve_executor_v2 = owner.deploy(ProofOfReserveExecutorV2, pool_addresses_provider_v2, proof_of_reserve_aggregator)

    # Enable PoR feeds
    proof_of_reserve_aggregator.enableProofOfReserveFeed(usdc, proof_of_reserve_feed_usdc, {'from': owner})
    proof_of_reserve_aggregator.enableProofOfReserveFeed(usdt, proof_of_reserve_feed_usdt, {'from': owner})

    # Set feed answers
    feed_answer_usdc = usdc.totalSupply() - 1000 # Reserve not backed
    proof_of_reserve_feed_usdc.setAnswer(feed_answer_usdc)

    feed_answer_usdt = usdt.totalSupply()
    proof_of_reserve_feed_usdt.setAnswer(feed_answer_usdt)

    # Enable [USDC, USDT] in Executor V2
    proof_of_reserve_executor_v2.enableAssets([usdc, usdt], {'from': owner})

    # Change `PROOF_OF_RESERVE_ADMIN` to new executor v2
    provider_owner = '0x01244e7842254e3fd229cd263472076b1439d1cd'
    pool_addresses_provider_v2.setPoolAdmin(proof_of_reserve_executor_v2, {'from': provider_owner})

    ## Action
    # `isEmergencyActionPossible()`
    is_possible = proof_of_reserve_executor_v2.isEmergencyActionPossible()

    ## Verification
    assert is_possible

    ## Setup
    # `executeEmergencyAction()` to freeze reserve and disable borrowings
    proof_of_reserve_executor_v2.executeEmergencyAction()

    ## Action
    # `isEmergencyActionPossible()`
    is_possible = proof_of_reserve_executor_v2.isEmergencyActionPossible()

    ## Verification
    assert not is_possible

# Tests `isEmergencyActionPossible()` when borrowing is disabled but not fozen
def test_is_emergency_action_possible_when_borrowing_disabled(owner, usdc, usdt, pool_addresses_provider_v2, pool_configurator_v2, ProofOfReserveAggregator, MockAggregator, ProofOfReserveExecutorV2):
    ## Setup
    # Deployments
    proof_of_reserve_aggregator = owner.deploy(ProofOfReserveAggregator)
    proof_of_reserve_feed_usdc = owner.deploy(MockAggregator)
    proof_of_reserve_feed_usdt = owner.deploy(MockAggregator)
    proof_of_reserve_executor_v2 = owner.deploy(ProofOfReserveExecutorV2, pool_addresses_provider_v2, proof_of_reserve_aggregator)

    # Enable PoR feeds
    proof_of_reserve_aggregator.enableProofOfReserveFeed(usdc, proof_of_reserve_feed_usdc, {'from': owner})
    proof_of_reserve_aggregator.enableProofOfReserveFeed(usdt, proof_of_reserve_feed_usdt, {'from': owner})

    # Set feed answers
    feed_answer_usdc = usdc.totalSupply() - 1000 # Reserve not backed
    proof_of_reserve_feed_usdc.setAnswer(feed_answer_usdc)

    feed_answer_usdt = usdt.totalSupply()
    proof_of_reserve_feed_usdt.setAnswer(feed_answer_usdt)

    # Enable [USDC, USDT] in Executor V2
    proof_of_reserve_executor_v2.enableAssets([usdc, usdt], {'from': owner})

    # Disable borrowing
    pool_admin = pool_addresses_provider_v2.getPoolAdmin()
    pool_configurator_v2.disableBorrowingOnReserve(usdc, {'from': pool_admin})

    ## Action
    # `isEmergencyActionPossible()`
    is_possible = proof_of_reserve_executor_v2.isEmergencyActionPossible()

    ## Verification
    assert is_possible


# Tests `isEmergencyActionPossible()` when frozen but borrowing is not disabled
def test_is_emergency_action_possible_when_frozen(owner, usdc, usdt, pool_addresses_provider_v2, pool_configurator_v2, ProofOfReserveAggregator, MockAggregator, ProofOfReserveExecutorV2):
    ## Setup
    # Deployments
    proof_of_reserve_aggregator = owner.deploy(ProofOfReserveAggregator)
    proof_of_reserve_feed_usdc = owner.deploy(MockAggregator)
    proof_of_reserve_feed_usdt = owner.deploy(MockAggregator)
    proof_of_reserve_executor_v2 = owner.deploy(ProofOfReserveExecutorV2, pool_addresses_provider_v2, proof_of_reserve_aggregator)

    # Enable PoR feeds
    proof_of_reserve_aggregator.enableProofOfReserveFeed(usdc, proof_of_reserve_feed_usdc, {'from': owner})
    proof_of_reserve_aggregator.enableProofOfReserveFeed(usdt, proof_of_reserve_feed_usdt, {'from': owner})

    # Set feed answers
    feed_answer_usdc = usdc.totalSupply() - 1000 # Reserve not backed
    proof_of_reserve_feed_usdc.setAnswer(feed_answer_usdc)

    feed_answer_usdt = usdt.totalSupply()
    proof_of_reserve_feed_usdt.setAnswer(feed_answer_usdt)

    # Enable [USDC, USDT] in Executor V2
    proof_of_reserve_executor_v2.enableAssets([usdc, usdt], {'from': owner})

    # Disable borrowing only for USDC and USDT
    pool_admin = pool_addresses_provider_v2.getPoolAdmin()
    pool_configurator_v2.freezeReserve(usdc, {'from': pool_admin})
    pool_configurator_v2.freezeReserve(usdt, {'from': pool_admin})

    ## Action
    # `isEmergencyActionPossible()`
    is_possible = proof_of_reserve_executor_v2.isEmergencyActionPossible()

    ## Verification
    assert is_possible