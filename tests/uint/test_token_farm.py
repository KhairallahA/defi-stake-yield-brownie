from scripts.deploy import deploy_token_farm_and_dapp_token, KEPT_BALANCE
from scripts.helpful_scripts import (
    LOCAL_BLOCKCHAIN_ENVIRONMENTS,
    INITIAL_PRICE_FEED_VALUE,
    DECIMALS,
    get_account,
    get_contract,
)
from brownie import network, exceptions
import pytest
from web3 import Web3


def test_add_allowed_tokens():
    # Arrange
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local testing!")
    account = get_account()
    non_owner = get_account(1)
    token_farm, dapp_token = deploy_token_farm_and_dapp_token()
    # Act
    token_farm.addAllowedTokens(dapp_token, {"from": account})
    # Assert
    assert token_farm.allowedTokens(0) == dapp_token.address
    with pytest.raises(exceptions.VirtualMachineError):
        token_farm.addAllowedTokens(dapp_token, {"from": non_owner})

def test_set_price_feed_contract():
    # Arrange
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local testing!")
    account = get_account()
    non_owner = get_account(1)
    token_farm, dapp_token = deploy_token_farm_and_dapp_token()
    # Act
    token_farm.setPriceFeedContract(
        dapp_token.address, get_contract("eth_usd_price_feed"), {"from": account}
    )
    # Assert
    token_farm.tokenPriceFeedMapping(dapp_token.address) == get_contract(
        "eth_usd_price_feed"
    )
    with pytest.raises(exceptions.VirtualMachineError):
        token_farm.setPriceFeedContract(
            dapp_token.address, get_contract("eth_usd_price_feed"), {"from": non_owner}
        )

def test_stake_tokens(amount_staked):
    # Arrange
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local testing!")
    account = get_account()
    token_farm, dapp_token = deploy_token_farm_and_dapp_token()
    # Act
    dapp_token.approve(token_farm.address, amount_staked, {"from": account})
    token_farm.stakeTokens(
        amount_staked, dapp_token.address, {"from": account}
    )
    # Assert
    assert token_farm.uniqueTokensStaked(account.address) == 1
    assert token_farm.stakingBalance(dapp_token.address, account.address) == amount_staked
    assert token_farm.stakers(0) == account.address
    return token_farm, dapp_token

def test_stake_unapproved_tokens(amount_staked, random_erc20):
    # Arrange
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local testing!")
    account = get_account()
    token_farm, dapp_token = deploy_token_farm_and_dapp_token()
    # Act / Assert
    dapp_token.approve(token_farm.address, amount_staked, {"from": account})
    with pytest.raises(exceptions.VirtualMachineError):
        token_farm.stakeTokens(
            amount_staked, random_erc20.address, {"from": account}
        )

def test_unstake_tokens(amount_staked):
    # Arrange
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local testing!")
    account = get_account()
    token_farm, dapp_token = test_stake_tokens(amount_staked)
    # Act
    token_farm.unstakeTokens(dapp_token.address, {"from": account})
    # Assert
    assert token_farm.uniqueTokensStaked(account.address) == 0
    assert token_farm.stakingBalance(dapp_token.address, account.address) == 0


def test_issue_tokens(amount_staked):
    # Arrange
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local testing!")
    account = get_account()
    token_farm, dapp_token = test_stake_tokens(amount_staked)
    starting_balance = dapp_token.balanceOf(account.address)
    # Act
    token_farm.issueTokens({"from": account})
    # Assert
    assert dapp_token.balanceOf(account.address) == starting_balance + INITIAL_PRICE_FEED_VALUE