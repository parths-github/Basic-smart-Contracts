// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

contract MultiSigWallet {
    // Fire it when someone deposit some amount
    event Deposit(address indexed sender, uint amount);
    // Fire it when one of the owner propose some txn with it's txn id
    event Submit(uint indexed txId);
    // Fire it when some owner approve it
    event Approve(address indexed owner, uint indexed txId);
    // Fire it when some owner changes his mind and cancel the approval
    event Revoke(address indexed owner, uint indexed txId);
    // Fire it when there are enough approval to a txn
    event Execute(uint indexed txId);

    // Struct to store a txn
    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
    }

    // Array to store the addresses of owners
    address[] public owners;
    // Only the owner are allowed to call the most of the function so storing them in mapping 
    mapping(address => bool) public isOwner;
    // No of approval required to executethe txn
    uint public required;

    // Array to store the txns
    Transaction[] public transactions;
    // Mapping to store which txn is approved by which owner
    mapping(uint => mapping(address => bool)) public approved;

    // Need to pass 2 things, address of owner and no of required
    constructor(address[] memory _owners, uint _required) {
        require(_owners.length > 0);
        require(_required > 0 && _required <= _owners.length);
        /* We have to check
        * 1. Each owner is unique
        * 2. Have to set the mapping of isOwner
        * 3. Have to add that owner to state array owners
        */
        
        for (uint i; i < _owners.length; i++) {
            require(!isOwner[_owners[i]] && _owners[i] != address(0));
            isOwner[_owners[i]] = true;
            owners.push(_owners[i]);
        }
        required = _required;
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender]);
        _;
    }

    modifier txExist(uint _txId) {
        require(_txId <= transactions.length);
        _;
    }

    modifier notApproved(uint _txId) {
        require(!approved[_txId][msg.sender]);
        _;      
    }

    modifier notExecuted(uint _txId) {
        require(!transactions[_txId].executed);
        _;      
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function submit(address _to, uint _amount, bytes calldata _data) external onlyOwner {
        transactions.push(Transaction(_to, _amount, _data, false));
        emit Submit(transactions.length-1);
    }

    function approve(uint _txId)
        external
        onlyOwner
        txExist(_txId)
        notApproved(_txId)
        notExecuted(_txId) 
    {
        approved[_txId][msg.sender] = true;
        emit Approve(msg.sender, _txId);
    }

    function _getApprovalCount(uint _txId) private view returns (uint count) {
        for (uint i; i < owners.length; i++) {
            if (approved[_txId][owners[i]]) {
                count++;
            }
        }
    }

    function execute(uint _txId)
        external
        onlyOwner
        txExist(_txId)
        notExecuted(_txId)
    {
        require(_getApprovalCount(_txId) >= required);
        Transaction storage transaction = transactions[_txId];
        transaction.executed = true;
        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success);
        emit Execute(_txId);
    }


    function revoke(uint _txId)
        external
        onlyOwner
        txExist(_txId)
        notExecuted(_txId)
    {
        require(approved[_txId][msg.sender]);
        approved[_txId][msg.sender] = false;
        emit Revoke(msg.sender, _txId);      
    }   
}