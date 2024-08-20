// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import "./AppStorage.sol";
import "./TokenFactory.sol";
import "@openzeppelin-contracts/token/ERC20/ERC20.sol";

import "./Vault.sol";

import "./util/AggregatorV3Interface.sol";
2contract YieldiFi is AppStorage,TokenFactory{

    Vault assetVault;

    event WithdrawAAVE(address indexed _TokenAddress,address user, uint amount);
     constructor(){
     }

    modifier istokenAccepted(address tokenaddr){
        require(TokenInfo[tokenaddr].accepted,"Token is not accepted");
        _;
    }

    modifier isTokenHasYTpairs(address _TokenAddress){
        YBTokenPair ybt= TokenInfo[_TokenAddress];
        require(ybt.PTToken!=address(0),"Token is not accepted");
        _;
    }

    function setVault(address newaddress) public onlyOwner{
        assetVault=Vault(newaddress);
    }
     function DepositYBT(address _TokenAddress,uint amount) public istokenAccepted(_TokenAddress) isTokenHasYTpairs(_TokenAddress) returns(bool){

        ERC20 ybt=ERC20(_TokenAddress);

        YBTokenPair ybtp=TokenInfo[_TokenAddress];
        ybt.transferFrom(msg.sender,address(this),amount);

        if(ybtp.PTToken == address(0)){
            CreateTokenPair(_TokenAddress);
        }

        (bool res1,)= ybtp.PTToken.call(abi.encodeWithSignature("mint(address,uint)",msg.sender,amount));
        (bool res2,)= ybtp.YTToken.call(abi.encodeWithSignature("mint(address,uint)",msg.sender,amount));
        
        TokensDeposited[_TokenAddress][msg.sender]+=amount;
        require(res1&&res2,"Yield and Prinicipal Tokens are not minted");

        emit Deposit(msg.sender, amount);
        
        return true;  
     }
 
     function redeemPTT(address _TokenAddress,uint amount) public istokenAccepted(_TokenAddress) isTokenHasYTpairs(_TokenAddress) returns(bool){
        _handle(_TokenAddress,amount,0);
     }

     function redeemYTT(address _TokenAddress,uint amount) public istokenAccepted(_TokenAddress) isTokenHasYTpairs(_TokenAddress) returns(bool){
        _handle(_TokenAddress,amount,1);
     }

    function WithdrawYBT(address _TokenAddress,uint amount) public istokenAccepted(_TokenAddress) isTokenHasYTpairs(_TokenAddress) returns(bool){
        _handle(_TokenAddress,amount,2);   
    }

    function _handle(address _TokenAddress,uint amount,uint8 num) internal returns(uint){

        YBTokenPair ybt=TokenInfo[_TokenAddress];

        if (keccak256(abi.encodePacked(ybt.protocol)) == keccak256(abi.encodePacked("AAVE"))){
            if (num == 0){
                ERC20 ptt=ERC20(ybt.PTToken);
                ptt.call(abi.encodeWithSignature("burn(address,uint256)",msg.sender,amount));
                redeemPTTAAVE(_TokenAddress,ybt.underlyingAsset,msg.sender, amount);
                return 0;
            }
            else if(num==1){
                ERC20 ytt=ERC20(ybt.yTToken);
                ytt.call(abi.encodeWithSignature("burn(address,uint256)",msg.sender,amount));
                redeemYTTAAVE(_TokenAddress,ybt.underlyingAsset,msg.sender, amount);
            }
            else if(num==2){
                ERC20 ptt=ERC20(ybt.PTToken);
                ERC20 ytt=ERC20(ybt.yTToken);
                ptt.call(abi.encodeWithSignature("burn(address,uint256)",msg.sender,amount));
                ytt.call(abi.encodeWithSignature("burn(address,uint256)",msg.sender,amount));
                ERC20 token=ERC20(_TokenAddress);
                token.transfer(msg.sender, amount);
                emit WithdrawAAVE(_TokenAddress,msg.sender,amount);
            }
            else if(num==3){

              return  calculateYieldRateAAVE(TokenInfo[_TokenAddress].underlyingAsset);
            }
            else{
                revert("Invalid Protocol");
            }
        }

    }

    
    function borrow(uint amount,address StakingAsset) public istokenAccepted(StakingAsset) isTokenHasYTpairs(StakingAsset) returns(uint id){
        
        require(loanTaken[msg.sender].status==LoanStatus.NotTaken,"Loan already taken");
        YBTokenPair ybt= TokenInfo[StakingAsset];
        
        uint yr=_handle(StakingAsset,0,3);
        
        ERC20 ytt=ERC20(ybt.YTToken);

        int256 ETHPrice=getAssetPrice(address(0));
        int256 AssetPrice=getAssetPrice(StakingAsset);

        uint bal=ytt.balanceOf(msg.sender);
        uint maxlimit= (bal*yr*7)/100000;
        
        
        
        require(amount<maxlimit,"NOT Enough Yield Token");
        
        uint256 loanAmount= ((bal * AssetPrice)/ETHPrice)/1e8;
        assetVault.transferETH(amount,msg.sender);

        uint stakedAmount= (amount*10)/7;
        loan newLoan=loan{
            status:LoanStatus.LoanTaken,
            _TokenAddress:StakingAsset,
            amount:amount,
            YTTStaked:loanAmount,
            timestamp:block.timestamp,
            lastPaid:block.timestamp
        }

        loanTaken[msg.sender]= newLoan;
        ytt.transferFrom(msg.sender,address(this),stakedAmount);
    }


    function getAssetPrice(address Asset) internal returns(int256){
        AggregatorV3Interface df=getAggregatorV3Interface(TokenInfo[Asset]);
        (,int256 answer,,,)=df.latestRoundData();
        return answer;
    }

    function repay(uint amount) public payable returns(bool){
        loan storage userLoan=loanTaken[msg.sender];

        require(loanTaken[msg.sender].status==LoanStatus.Taken,"Loan is not Taken taken");
        
        uint interest= calculateIntrest(userLoan.amount,userLoan.lastPaid);
        require(msg.value >= (amount+interest),"insufficient balance");
        address(assetVault).transfer(msg.value);
        ERC20 ytt= ERC20(TokenInfo[userLoan._TokenAddress].YTToken);
        ytt.transfer(msg.sender,userLoan.YTTStaked);
        
        delete userLoan;
    }

    function payInterst() public payable returns(bool){
        loan storage userLoan=loanTaken[msg.sender];
        require(loanTaken[msg.sender].status==LoanStatus.Taken,"Loan is not Taken taken");
        uint interest= calculateIntrest(userLoan.amount,userLoan.lastPaid);
        require(msg.value >= interest,"insufficient balance");
        address(assetVault).transfer(msg.value);
        userLoan.lastPaid = block.timestamp;
    }

    function calculateInterest (uint amount,uint timestamp) public view returns(uint interest){
        
        uint time= (block.timestamp-timestamp)/1 days;

        uint dailyInterest = ( interestRate *1e6 )/365;

        interest = (amount*time*dailyIntrest*)/1e8;

    } 

    function liquidate(address user) public returns(bool){
        require(msg.sender!=user,"cannot liquidate yourself");
        loan storage userLoan=loanTaken[user];
        require(loanTaken[user].status==LoanStatus.Taken,"Loan is not Taken taken");
        require(checkLiquidation(user,userLoan),"Cannot liquidate this loan");
            
    }

    function checkLiquidation(address user,loan storage userLoan) internal returns(bool){
        if(((block.timestamp-userLoan.lastPaid)/1 days)>45){
            return true;
        }
        else{
           uint currentYr=_handle(userLoan._TokenAddress,0,3);
           if(currentYr<=userLoan.yr){
            return false;
           }
           else{
            int256 ETHPrice=getAssetPrice(address(0));
            int256 AssetPrice=getAssetPrice(StakingAsset);

            uint bal=ytt.balanceOf(user);
            uint maxlimit= (bal*yr*7)/100000;
           }
        }
    }
}
