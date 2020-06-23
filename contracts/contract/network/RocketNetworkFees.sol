pragma solidity 0.6.10;

// SPDX-License-Identifier: GPL-3.0-only

import "../RocketBase.sol";
import "../../interface/deposit/RocketDepositPoolInterface.sol";
import "../../interface/minipool/RocketMinipoolQueueInterface.sol";
import "../../interface/network/RocketNetworkFeesInterface.sol";
import "../../interface/settings/RocketNetworkSettingsInterface.sol";
import "../../lib/SafeMath.sol";

// Network node demand and commission rate

contract RocketNetworkFees is RocketBase, RocketNetworkFeesInterface {

    // Libs
    using SafeMath for uint;

    // Construct
    constructor(address _rocketStorageAddress) RocketBase(_rocketStorageAddress) public {
        version = 1;
    }

    // Get the current RP network node demand in ETH
    // Node demand is equal to deposit pool balance minus available minipool capacity
    function getNodeDemand() override public view returns (int256) {
        // Load contracts
        RocketDepositPoolInterface rocketDepositPool = RocketDepositPoolInterface(getContractAddress("rocketDepositPool"));
        RocketMinipoolQueueInterface rocketMinipoolQueue = RocketMinipoolQueueInterface(getContractAddress("rocketMinipoolQueue"));
        // Calculate & return
        return int256(rocketDepositPool.getBalance()) - int256(rocketMinipoolQueue.getEffectiveCapacity());
    }

    // Get the current RP network node fee as a fraction of 1 ETH
    function getNodeFee() override public view returns (uint256) {
        return getNodeFee(getNodeDemand());
    }

    // Get the RP network node fee for a node demand value
    function getNodeFee(int256 _nodeDemand) override public view returns (uint256) {
        // Calculation base values
        uint256 calcBase = 1 ether;
        int256 demandDivisor = 1000000000000;
        // Get settings
        RocketNetworkSettingsInterface rocketNetworkSettings = RocketNetworkSettingsInterface(getContractAddress("rocketNetworkSettings"));
        uint256 minFee = rocketNetworkSettings.getMinimumNodeFee();
        uint256 targetFee = rocketNetworkSettings.getTargetNodeFee();
        uint256 maxFee = rocketNetworkSettings.getMaximumNodeFee();
        uint256 demandRange = rocketNetworkSettings.getNodeFeeDemandRange();
        // Check range bounds
        if (_nodeDemand == 0) { return targetFee; }
        if (_nodeDemand <= int256(demandRange) * -1) { return minFee; }
        if (_nodeDemand >= int256(demandRange)) { return maxFee; }
        // Get fee interpolation factor
        uint256 t = uint256(((_nodeDemand / (demandDivisor * int256(demandRange))) ** 3) + int256(calcBase));
        // Interpolate between min / target / max fee
        if (t < calcBase) { return minFee.add(targetFee.sub(minFee).mul(t).div(calcBase)); }
        else { return targetFee.add(maxFee.sub(targetFee).mul(t.sub(calcBase)).div(calcBase)); }
    }

}
