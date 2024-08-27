// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import"@openzeppelin-contracts/token/ERC20/extensions/ERC4626.sol";
contract Vault is ERC4626{
    
    address public Owner;
    address public yieldiFi;
    constructor(string memory _name,string memory _symbol) ERC20(_name,_symbol) ERC4626(IERC20(address(0))){
        Owner=msg.sender;
    }

    modifier OnlyOwner{
        require(msg.sender==Owner,"NOT authorised");
        _;
    }

    function setOwner(address newOwner) public{
        require(msg.sender==Owner,"sender is not owner");
        Owner=newOwner;
    }

    function setYieldFi(address _yf) public{
        require(msg.sender==Owner);
        yieldiFi=_yf;
    }


    function transferETH(uint assets,address receiver) public returns(bool){
        require(msg.sender==yieldiFi);
        payable(receiver).transfer(assets);
        return true;
    }
    

    function DepositEth(uint amount , address receiver) public payable returns(uint shares){
        require(msg.value>=amount,"not enough");
        shares = previewDeposit(amount);
        _mint(receiver,shares);
        emit Deposit(msg.sender, receiver,amount, shares);
        return shares;
    }

    function withdrawEth(uint amount ,address receiver) public returns(uint){
        uint256 shares = previewWithdraw(amount);
        _withdraw(_msgSender(), receiver, msg.sender, amount, shares);
        payable(receiver).transfer(amount);
        return shares;
    }

    function RedeemEth(uint shares,address receiver) public returns(uint){
        uint256 assets = previewRedeem(shares);
        _withdraw(_msgSender(), receiver, msg.sender, assets, shares);
         payable(receiver).transfer(assets);
         return assets;

    }
    receive() external payable{}
}