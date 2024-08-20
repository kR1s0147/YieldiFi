// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./PTToken.sol";
import "./YTToken.sol";

contract TokenFactory {
    struct YBTokenPair {
        // whether token is accepted or not 
        bool accepted;

        // principal token address
        address PTToken;

        // yield token address
        address YTToken;

        // underlying address
        address underlyingAsset;

        // address of the oracle that provides the price of the asset in USD
        address oracle;

        // mention the protocol it belongs to , AAVE or Compound
        string protocol;
    }


    address public Owner;

    modifier onlyOwner{
        require(msg.sender==Owner);
        _;
    }
    constructor() {
        Owner=msg.sender;
    }

    mapping(address token => YBToken)  TokenInfo;

    
    function CreateTokenPair(address YBTaddress) public onlyOwner {

        require(TokensAccepted[YBTaddress],"token is accepted");

        PTToken ptt=new PTToken("","ptt",YBTaddress);
        YTToken ytt = new YTToken("","ytt",YBTaddress);

        YBToken memory ybt = YBToken(
            {
                PTToken: address(ptt),
                YTToken:address(ytt)
            } 
        );

        TokenAddress[YBTaddress]=ybt;
    }
    

    function IntroduceToken(address _TokenAddress,address _underlyingAsset,address _oracle,string calldata _protocol) public onlyOwner returns(bool){
        require(!TokenInfo[_TokenAddress].accepted,"Token is already existed");
        
        YBTokenPair ybt= YBTokenPair{
            accepted:true,
            PTToken:address(0),
            YTToken:address(0),
            underlyingAsset:_underlyingAsset,
            oracle:_oracle,
            protocol,_protocol
        }
        TokenInfo[_TokenAddress]=ybt;
        return true;
    }

    function changeOwner(address new_owner) public onlyOwner{
        Owner=new_owner;
    }
}