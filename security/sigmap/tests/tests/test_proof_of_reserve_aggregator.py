"""
Tests for `ProofOfReserveAggregator.sol` contract
"""

from brownie import reverts

# Tests constructor
def test_constructor(owner, constants, ProofOfReserveAggregator):
    proof_of_reserve_aggregator = owner.deploy(ProofOfReserveAggregator)

    assert proof_of_reserve_aggregator.owner() == owner
    assert proof_of_reserve_aggregator.getProofOfReserveFeedForAsset(constants.ZERO_ADDRESS) == constants.ZERO_ADDRESS


# Tests `enableProofOfReserveFeed()`
def test_enable_proof_of_reserve_feed(
    owner,
    usdc,
    pool_addresses_provider_v2,
    ProofOfReserveAggregator,
    MockAggregator
):
    ## Setup
    proof_of_reserve_aggregator = owner.deploy(ProofOfReserveAggregator)
    proof_of_reserve_feed = owner.deploy(MockAggregator)
    proof_of_reserve_feed_2 = owner.deploy(MockAggregator)

    ## Action
    tx = proof_of_reserve_aggregator.enableProofOfReserveFeed(usdc, proof_of_reserve_feed, {'from': owner})

    ## Validation
    assert tx.events['ProofOfReserveFeedStateChanged']['asset'] == usdc
    assert tx.events['ProofOfReserveFeedStateChanged']['proofOfReserveFeed'] == proof_of_reserve_feed
    assert tx.events['ProofOfReserveFeedStateChanged']['enabled'] == True
    assert proof_of_reserve_aggregator.getProofOfReserveFeedForAsset(usdc) == proof_of_reserve_feed

    ## Action
    tx = proof_of_reserve_aggregator.enableProofOfReserveFeed(usdc, proof_of_reserve_feed_2, {'from': owner})

    ## Validation
    assert tx.events['ProofOfReserveFeedStateChanged']['asset'] == usdc
    assert tx.events['ProofOfReserveFeedStateChanged']['proofOfReserveFeed'] == proof_of_reserve_feed_2
    assert tx.events['ProofOfReserveFeedStateChanged']['enabled'] == True
    assert proof_of_reserve_aggregator.getProofOfReserveFeedForAsset(usdc) == proof_of_reserve_feed_2


# Tests `disableProofOfReserveFeed()`
def test_disable_proof_of_reserve_feed(
    owner,
    constants,
    usdc,
    pool_addresses_provider_v2,
    ProofOfReserveAggregator,
    MockAggregator
):
    ## Setup
    proof_of_reserve_aggregator = owner.deploy(ProofOfReserveAggregator)
    proof_of_reserve_feed = owner.deploy(MockAggregator)
    
    proof_of_reserve_aggregator.enableProofOfReserveFeed(usdc, proof_of_reserve_feed, {'from': owner})

    ## Action
    tx = proof_of_reserve_aggregator.disableProofOfReserveFeed(usdc, {'from': owner})

    ## Validation
    assert tx.events['ProofOfReserveFeedStateChanged']['asset'] == usdc
    assert tx.events['ProofOfReserveFeedStateChanged']['proofOfReserveFeed'] == constants.ZERO_ADDRESS
    assert tx.events['ProofOfReserveFeedStateChanged']['enabled'] == False
    assert proof_of_reserve_aggregator.getProofOfReserveFeedForAsset(usdc) == constants.ZERO_ADDRESS

    ## Action
    # TODO: Should this fail as it's already disabled?
    tx = proof_of_reserve_aggregator.disableProofOfReserveFeed(usdc, {'from': owner})

    ## Validation
    assert tx.events['ProofOfReserveFeedStateChanged']['asset'] == usdc
    assert tx.events['ProofOfReserveFeedStateChanged']['proofOfReserveFeed'] == constants.ZERO_ADDRESS
    assert tx.events['ProofOfReserveFeedStateChanged']['enabled'] == False
    assert proof_of_reserve_aggregator.getProofOfReserveFeedForAsset(usdc) == constants.ZERO_ADDRESS



# Tests `enableProofOfReserveFeed()` and `disableProofOfReserveFeed()` when not the owner
def test_owner_access_control(owner, alice, constants, usdc, pool_addresses_provider_v2, ProofOfReserveAggregator, MockAggregator):
    ## Setup
    proof_of_reserve_aggregator = owner.deploy(ProofOfReserveAggregator)
    proof_of_reserve_feed = owner.deploy(MockAggregator)

    ## Action
    with reverts('Ownable: caller is not the owner'):
        proof_of_reserve_aggregator.enableProofOfReserveFeed(usdc, proof_of_reserve_feed, {'from': alice})

    ## Action
    with reverts('Ownable: caller is not the owner'):
        proof_of_reserve_aggregator.disableProofOfReserveFeed(usdc, {'from': alice})


# Tests `areAllReservesBacked()`
def test_are_all_reserves_backed(owner, constants, usdc, usdt, pool_addresses_provider_v2, ProofOfReserveAggregator, MockAggregator):
    ## Setup
    # Deployments
    proof_of_reserve_aggregator = owner.deploy(ProofOfReserveAggregator)
    proof_of_reserve_feed_usdc = owner.deploy(MockAggregator)
    proof_of_reserve_feed_usdt = owner.deploy(MockAggregator)

    # Enable PoR feeds
    proof_of_reserve_aggregator.enableProofOfReserveFeed(usdc, proof_of_reserve_feed_usdc, {'from': owner})
    proof_of_reserve_aggregator.enableProofOfReserveFeed(usdt, proof_of_reserve_feed_usdt, {'from': owner})

    # Set feed answers
    feed_answer_usdc = usdc.totalSupply()
    proof_of_reserve_feed_usdc.setAnswer(feed_answer_usdc)

    feed_answer_usdt = usdt.totalSupply()
    proof_of_reserve_feed_usdt.setAnswer(feed_answer_usdt)

    ## Action
    # Zero assets
    are_reserves_backed, unbacked_assets_flags = proof_of_reserve_aggregator.areAllReservesBacked([])

    ## Validation
    assert are_reserves_backed
    assert unbacked_assets_flags == []

    ## Action
    # One assets
    are_reserves_backed, unbacked_assets_flags = proof_of_reserve_aggregator.areAllReservesBacked([usdc])

    ## Validation
    assert are_reserves_backed
    assert unbacked_assets_flags == [False]

    ## Action
    # Two assets
    are_reserves_backed, unbacked_assets_flags = proof_of_reserve_aggregator.areAllReservesBacked([usdc, usdt])

    ## Validation
    assert are_reserves_backed
    assert unbacked_assets_flags == [False, False]


# Tests `areAllReservesBacked()`
def test_are_all_reserves_backed_invalid(owner, constants, usdc, usdt, pool_addresses_provider_v2, ProofOfReserveAggregator, MockAggregator):
    ## Setup
    # Deployments
    proof_of_reserve_aggregator = owner.deploy(ProofOfReserveAggregator)
    proof_of_reserve_feed_usdc = owner.deploy(MockAggregator)
    proof_of_reserve_feed_usdt = owner.deploy(MockAggregator)

    # Enable PoR feeds
    proof_of_reserve_aggregator.enableProofOfReserveFeed(usdc, proof_of_reserve_feed_usdc, {'from': owner})
    proof_of_reserve_aggregator.enableProofOfReserveFeed(usdt, proof_of_reserve_feed_usdt, {'from': owner})

    # Set feed answers
    feed_answer_usdc = usdc.totalSupply() - 1 # Reserve is not backed
    proof_of_reserve_feed_usdc.setAnswer(feed_answer_usdc)

    feed_answer_usdt = usdt.totalSupply()
    proof_of_reserve_feed_usdt.setAnswer(feed_answer_usdt)

    ## Action
    # Two assets - one invalid
    are_reserves_backed, unbacked_assets_flags = proof_of_reserve_aggregator.areAllReservesBacked([usdc, usdt])

    ## Validation
    assert not are_reserves_backed
    assert unbacked_assets_flags == [True, False]


# Tests `areAllReservesBacked()` negative answer
def test_are_all_reserves_backed_negative(owner, constants, usdc, usdt, pool_addresses_provider_v2, ProofOfReserveAggregator, MockAggregator):
    ## Setup
    # Deployments
    proof_of_reserve_aggregator = owner.deploy(ProofOfReserveAggregator)
    proof_of_reserve_feed_usdc = owner.deploy(MockAggregator)

    # Enable PoR feeds
    proof_of_reserve_aggregator.enableProofOfReserveFeed(usdc, proof_of_reserve_feed_usdc, {'from': owner})

    # Set feed answers
    feed_answer_usdc = - 1 # negative answer
    proof_of_reserve_feed_usdc.setAnswer(feed_answer_usdc)

    ## Action
    # One assets - negative answer
    are_reserves_backed, unbacked_assets_flags = proof_of_reserve_aggregator.areAllReservesBacked([usdc])

    ## Validation
    assert not are_reserves_backed
    assert unbacked_assets_flags == [True]

