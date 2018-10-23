/*
* Copyright (c) 2018, Phuwanai Thummavet (serial-coder). All rights reserved.
* Github: https://github.com/serial-coder
* Contact us: mr[dot]thummavet[at]gmail[dot]com
*/

pragma solidity ^0.4.23;

import "./SafeMath.sol";
import "./BasicStringUtils.sol";
import "./Owned.sol";


// ------------------------------------------------------------------------
// Interface for exporting external functions of PizzaCoinStaff contract
// ------------------------------------------------------------------------
interface IStaffContract {
    function lockRegistration() external;
    function startVoting() external;
    function stopVoting() external;
    function getTotalSupply() external view returns (uint256 _totalSupply);
    function isStaff(address _user) external view returns (bool _bStaff);
    function getStaffName(address _staff) external view returns (string _name);
    function registerStaff(address _staff, string _staffName) external;
    function kickStaff(address _staff) external;
    function getTotalStaffs() external view returns (uint256 _total);
    function getStaffInfoAtIndex(uint256 _staffIndex) 
        external view
        returns (
            bool _endOfList,
            address _staff,
            string _name,
            uint256 _tokenBalance
        );
    function getTotalTeamsVotedByStaff(address _staff) external view returns (uint256 _total);
    function getVotingResultByStaffAtIndex(address _staff, uint256 _votingIndex) 
        external view
        returns (
            bool _endOfList,
            string _team,
            uint256 _voteWeight
        );
    function getTokenBalance(address _staff) external view returns (uint256 _tokenBalance);
    function commitToVote(address _staff, string _teamName, uint256 _votingWeight) external;
}


// ----------------------------------------------------------------------------
// Pizza Coin Staff Contract
// ----------------------------------------------------------------------------
contract PizzaCoinStaff is IStaffContract, Owned {
    /*
    * Owner of the contract is PizzaCoin contract, 
    * not a project deployer who is PizzaCoin owner
    *
    * Let staffs[0] denote a project deployer (i.e., PizzaCoin owner)
    */

    using SafeMath for uint256;
    using BasicStringUtils for string;


    struct StaffInfo {
        // This is used to reduce potential gas cost consumption when kicking a staff
        uint256 index;  // A pointing index to a particular staff on the 'staffs' array

        string name;
        bool wasRegistered;    // Check if a specific staff is being registered
        uint256 tokenBalance;  // Amount of tokens left for voting
        string[] teamsVoted;   // A collection of teams voted by this staff
        
        // mapping(team => votingWeight)
        mapping(string => uint256) votesWeight;  // Teams with voting weight approved by this staff
    }

    address[] private staffs;                          // staffs[0] denotes a project deployer (i.e., PizzaCoin owner)
    mapping(address => StaffInfo) private staffsInfo;  // mapping(staff => StaffInfo)

    uint256 private voterInitialTokens;
    uint256 private totalSupply;

    enum State { Registration, RegistrationLocked, Voting, VotingFinished }
    State private state = State.Registration;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor(uint256 _voterInitialTokens) public {
        require(
            _voterInitialTokens > 0,
            "'_voterInitialTokens' must be larger than 0."
        );

        voterInitialTokens = _voterInitialTokens;
    }

    // ------------------------------------------------------------------------
    // Don't accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
        revert("We don't accept ETH.");
    }

    // ------------------------------------------------------------------------
    // Guarantee that msg.sender must be a contract deployer (i.e., PizzaCoin address)
    // ------------------------------------------------------------------------
    modifier onlyPizzaCoin {
        // owner == PizzaCoin address
        require(
            msg.sender == owner,
            "This address is not PizzaCoin contract"
        );
        _;
    }

    // ------------------------------------------------------------------------
    // Guarantee that the present state is Registration
    // ------------------------------------------------------------------------
    modifier onlyRegistrationState {
        require(
            state == State.Registration,
            "The present state is not Registration."
        );
        _;
    }

    // ------------------------------------------------------------------------
    // Guarantee that the present state is RegistrationLocked
    // ------------------------------------------------------------------------
    modifier onlyRegistrationLockedState {
        require(
            state == State.RegistrationLocked,
            "The present state is not RegistrationLocked."
        );
        _;
    }

    // ------------------------------------------------------------------------
    // Guarantee that the present state is Voting
    // ------------------------------------------------------------------------
    modifier onlyVotingState {
        require(
            state == State.Voting,
            "The present state is not Voting."
        );
        _;
    }

    // ------------------------------------------------------------------------
    // Guarantee that the present state is VotingFinished
    // ------------------------------------------------------------------------
    modifier onlyVotingFinishedState {
        require(
            state == State.VotingFinished,
            "The present state is not VotingFinished."
        );
        _;
    }

    // ------------------------------------------------------------------------
    // Allow a staff freeze Registration state and transfer the state to RegistrationLocked
    // ------------------------------------------------------------------------
    function lockRegistration() external onlyRegistrationState onlyPizzaCoin {
        state = State.RegistrationLocked;
    }

    // ------------------------------------------------------------------------
    // Allow a staff transfer a state from RegistrationLocked to Voting
    // ------------------------------------------------------------------------
    function startVoting() external onlyRegistrationLockedState onlyPizzaCoin {
        state = State.Voting;
    }

    // ------------------------------------------------------------------------
    // Allow a staff transfer a state from Voting to VotingFinished
    // ------------------------------------------------------------------------
    function stopVoting() external onlyVotingState onlyPizzaCoin {
        state = State.VotingFinished;
    }

    // ------------------------------------------------------------------------
    // Get a total supply
    // ------------------------------------------------------------------------
    function getTotalSupply() external view returns (uint256 _totalSupply) {
        return totalSupply;
    }

    // ------------------------------------------------------------------------
    // Determine if _user is a project deployer (i.e., PizzaCoin owner) or not
    // ------------------------------------------------------------------------
    function isProjectDeployer(address _user) internal view returns (bool _bDeployer) {
        /*
        * Owner of the contract is PizzaCoin contract, 
        * not a project deployer who is PizzaCoin owner
        *
        * Let staffs[0] denote a project deployer (i.e., PizzaCoin owner)
        */

        assert(_user != address(0));
        return staffs[0] == _user;
    }

    // ------------------------------------------------------------------------
    // Determine if _user is a staff or not (external)
    // ------------------------------------------------------------------------
    function isStaff(address _user) external view returns (bool _bStaff) {
        return __isStaff(_user);
    }

    // ------------------------------------------------------------------------
    // Determine if _user is a staff or not (internal)
    // ------------------------------------------------------------------------
    function __isStaff(address _user) internal view returns (bool _bStaff) {
        require(
            _user != address(0),
            "'_user' contains an invalid address."
        );

        return staffsInfo[_user].wasRegistered;
    }

    // ------------------------------------------------------------------------
    // Get a staff name
    // ------------------------------------------------------------------------
    function getStaffName(address _staff) external view returns (string _name) {
        require(
            _staff != address(0),
            "'_staff' contains an invalid address."
        );

        require(
            __isStaff(_staff),
            "Cannot find the specified staff."
        );

        return staffsInfo[_staff].name;
    }

    // ------------------------------------------------------------------------
    // Register a new staff
    // ------------------------------------------------------------------------
    function registerStaff(address _staff, string _staffName) external onlyRegistrationState onlyPizzaCoin {
        require(
            _staff != address(0),
            "'_staff' contains an invalid address."
        );

        require(
            _staffName.isNotEmpty(),
            "'_staffName' might not be empty."
        );

        require(
            staffsInfo[_staff].wasRegistered == false,
            "The specified staff was registered already."
        );

        // Register a new staff
        staffs.push(_staff);
        staffsInfo[_staff] = StaffInfo({
            wasRegistered: true,
            name: _staffName,
            tokenBalance: voterInitialTokens,
            teamsVoted: new string[](0),
            /*
                Omit 'votesWeight'
            */
            index: staffs.length - 1
        });

        totalSupply = totalSupply.add(voterInitialTokens);
    }

    // ------------------------------------------------------------------------
    // Remove a specific staff
    // ------------------------------------------------------------------------
    function kickStaff(address _staff) external onlyRegistrationState onlyPizzaCoin {
        require(
            _staff != address(0),
            "'_staff' contains an invalid address."
        );

        require(
            staffsInfo[_staff].wasRegistered,
            "Cannot find the specified staff."
        );

        require(
            isProjectDeployer(_staff) == false,
            "Project deployer is not kickable."
        );

        uint256 staffIndex = getStaffIndex(_staff);

        // Remove the specified staff from an array by moving 
        // the last array element to the element pointed by staffIndex
        staffs[staffIndex] = staffs[staffs.length - 1];

        // Since we have just moved the last array element to 
        // the element pointed by staffIndex, we have to update 
        // the newly moved staff's index to staffIndex too
        staffsInfo[staffs[staffIndex]].index = staffIndex;

        // Remove the last element
        staffs.length--;

        // Remove the specified staff from a mapping
        delete staffsInfo[_staff];

        totalSupply = totalSupply.sub(voterInitialTokens);
    }

    // ------------------------------------------------------------------------
    // Get an index pointing to the specified staff on the array 'staffs'
    // ------------------------------------------------------------------------
    function getStaffIndex(address _staff) internal view returns (uint256 _staffIndex) {
        assert(_staff != address(0));
        assert(staffsInfo[_staff].wasRegistered);
        return staffsInfo[_staff].index;
    }

    // ------------------------------------------------------------------------
    // Get a total number of staffs
    // ------------------------------------------------------------------------
    function getTotalStaffs() external view returns (uint256 _total) {
        return staffs.length;
    }

    // ------------------------------------------------------------------------
    // Get a staff info at the specified index '_staffIndex'
    // ------------------------------------------------------------------------
    function getStaffInfoAtIndex(uint256 _staffIndex) 
        external view
        returns (
            bool _endOfList,
            address _staff,
            string _name,
            uint256 _tokenBalance
        ) 
    {
        if (_staffIndex >= staffs.length) {
            _endOfList = true;
            _staff = address(0);
            _name = "";
            _tokenBalance = 0;
            return;
        }

        address staff = staffs[_staffIndex];
        _endOfList = false;
        _staff = staff;
        _name = staffsInfo[staff].name;
        _tokenBalance = staffsInfo[staff].tokenBalance;
    }

    // ------------------------------------------------------------------------
    // Get a total number of teams voted by the specified staff
    // ------------------------------------------------------------------------
    function getTotalTeamsVotedByStaff(address _staff) external view returns (uint256 _total) {
        require(
            _staff != address(0),
            "'_staff' contains an invalid address."
        );

        require(
            staffsInfo[_staff].wasRegistered,
            "Cannot find the specified staff."
        );

        return staffsInfo[_staff].teamsVoted.length;
    }

    // ------------------------------------------------------------------------
    // Get a voting result to a team pointed by _votingIndex committed by the specified staff
    // ------------------------------------------------------------------------
    function getVotingResultByStaffAtIndex(address _staff, uint256 _votingIndex) 
        external view
        returns (
            bool _endOfList,
            string _team,
            uint256 _voteWeight
        ) 
    {
        require(
            _staff != address(0),
            "'_staff' contains an invalid address."
        );

        require(
            staffsInfo[_staff].wasRegistered,
            "Cannot find the specified staff."
        );

        if (_votingIndex >= staffsInfo[_staff].teamsVoted.length) {
            _endOfList = true;
            _team = "";
            _voteWeight = 0;
            return;
        }

        _endOfList = false;
        _team = staffsInfo[_staff].teamsVoted[_votingIndex];
        _voteWeight = staffsInfo[_staff].votesWeight[_team];
    }

    // ------------------------------------------------------------------------
    // Get a token balance of the specified staff
    // ------------------------------------------------------------------------
    function getTokenBalance(address _staff) external view returns (uint256 _tokenBalance) {
        require(
            _staff != address(0),
            "'_staff' contains an invalid address."
        );

        require(
            staffsInfo[_staff].wasRegistered,
            "Cannot find the specified staff."
        );

        return staffsInfo[_staff].tokenBalance;
    }

    // ------------------------------------------------------------------------
    // Allow a staff give a vote to the specified team
    // ------------------------------------------------------------------------
    function commitToVote(address _staff, string _teamName, uint256 _votingWeight) 
        external onlyVotingState onlyPizzaCoin 
    {
        require(
            _staff != address(0),
            "'_staff' contains an invalid address."
        );

        require(
            _teamName.isNotEmpty(),
            "'_teamName' might not be empty."
        );

        require(
            _votingWeight > 0,
            "'_votingWeight' must be larger than 0."
        );

        require(
            staffsInfo[_staff].wasRegistered,
            "Cannot find the specified staff."
        );

        require(
            _votingWeight <= staffsInfo[_staff].tokenBalance,
            "Insufficient voting balance."
        );

        staffsInfo[_staff].tokenBalance = staffsInfo[_staff].tokenBalance.sub(_votingWeight);

        // If staffsInfo[_staff].votesWeight[_teamName] > 0 is true, this implies that 
        // the staff used to give a vote to the specified team previously
        if (staffsInfo[_staff].votesWeight[_teamName] == 0) {
            // The staff has never given a vote to the specified team before
            // We, therefore, have to add a new team to the 'teamsVoted' array
            staffsInfo[_staff].teamsVoted.push(_teamName);
        }

        staffsInfo[_staff].votesWeight[_teamName] = staffsInfo[_staff].votesWeight[_teamName].add(_votingWeight);
    }
}