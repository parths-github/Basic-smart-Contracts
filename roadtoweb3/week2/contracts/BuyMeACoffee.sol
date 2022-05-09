//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract BuyMeACoffee {
    // Evevnt to emit ehen a memo is created
    event NewMemo(
        address indexed from,
        uint256 timestamp,
        string name,
        string message
    );


    // Memo struct
    struct Memo {
        address from;
        uint256 timestamp;
        string name;
        string message;
    }
    // address of contarct deployer
    address payable owner;

    // Keep track of allowed address to withdraw
    mapping(address => bool) public isAllowed;

    // List of all memo received from friend
    Memo[] memos;

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyAllowed(address _allowed) {
        require(isAllowed[_allowed], "Not allowed to withdraw");
        _;
    }


    /**
     * @dev buy a coffee for contract owner
     * @param _name - name of coffee buyer
     * @param _message nice msg from coffee buyer
     */
    function buyCoffee(string memory _name, string memory _message) public payable {
        require(msg.value > 0, "Can't buycoffe with 0 eth");
        // add memo to storage
        memos.push(Memo(msg.sender, block.timestamp, _name, _message));
        emit NewMemo(msg.sender, block.timestamp, _name, _message);
    }

    /**
     * @dev transfer entire balnce of this contarct to owner of contract
     */
    function withdrawTips() public onlyAllowed(msg.sender) {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "withdraw failed");
    }

    /**
     * @dev only owner is able to call this function and can allow someone else to withdraw
     */
    function allowWithdrawing(address _allowed) public {
        require(msg.sender == owner, "You are not the owner of contrcat");
        isAllowed[_allowed] = true;
    }


    /**
     * @dev retrieve all the memos received and stored on the blockchain
     */
    function getMemos() public view returns (Memo[] memory) {
        return memos;
    }
}
