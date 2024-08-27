// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "src/Vault.sol";
import "src/main.sol";
import "@aave/interfaces/IPool.sol";
import "@openzeppelin-contracts/token/ERC20/ERC20.sol";

contract TestCase is Test {

    Vault _Vault;
    YieldiFi _yf;

    address aDai=0x29598b72eb5CeBd806C5dCD549490FdA35B13cD8;
    address Dai=0xFF34B3d4Aee8ddCd6F9AFFFB6Fe49bD371b8a357;
    address _oracle=0x14866185B1962B63C3Ea9E03Bc1da838bab34C19;
    address ETHOracle=0x694AA1769357215DE4FAC081bf1f309aDC325306;
    address Me=0x9CFb08Ed5169990c39E28144c630585b7725c9d5;

    IPool pool=IPool(0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951);
    address Dytt;
    address Dptt;
    function setUp() public{
        string memory rpc="https://sepolia.infura.io/v3/6518332f09254566878d16571dfb9468";
        vm.createSelectFork(rpc);

        vm.startPrank(address(0));
        _Vault= new Vault("VAULT","VAL"); 
        _yf= new YieldiFi(address(_Vault));
        _Vault.setYieldFi(address(_yf));
        require(_yf.IntroduceToken(aDai,Dai,_oracle, "AAVE"));
        _yf.CreateTokenPair(aDai);
        (Dytt, Dptt)= _yf.getPairTokens(aDai);
        _yf.IntroduceToken(address(0),address(0),ETHOracle,"");
        deal(address(2),100 ether);
        vm.stopPrank();
    }

    function test_Yieldifi() public {
        ERC20 adai=ERC20(aDai);
        ERC20 dai=ERC20(Dai);
        ERC20 ytt=ERC20(Dytt);
        ERC20 ptt=ERC20(Dptt);
        vm.startPrank(address(1));
        deal(address(1),100 ether);
        _Vault.DepositEth{value:1 ether}(1 ether,address(1));
        vm.stopPrank();

        vm.startPrank(Me);
        dai.approve(address(pool),1e24);
        adai.approve(address(pool),1e24);
        dai.approve(address(_yf),type(uint256).max);
        adai.approve(address(_yf),type(uint256).max);
        ytt.approve(0x5a443704dd4B594B382c22a083e2BD3090A6feF3,type(uint256).max);
        ptt.approve(0x5a443704dd4B594B382c22a083e2BD3090A6feF3,type(uint256).max);
        uint d= 100 * 1e18;
        pool.supply(Dai,d,Me,0);
        require(_yf.DepositYBT(aDai,d));
        
        require(ytt.balanceOf(Me)==ptt.balanceOf(Me));
        console.log(adai.balanceOf(Me));

        console.log(address(Me).balance);
        require(_yf.borrow(0.01 ether,aDai));


        console.log(address(Me).balance);
        vm.stopPrank();
    }
}