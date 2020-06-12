pragma solidity 0.6.8;

// SPDX-License-Identifier: GPL-3.0-only

import "./StandardToken.sol";
import "../RocketBase.sol";
import "../../interface/network/RocketNetworkBalancesInterface.sol";
import "../../interface/token/RocketETHTokenInterface.sol";

// rETH is a tokenized stake in the Rocket Pool network
// rETH is backed by ETH (subject to liquidity) at a variable exchange rate

contract RocketETHToken is RocketBase, StandardToken, RocketETHTokenInterface {

    // Libs
    using SafeMath for uint;

    // Construct
    constructor(address _rocketStorageAddress) RocketBase(_rocketStorageAddress) public {
        version = 1;
    }

    // Get the current ETH : rETH exchange rate
    // Returns the amount of ETH backing 1 rETH
    function getExchangeRate() override public view returns (uint256) {
        // Get network total ETH balance
        RocketNetworkBalancesInterface rocketNetworkBalances = RocketNetworkBalancesInterface(getContractAddress("rocketNetworkBalances"));
        uint256 totalEthBalance = rocketNetworkBalances.getTotalETHBalance();
        // Calculate exchange rate
        uint256 calcBase = 1 ether;
        if (totalSupply == 0) { return calcBase; }
        return calcBase.mul(totalEthBalance).div(totalSupply);
    }

    // Deposit ETH
    // Only accepts calls from the RocketNetworkWithdrawal contract
    function deposit() override external payable onlyLatestContract("rocketNetworkWithdrawal", msg.sender) {}

    // Mint rETH
    // Only accepts calls from the RocketDepositPool contract
    function mint(uint256 _amount, address _to) override external onlyLatestContract("rocketDepositPool", msg.sender) {
        // Check amount
        require(_amount > 0, "Invalid token mint amount");
        // Update balance & supply
        balances[_to] = balances[_to].add(_amount);
        totalSupply = totalSupply.add(_amount);
    }

    // Burn rETH for ETH
    function burn(uint256 _amount) external {
        // TODO: implement
        // 1. Calculate ETH amount and check contract ETH balance
        // 2. Decrease total supply and account balance
        // 3. Update the RP network total ETH balance
        // 4. Transfer ETH to account
    }

}
