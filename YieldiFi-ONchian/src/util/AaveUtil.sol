// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import "./IPool.sol";
contract AaveUtil{

    event AssetWithdrawAAVE(address indexed user,uint amount);

    IPool public Aavepool= IPool(0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951);

    function calculateYieldAAVE(address aDaiAddress,uint amount) external view returns (uint256) {
        // Get the current lending pool
        
        // Get the normalized income for the DAI reserve
        uint256 normalizedIncome = Aavepool.getReserveNormalizedIncome(aDaiAddress);
        
        // Get the user's aDAI balance
       
        
        // Calculate the total DAI equivalent
        uint256 totalDai = amount* normalizedIncome / 1e27; // Adjust for Aave's RAY (27 decimals)
        
        // Calculate the yield (total DAI - initial deposit)
        uint256 yield = totalDai > amount ? totalDai - amount : 0;
        
        return yield;
    }

    function redeemPTTAAVE(address _TokenAddress,address Asset, address user,uint amount) internal {
        Aavepool.withdraw(Asset,user,amount);
    }

    function redeemYTTAAVE(address _TokenAddress,address Asset,address user,uint amount) internal {
       uint yield= calculateYieldAAVE(Asset, amount);
        Aavepool.withdraw(Asset,user,yield);
    }
    function calculateYieldRateAAVE(address asset) public returns(uint){
        uint yr= Aavepool.getReserveNormalizedIncome(asset);
         return (yr/1e23)%10000;
    }
}