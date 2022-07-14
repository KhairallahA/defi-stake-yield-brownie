// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenFarm is Ownable {
    IERC20 public dappToken;

    address[] public stakers;
    // mapping token address -> mapping stake address -> amount
    mapping(address => mapping(address => uint256)) public stakingBalance;
    mapping(address => uint256) public uniqueTokensStaked;
    mapping(address => address) public tokenPriceFeedMapping;
    address[] public allowedTokens; // 0 -> ETH || 1 -> DAI || 2 -> WETH


    constructor(address _dappTokenAddress) public {
        dappToken = IERC20(_dappTokenAddress);
    }

    function setPriceFeedContract(address _dappTokenAddress, address _priceFeed) public onlyOwner {
        tokenPriceFeedMapping[_dappTokenAddress] = _priceFeed;
    }

    function issueTokens() public onlyOwner {
        // Issue tokens to all stakers
        for(
            uint256 stakersIndex = 0; 
            stakersIndex < stakers.length; 
            stakersIndex++
        ) {
            address recipient = stakers[stakersIndex];
            uint256 userTotalValue = getUserTotalValue(recipient);
            // send them a token reward
            // based on their total value locked
            dappToken.transfer(recipient, userTotalValue);
        }
    }

    function getUserTotalValue(address _user) public view returns (uint256) {
        uint256 totalValue = 0;
        require(uniqueTokensStaked[_user] > 0, "No tokens staked!");
        for(
            uint256 allowedTokensIndex = 0; 
            allowedTokensIndex < allowedTokens.length; 
            allowedTokensIndex++
        ) {
            totalValue = totalValue + getUserSingleTotalValue(_user, allowedTokens[allowedTokensIndex]);
        }
        return totalValue;
    }

    function getUserSingleTotalValue(address _user, address _token) public view returns (uint256) {
        if(uniqueTokensStaked[_user] <= 0) {
            return 0;
        }
        (uint256 price, uint256 decimals) = getTokenPrice(_token);
        return
            (stakingBalance[_token][_user] * price) / (10**decimals);
    }

    function getTokenPrice(address _token) public view returns (uint256, uint256) {
        address priceFeedAddress = tokenPriceFeedMapping[_token];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddress);
        (,int256 price,,,) = priceFeed.latestRoundData();
        uint256 decimals = uint256(priceFeed.decimals());
        return (uint256(price), decimals);
    }

    function stakeTokens(uint256 _amount, address _token) public {
        // what tokens can they stake?
        // how much can they stake?
        require(_amount > 0, "Amount must be more than 0");
        require(tokenIsAllowed(_token), "Token is currently no allowed");
        updateUniqueTokensStaked(msg.sender, _token);
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        stakingBalance[_token][msg.sender] = stakingBalance[_token][msg.sender] + _amount;
        if(uniqueTokensStaked[msg.sender] == 1) {
            stakers.push(msg.sender);
        }
    }

    // Unstaking Tokens (Withdraw)
    function unstakeTokens(address token) public {
        // NOTE:
        // This is vulnerable to a reentrancy attack!!!
            // Fetch staking balance
        uint256 balance = stakingBalance[token][msg.sender];
        require(balance > 0, "staking balance cannot be 0");
        IERC20(token).transfer(msg.sender, balance);
        stakingBalance[token][msg.sender] = 0;
        uniqueTokensStaked[msg.sender] = uniqueTokensStaked[msg.sender] - 1;
    } 

    function updateUniqueTokensStaked(address _user, address _token) internal {
        if(stakingBalance[_token][_user] <= 0) {
            uniqueTokensStaked[_user] = uniqueTokensStaked[_user] + 1;
        }
    }

    function addAllowedTokens(address _token) public onlyOwner {
        allowedTokens.push(_token);
    }

    function tokenIsAllowed(address _token) public returns (bool) {
        for(
            uint256 allowedTokensIndex=0; 
            allowedTokensIndex < allowedTokens.length; 
            allowedTokensIndex++
        ) {
            if(allowedTokens[allowedTokensIndex] == _token) {
                return true;
            }
        }
        return false;
    }
}