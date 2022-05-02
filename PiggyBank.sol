// SPDX-License-Identifier:MIT
pragma solidity ^0.8.10;


// Simple contract in which anyone can deposit ether but only owner of contract can withdraw it
// When withdrawing PIggyBank needs to be broken so contract shold be selfdestructed
contract PiggyBank {
    event Deposit(uint amount);
    event Withdraw(uint amount);
    address public owner;
    constructor () {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }

    receive() external payable{
        emit Deposit(msg.value);
    }

    function withdraw() external onlyOwner {
        emit Withdraw(address(this).balance);
        selfdestruct(payable(owner));
    }
}