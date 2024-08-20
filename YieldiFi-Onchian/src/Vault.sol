// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import"@openzeppelin-contracts/token/ERC20/extensions/ERC4626.sol";
contract Vault is ERC4626{
    
    address public Owner;

    constructor(string memory _name,string memory _symbol) ERC20(_name,_symbol){
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


    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) override internal  {
        // If _asset is ERC777, `transferFrom` can trigger a reentrancy BEFORE the transfer happens through the
        // `tokensToSend` hook. On the other hand, the `tokenReceived` hook, that is triggered after the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer before we mint so that any reentrancy would happen before the
        // assets are transferred and before the shares are minted, which is a valid state.
        // slither-disable-next-line reentrancy-no-eth
        
        require(msg.value==assets,"insufficent funds");
        _mint(receiver, shares);

        emit Deposit(caller, receiver, assets, shares);
    }
     function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) override internal  {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }

        // If _asset is ERC777, `transfer`SafeERC20.safeTransfer(_asset, receiver, assets); can trigger a reentrancy AFTER the transfer happens through the
        // `tokensReceived` hook. On the other hand, the `tokensToSend` hook, that is triggered before the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer after the burn so that any reentrancy would happen after the
        // shares are burned and after the assets are transferred, which is a valid state.
        _burn(owner, shares);
        
        require(msg.value == assets);
        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    function transferETH(uint assets,address receiver) public OnlyOwner returns(bool){
        payable(receiver).transfer(assets);
        return true;
    }

    receive() external payable{}
}