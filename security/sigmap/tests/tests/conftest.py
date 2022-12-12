import json
import os
import types
from typing import Dict, Tuple

import brownie
import pytest
from brownie import web3

# Type aliases
CONTRACT_INSTANCE = brownie.network.contract._DeployedContractBase
NAME_WITH_INSTANCE = Tuple[str, CONTRACT_INSTANCE]
NAME_TO_INSTANCE = Dict[str, CONTRACT_INSTANCE]


@pytest.fixture(scope="module", autouse=True)
def mod_isolation(module_isolation):
    """Snapshot ganache at start of module."""
    pass


@pytest.fixture(autouse=True)
def isolation(fn_isolation):
    """Snapshot ganache before every test function call."""
    pass


@pytest.fixture(scope="session")
def constants():
    """Parameters used in the default setup/deployment, useful constants."""
    return types.SimpleNamespace(
        ZERO_ADDRESS=brownie.ZERO_ADDRESS,
        STABLE_SUPPLY=1_000_000 * 10**6,
        MAX_UINT256=2**256 - 1,
    )


# Pytest Adjustments
####################

# Copied from
# https://docs.pytest.org/en/latest/example/simple.html?highlight=skip#control-skipping-of-tests-according-to-command-line-option


def pytest_addoption(parser):
    parser.addoption("--runslow", action="store_true", default=False, help="run slow tests")


def pytest_configure(config):
    config.addinivalue_line("markers", "slow: mark test as slow to run")


def pytest_collection_modifyitems(config, items):
    if config.getoption("--runslow"):
        # --runslow given in cli: do not skip slow tests
        return
    skip_slow = pytest.mark.skip(reason="need --runslow option to run")
    for item in items:
        if "slow" in item.keywords:
            item.add_marker(skip_slow)


## Account Fixtures
###################


@pytest.fixture(scope="module")
def owner(accounts):
    """Account used as the default owner/guardian."""
    return accounts[0]


@pytest.fixture(scope="module")
def proxy_admin(accounts):
    """
    Account used as the admin to proxies.
    Use this account to deploy proxies as it allows the default account (i.e. accounts[0])
    to call contracts without setting the `from` field.
    """
    return accounts[1]


@pytest.fixture(scope="module")
def alice(accounts):
    return accounts[2]


@pytest.fixture(scope="module")
def bob(accounts):
    return accounts[3]


@pytest.fixture(scope="module")
def carol(accounts):
    return accounts[4]


@pytest.fixture(scope="module")
def lost_and_found_addr(accounts):
    """Account used as Lost and Found Address for USDC V2."""
    return accounts[5]


## Mainnet Contracts
####################

# Aave related contracts can be found at https://docs.aave.com/developers/deployed-contracts/deployed-contracts

# Instance of `USDC.e` as `IERC20`
@pytest.fixture(scope='session', autouse=True)
def usdc(interface):
    return interface.IERC20("0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664")

# Instance of `USDT.e` as `IERC20`
@pytest.fixture(scope='session', autouse=True)
def usdt(interface):
    return interface.IERC20("0xc7198437980c041c805A1EDcbA50c1Ce5db95118")

# Instance of `Aave.e` token as `IERC20`
@pytest.fixture(scope='session', autouse=True)
def aave_token(interface):
    return interface.IERC20("0x63a72806098Bd3D9520cC43356dD78afe5D386D9")

# Instance of `DAI.e` token as `IERC20`
@pytest.fixture(scope='session', autouse=True)
def dai(interface):
    return interface.IERC20("0xd586E7F844cEa2F87f50152665BCbc2C279D8d70")

# Instance of `PoolAddressesProvider` V2 as `ILendingPoolAddressesProvider`
@pytest.fixture(scope='session', autouse=True)
def pool_addresses_provider_v2(interface):
    return interface.ILendingPoolAddressesProvider("0xb6A86025F0FE1862B372cb0ca18CE3EDe02A318f")

# Instance of `PoolAddressesProvider` V3 as `IPoolAddressesProvider`
@pytest.fixture(scope='session', autouse=True)
def pool_addresses_provider_v3(interface):
    return interface.IPoolAddressesProvider("0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb")

# Instance of `ACLManager` V3 as `IACLManager`
@pytest.fixture(scope='session', autouse=True)
def acl_manager_v3(interface):
    return interface.IACLManager("0xa72636CbcAa8F5FF95B2cc47F3CDEe83F3294a0B")

# Instance of `LendingPoolConfigurator` V2 as `ILendingPoolConfigurator`
@pytest.fixture(scope='session', autouse=True)
def pool_configurator_v2(interface):
    return interface.ILendingPoolConfigurator("0x230B618aD4C475393A7239aE03630042281BD86e")

# Instance of `PoolConfigurator` V3 as `IPoolConfigurator`
@pytest.fixture(scope='session', autouse=True)
def pool_configurator_v3(interface):
    return interface.IPoolConfigurator("0x8145eddDf43f50276641b55bd3AD95944510021E")

# Instance of `LendingPool` V2 as `IPool`
@pytest.fixture(scope='session', autouse=True)
def pool_v2(interface):
    return interface.IPool("0x4F01AeD16D97E3aB5ab2B501154DC9bb0F1A5A2C")
