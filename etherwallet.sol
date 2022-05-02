// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract EtherWallet {
    address payable public owner;


    constructor () {
        owner = payable(msg.sender);
    }

    receive() external payable {}

    function withdraw(uint _amount) external {
        require(msg.sender == owner);
        payable(msg.sender).transfer(_amount);

        // (bool sent,) = msg.sender.call{value: _amount}("");
        // require(sent);
    }

    function getBalance() external view returns (uint){
        return address(this).balance;
    }
}