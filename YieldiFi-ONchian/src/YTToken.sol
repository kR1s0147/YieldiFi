// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin-contracts/token/ERC20/ERC20.sol";


contract YTToken is ERC20{
    address public Owner;
    address public YBTokenAddress;
    modifier OnlyOwner{
        require(msg.sender == Owner);
        _;
    }

    constructor(string memory name_, string memory symbol_,address YBAddress)
    ERC20(name_,symbol_){
        Owner=msg.sender;
        YBTokenAddress=YBAddress;
    }

    function mint(address user,uint amount) public OnlyOwner returns(bool){
        _mint(user,amount);
        return true;
    }  
}