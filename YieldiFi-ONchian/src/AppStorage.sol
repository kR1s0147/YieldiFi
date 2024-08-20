// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;


contract AppStorage{

    uint8 interestRate= 5;
    uint8 liquidationFee=2;

    enum LoanStatus{NotTaken,Taken,Liquidated}

    struct loan{
        LoanStatus status;
        uint88 yr; 
        address _TokenAddress;
        uint amount;
        uint loanCleared;
        uint YTTStaked;
        uint timestamp;
        uint lastPaid;
    }
    
    uint256 NumberOfLoans;
    // tracks the loan taken by the user
    mapping(address => loan) loanTaken;

    mapping(address => uint) ReserveBalance;

    event Deposit(address indexed,uint amount);

    event WithDrawPrincipal(address indexed,uint amount);

    event WithdrawYield(address indexed,uint amount);

    error insufficentAmount(address user);
}
