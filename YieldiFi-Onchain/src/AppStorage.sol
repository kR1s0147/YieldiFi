// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";


contract AppStorage{

    uint8 interestRate= 5;
    uint8 liquidationFee=2;

    enum LoanStatus{NotTaken,Taken,Liquidated}

    
    ISwapRouter public constant swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    address public constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    struct loan{
        LoanStatus status;
        uint88 yr; 
        address _TokenAddress;
        uint amount;
        uint YTTStaked;
        uint timestamp;
        uint lastPaid;
    }
    
    uint256 NumberOfLoans;
    // tracks the loan taken by the user
    mapping(address => loan) loanTaken;

    mapping(address=>mapping(address=>uint)) TokensDeposited;

    mapping(address => uint) ReserveBalance;

    event Deposit(address indexed,uint amount);

    event WithDrawPrincipal(address indexed,uint amount);

    event WithdrawYield(address indexed,uint amount);

    error insufficentAmount(address user);
}
