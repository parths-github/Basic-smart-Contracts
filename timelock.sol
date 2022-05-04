// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/* TimeLock is a contract that publishes a transaction to be executed in the future. 
After a mimimum waiting period, the transaction can be executed.
TimeLocks are commonly used in DAOs.
User can trust better coz they have time until the txn is executed and they can revert it */

contract TimeLock {
    /* There are 2 functions.
    1. queue()- To queue the txn, should only be called by owner
    2. execute() - after the required time txn can be executed
    */
    address public owner;
    // Mapping to kepp tarck of which txn is queued
    mapping(bytes32 => bool) queued;
    uint public constant MIN_DELAY = 10;
    uint public constant MAX_DELAY = 1000;
    uint public constant GRACE_PERIOD = 1000; // seconds



    error NotOwnerError();
    error AlreadyQueuedError(bytes32 txId);
    error TimestampNotInRangeError(uint blockTimestamp, uint timestamp);
    error NotQueuedError(bytes32 txId);
    error TimestampNotPassedError(uint blockTimestmap, uint timestamp);
    error TimestampExpiredError(uint blockTimestamp, uint expiresAt);
    error TxFailedError();

    event Queue(
        bytes32 indexed txId,
        address indexed target,
        uint value,
        string func,
        bytes data,
        uint timestamp
    );
    event Execute(
        bytes32 indexed txId,
        address indexed target,
        uint value,
        string func,
        bytes data,
        uint timestamp
    );
    event Cancel(bytes32 indexed txId);


    constructor () {
        owner = msg.sender;
    }

    // to receive ether
    receive() external payable {}
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwnerError();
        }
        _;
    }

    // Function to get the txn Id
    function getTxId(
        address _target,
        uint _value,
        string calldata _func,
        bytes calldata _data,
        uint _timestamp
    ) public pure returns (bytes32 txId) {
        return keccak256(abi.encode(
            _target, _value, _func, _data, _timestamp
        ));
    }
    function queue(
        address _target,
        uint _value,
        string calldata _func,
        bytes calldata _data,
        uint _timestamp
    ) external onlyOwner {
        // _target- address of contract whose function will be called
        // _value- value eth to be sent 
        // _func -name of func to be called, for example "foo(address,uint256)"
        // _data- data of function, ABI encoded data send.
        // _timestamp- after which this txn can be executed


        // tobe done
        // 1. Create txID
        bytes32 txId = getTxId( _target, _value, _func, _data, _timestamp);
        // 2. check txId for uniqueness
        if (queued[txId]) {
            revert AlreadyQueuedError(txId);
        }
        // 3. timestamp must be in range from max duration and min duration
        // ---|------------|---------------|-------
        //  block    block + min     block + max
        if (_timestamp < block.timestamp + MIN_DELAY ||
            _timestamp > block.timestamp + MAX_DELAY
        ) {
            revert TimestampNotInRangeError(block.timestamp, _timestamp);
        }
        // 4. queue the txn
        queued[txId] = true;

        emit Queue(txId, _target, _value, _func, _data, _timestamp);
        
    }

    function execute(
        address _target,
        uint _value,
        string calldata _func,
        bytes calldata _data,
        uint _timestamp
    ) external payable onlyOwner returns (bytes memory) {
        bytes32 txId = getTxId( _target, _value, _func, _data, _timestamp);
        if (!queued[txId]) {
            revert NotQueuedError(txId);
        }
        // ----|-------------------|-------
        //  timestamp    timestamp + grace period
        if (block.timestamp < _timestamp) {
            revert TimestampNotPassedError(block.timestamp, _timestamp);
        }
        if (block.timestamp > _timestamp + GRACE_PERIOD) {
            revert TimestampExpiredError(block.timestamp, _timestamp + GRACE_PERIOD);
        }
        queued[txId] = false;
        // prepare data
        bytes memory data;
        if (bytes(_func).length > 0) {
            // data = func selector + _data
            data = abi.encodePacked(bytes4(keccak256(bytes(_func))), _data);
        } else {
            data = _data;
        }
        (bool ok, bytes memory res) = _target.call{value: _value}(data);
        if (!ok) {
            revert TxFailedError();
        }   

        emit Execute(txId, _target, _value, _func, _data, _timestamp);
        return res; 
    }

    function cancel(bytes32 _txId) external onlyOwner {
        if (!queued[_txId]) {
            revert NotQueuedError(_txId);
        }

        queued[_txId] = false;

        emit Cancel(_txId);
    }

}

contract TestTimeLock {
    address public timeLock;

    constructor(address _timeLock) {
        timeLock = _timeLock;
    }
    // this function can only be executed by timelock contract
    function test() external view {
        require(msg.sender == timeLock);
        // more code
    }
}