"""
Tests for `ProofOfReserveKeeper.sol` contract
"""

from eth_abi import encode_abi


# Tests `checkUpkeep()` and `performUpkeep()` V2
def test_check_upkeep_v2(
    owner,
    alice,
    usdc,
    pool_addresses_provider_v2,
    MockAggregator,
    ProofOfReserveAggregator,
    ProofOfReserveExecutorV2,
    ProofOfReserveKeeper,
):
    ## Setup
    # Deployments
    proof_of_reserve_aggregator = owner.deploy(ProofOfReserveAggregator)
    proof_of_reserve_feed_usdc = owner.deploy(MockAggregator)
    proof_of_reserve_executor_v2 = owner.deploy(ProofOfReserveExecutorV2, pool_addresses_provider_v2, proof_of_reserve_aggregator)
    proof_of_reserve_keeper = owner.deploy(ProofOfReserveKeeper)

    # Enable PoR feeds
    proof_of_reserve_aggregator.enableProofOfReserveFeed(usdc, proof_of_reserve_feed_usdc, {'from': owner})

    # Set feed answers
    feed_answer_usdc = usdc.totalSupply() - 1000 # Reserve not backed
    proof_of_reserve_feed_usdc.setAnswer(feed_answer_usdc)

    # Enable [USDC] in Executors
    proof_of_reserve_executor_v2.enableAssets([usdc], {'from': owner})

    # Change `PROOF_OF_RESERVE_ADMIN` to new executor v2
    provider_owner = '0x01244e7842254e3fd229cd263472076b1439d1cd'
    pool_addresses_provider_v2.setPoolAdmin(proof_of_reserve_executor_v2, {'from': provider_owner})

    ## Action
    # Check upkeep V2
    check_data = encode_abi(["address"], [proof_of_reserve_executor_v2.address])
    (should_check, data) = proof_of_reserve_keeper.checkUpkeep(check_data)

    ## Validation
    assert check_data == bytes(data)
    assert should_check

    ## Action
    # Perform upkeep V2
    perform_data = encode_abi(["address"], [proof_of_reserve_executor_v2.address])
    tx = proof_of_reserve_keeper.performUpkeep(perform_data, {'from': alice})

    ## Validation
    assert 'EmergencyActionExecuted' in tx.events
    assert tx.events['AssetIsNotBacked']['asset'] == usdc
    
    assert tx.events['ReserveFrozen']['asset'] == usdc

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

    ## Action
    # Check upkeep V2
    (should_check, data) = proof_of_reserve_keeper.checkUpkeep(check_data)

    ## Validation
    assert check_data == bytes(data)
    assert not should_check


# Tests `checkUpkeep()` and `performUpkeep()` V3
def test_check_upkeep_v3(
    owner,
    alice,
    dai,
    pool_addresses_provider_v3,
    acl_manager_v3,
    MockAggregator,
    ProofOfReserveAggregator,
    ProofOfReserveExecutorV3,
    ProofOfReserveKeeper,
):
    ## Setup
    # Deployments
    proof_of_reserve_aggregator = owner.deploy(ProofOfReserveAggregator)
    proof_of_reserve_feed_dai = owner.deploy(MockAggregator)
    proof_of_reserve_executor_v3 = owner.deploy(ProofOfReserveExecutorV3, pool_addresses_provider_v3, proof_of_reserve_aggregator)
    proof_of_reserve_keeper = owner.deploy(ProofOfReserveKeeper)

    # Enable PoR feeds
    proof_of_reserve_aggregator.enableProofOfReserveFeed(dai, proof_of_reserve_feed_dai, {'from': owner})

    # Set feed answers
    feed_answer_dai = dai.totalSupply() - 1000 # Reserve not backed
    proof_of_reserve_feed_dai.setAnswer(feed_answer_dai)

    # Enable [dai] in Executors
    proof_of_reserve_executor_v3.enableAssets([dai], {'from': owner})

    # # Grant `RISK_ADMIN_ROLE` to new executor V3
    acl_admin = '0xa35b76e4935449e33c56ab24b23fcd3246f13470'
    acl_manager_v3.addRiskAdmin(proof_of_reserve_executor_v3, {'from': acl_admin})

    ## Action
    # Check upkeep V3
    check_data = encode_abi(["address"], [proof_of_reserve_executor_v3.address])
    (should_check, data) = proof_of_reserve_keeper.checkUpkeep(check_data)

    ## Validation
    assert check_data == bytes(data)
    assert should_check

    ## Action
    # Perform upkeep V3
    perform_data = encode_abi(["address"], [proof_of_reserve_executor_v3.address])
    tx = proof_of_reserve_keeper.performUpkeep(perform_data, {'from': alice})

    ## Validation
    assert 'EmergencyActionExecuted' in tx.events
    assert tx.events['AssetIsNotBacked']['asset'] == dai

    assert tx.events['CollateralConfigurationChanged']['asset'] == dai
    assert tx.events['CollateralConfigurationChanged']['ltv'] == 0
    assert not tx.events['CollateralConfigurationChanged']['liquidationThreshold'] == 0
    assert not tx.events['CollateralConfigurationChanged']['liquidationBonus'] == 0

    assert tx.gas_used < 5_000_000

    ## Action
    # Check upkeep V3
    (should_check, data) = proof_of_reserve_keeper.checkUpkeep(check_data)

    ## Validation
    assert check_data == bytes(data)
    assert not should_check
