// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract CrowdFunding {
    mapping(address => uint) public contributors;
    address public admin;
    uint public numberOfContributors;
    uint public minimumContribution;
    uint public deadline; // timestamp
    uint public goal;
    uint public raisedAmount;
    struct Request {
        string description;
        address payable recipient;
        uint value;
        uint numberOfVoters;
        bool complete;
        mapping(address => bool) voters;
    }
    
    mapping(uint => Request) public requests;
    uint public numberOfRequests;
    
    constructor(uint _goal, uint _deadline) {
        goal = _goal;
        deadline = block.timestamp + _deadline;
        minimumContribution = 100 wei;
        admin = msg.sender;
    }
    
    event ContributeEvent(address _sender, uint _value);
    event CreateRequestEvent(string _description, address _recipient, uint _value);
    event FinalizeRequestEvent(address _recipient, uint _value);
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function!");
        _;
    }
    
    function contribute() public payable {
        require(block.timestamp < deadline, "Deadline has passed!");
        require(msg.value > minimumContribution, "Minimum contribution is not met");
        
        if (contributors[msg.sender] == 0) {
            numberOfContributors++;
        }
        
        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;
        
        emit ContributeEvent(msg.sender, msg.value);
    }
    
    receive() payable external {
        contribute();
    }
    
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    function getRefund() public payable {
        require(block.timestamp > deadline && raisedAmount < goal);
        require(contributors[msg.sender] > 0);
        
        address payable recipient = payable(msg.sender);
        uint value = contributors[msg.sender];
        
        recipient.transfer(value);
        contributors[msg.sender] = 0;
    }
    
    function createRequest(
        string memory _description,
        address payable _recipient, 
        uint _value) public onlyAdmin {
            Request storage newRequest = requests[numberOfRequests++];
            newRequest.description = _description;
            newRequest.recipient = _recipient;
            newRequest.value = _value;
            newRequest.complete = false;
            newRequest.numberOfVoters = 0;
            
            emit CreateRequestEvent(_description, _recipient, _value);
    }
    
    function voteRequest(uint _requestNumber) public {
        require(contributors[msg.sender] > 0, "You must be a contributor");
        Request storage request = requests[_requestNumber];
        
        require(!request.voters[msg.sender], "You have already voted");

        request.numberOfVoters++;
        request.voters[msg.sender] = true;
    }
    
    function finalizeRequest(uint _requestNumber) public payable onlyAdmin {
        require(raisedAmount >= goal);
        Request storage request = requests[_requestNumber];
        
        require(!request.complete, "The request has been completed");
        require(request.numberOfVoters > numberOfContributors / 2);
        
        request.complete = true;
        request.recipient.transfer(request.value);
        
        emit FinalizeRequestEvent(request.recipient, request.value);
    }
    
}