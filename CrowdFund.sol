// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// User creates a campaign.
// Users can pledge, transferring their token to a campaign.
// After the campaign ends, campaign creator can claim the funds if total amount pledged is more than the campaign goal.
// Otherwise, campaign did not reach it's goal, users can withdraw their pledge.


interface IERC20 {
    function transfer(address, uint) external returns (bool);

    function transferFrom(
        address,
        address,
        uint
    ) external returns (bool);
}

contract CrowdFund {
    event Launch(uint id, address indexed creator, uint goal, uint32 startAt, uint32 endAt);
    event Cancel(uint _id);
    event Pledge(address indexed pledger, uint indexed id, uint amount);
    event Unpledge(uint indexed id, address indexed caller, uint amount);
    event Claim(uint id);
    event Refund(uint id, address indexed caller, uint amount);

    struct Campaign {
        // Creator of campaign
        address creator;
        // Amount of tokens to raise
        uint goal;
        // Total amount pledged
        uint pledged;
        // Timestamp of start of campaign
        uint32 startAt;
        // Timestamp of end of campaign
        uint32 endAt;
        // True if goal was reached and creator has claimed the tokens.
        bool claimed;
    }

    IERC20 public immutable token;
    // Total count of campaigns created.
    // It is also used to generate id for new campaigns.
    uint public count;   
    // Mapping from id to Campaign
    mapping(uint => Campaign) public campaigns;
    // Mapping from campaign id => pledger => amount pledged, to let the user know how much they pledged in which campaign
    mapping(uint => mapping(address => uint)) public pledgedAmount;   

    constructor(address _token) {
        token = IERC20(_token);
    }

    function launch(
        uint _goal,
        uint32 _startAt,
        uint32 _endAt
    ) external {
        require(_startAt >= block.timestamp, "start at must be greater than current time");
        require(_endAt >= _startAt, "End at must be graeter than Start at");
        require(_endAt >= block.timestamp + 90 days, "Maximun duratiion of campaign is 90 days");
        count++;
        campaigns[count] = Campaign(msg.sender, _goal, 0, _startAt, _endAt, false);

        emit Launch(count, msg.sender, _goal, _startAt, _endAt);
        
    }


    // ONLY CRAETOR SHOULD BE ABLE TO CALL IT WHEN CAMPAIGN IS NOT STARTED YET
    function cancel(uint _id) external {
        Campaign memory campaign = campaigns[_id];
        require(msg.sender == campaign.creator, "You are not craetor of this campaign");
        require(block.timestamp < campaign.startAt, "Campaign already started");

        delete campaigns[_id];
        emit Cancel(_id);
    }

    function pledge(uint _id, uint _amount) external {
        Campaign storage campaign = campaigns[_id];
        require(campaign.startAt <= block.timestamp, "not started");
        require(block.timestamp <= campaign.endAt, "ended");

        campaign.pledged += _amount;
        pledgedAmount[_id][msg.sender] += _amount;
        token.transferFrom(msg.sender, address(this), _amount);
        emit Pledge(msg.sender, _id, _amount);
    }

    function unpledge(uint _id, uint _amount) external {
        Campaign storage campaign = campaigns[_id];
        require(pledgedAmount[_id][msg.sender] >= _amount, "Not pledged");
        require(block.timestamp <= campaign.endAt, "ended");

        campaign.pledged -= _amount;
        pledgedAmount[_id][msg.sender] -= _amount;
        token.transferFrom(address(this), msg.sender, _amount);
        emit Unpledge(_id, msg.sender, _amount);

    }

    function claim(uint _id) external {
        Campaign storage campaign = campaigns[_id];
        require(msg.sender == campaign.creator, "Not craetor");
        require(campaign.pledged >= campaign.goal, "goal not reached");
        require(campaign.endAt < block. timestamp, "not ended");
        require(!campaign.claimed, "Already claimed");
        campaign.claimed = true;
        token.transfer(msg.sender, campaign.pledged);
        emit Claim(_id);

    }
    // In case the campaign is unsucessful and didn't reach it's goal, then refund
    function refund(uint _id) external {
        Campaign storage campaign = campaigns[_id];
        require(campaign.endAt < block. timestamp, "not ended");
        require(!campaign.claimed, "Already claimed");
        require(campaign.pledged < campaign.goal, "goal not reached");

        uint bal = pledgedAmount[_id][msg.sender];
        pledgedAmount[_id][msg.sender] = 0;
        token.transfer(msg.sender, bal);

        emit Refund(_id, msg.sender, bal);


    }

}