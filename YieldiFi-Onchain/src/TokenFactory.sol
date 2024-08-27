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

    mapping(address token => YBTokenPair)  TokenInfo;

    function getPairTokens(address _TokenAddres) public view returns(address ytt,address ptt){
        ytt=TokenInfo[_TokenAddres].YTToken;
        ptt=TokenInfo[_TokenAddres].PTToken;
    }
    function CreateTokenPair(address YBTaddress) public onlyOwner {

        require(TokenInfo[YBTaddress].accepted,"token is accepted");

        PTToken ptt=new PTToken("","ptt",YBTaddress);
        YTToken ytt = new YTToken("","ytt",YBTaddress);

        YBTokenPair storage ybt = TokenInfo[YBTaddress];
        ybt.PTToken= address(ptt);
        ybt.YTToken=address(ytt);
    }
    

    function IntroduceToken(address _TokenAddress,address _underlyingAsset,address _oracle,string calldata _protocol) public onlyOwner returns(bool){
        require(!TokenInfo[_TokenAddress].accepted,"Token is already existed");
        
        YBTokenPair memory ybt= YBTokenPair({
            accepted:true,
            PTToken:address(0),
            YTToken:address(0),
            underlyingAsset:_underlyingAsset,
            oracle:_oracle,
            protocol:_protocol
        });
        TokenInfo[_TokenAddress]=ybt;
        return true;
    }

    function changeOwner(address new_owner) public onlyOwner{
        Owner=new_owner;
    }
}