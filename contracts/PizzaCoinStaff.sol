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
    function isStaff(address _user) external view returns (bool bStaff);
    function getStaffName(address _staff) external view returns (string _name);
    function registerStaff(address _staff, string _staffName) external;
    function kickStaff(address _staff) external;
    function getTotalStaffs() external view returns (uint256 _total);
    function getFirstFoundStaffInfo(uint256 _startSearchingIndex) 
        external view
        returns (
            bool _endOfList, 
            uint256 _nextStartSearchingIndex,
            address _staff,
            string _name,
            uint256 _tokensBalance
        );
    function getTotalVotesByStaff(address _staff) external view returns (uint256 _total);
    function getVoteResultAtIndexByStaff(address _staff, uint256 _votingIndex) 
        external view
        returns (
            bool _endOfList,
            string _team,
            uint256 _voteWeight
        );
    function getTokenBalance(address _staff) external view returns (uint256 _tokenBalance);
    function commitToVote(address _staff, uint256 _votingWeight, string _teamName) external;
}


// ----------------------------------------------------------------------------
// Pizza Coin Staff Contract
// ----------------------------------------------------------------------------
contract PizzaCoinStaff is IStaffContract, Owned {
    /*
    * Owner of the contract is PizzaCoin contract, 
    * not a project deployer (or PizzaCoin's owner)
    *
    * Let staffs[0] denote a project deployer (i.e., PizzaCoin's owner)
    */

    using SafeMath for uint256;
    using BasicStringUtils for string;


    struct StaffInfo {
        bool wasRegistered;    // Check if a specific staff is being registered
        string name;
        uint256 tokensBalance; // Amount of tokens left for voting
        string[] teamsVoted;   // Record all the teams voted by this staff
        
        // mapping(team => votes)
        mapping(string => uint256) votesWeight;  // A collection of teams with voting weight approved by this staff
    }

    address[] private staffs;                          // The first staff is the contract owner
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
        require(msg.sender == owner);  // owner == PizzaCoin address
        _;
    }

    // ------------------------------------------------------------------------
    // Guarantee that msg.sender must be a staff
    // ------------------------------------------------------------------------
    modifier onlyStaff {
        require(
            staffsInfo[msg.sender].wasRegistered == true || msg.sender == owner,
            "This address is not a staff."
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
    // Determine if _user is a project deployer (i.e., PizzaCoin's owner) or not
    // ------------------------------------------------------------------------
    function isProjectDeployer(address _user) internal view onlyPizzaCoin returns (bool bDeployer) {
        /*
        * Owner of the contract is PizzaCoin contract, 
        * not a project deployer (or PizzaCoin's owner)
        *
        * Let staffs[0] denote a project deployer (i.e., PizzaCoin's owner)
        */

        assert(_user != address(0));

        address deployer = staffs[0];
        return deployer == _user && staffsInfo[deployer].wasRegistered == true;
    }

    // ------------------------------------------------------------------------
    // Determine if _user is a staff or not (external)
    // ------------------------------------------------------------------------
    function isStaff(address _user) external view returns (bool bStaff) {
        return __isStaff(_user);
    }

    // ------------------------------------------------------------------------
    // Determine if _user is a staff or not (internal)
    // ------------------------------------------------------------------------
    function __isStaff(address _user) internal view returns (bool bStaff) {
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
            __isStaff(_staff) == true,
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
            _staffName.isEmpty() == false,
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
            tokensBalance: voterInitialTokens,
            teamsVoted: new string[](0)
            /*
                Omit 'votesWeight'
            */
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
            staffsInfo[_staff].wasRegistered == true,
            "Cannot find the specified staff."
        );

        require(
            isProjectDeployer(_staff) == false,
            "Project deployer is not kickable."
        );

        bool found;
        uint staffIndex;

        (found, staffIndex) = getStaffIndex(_staff);
        if (!found) {
            revert("Cannot find the specified staff.");
        }

        // Reset an element to 0 but the array length never decrease (beware!!)
        delete staffs[staffIndex];

        // Remove a specified staff from a mapping
        delete staffsInfo[_staff];

        totalSupply = totalSupply.sub(voterInitialTokens);
    }

    // ------------------------------------------------------------------------
    // Get the index of a specific staff found in the array 'staffs'
    // ------------------------------------------------------------------------
    function getStaffIndex(address _staff) internal view onlyPizzaCoin returns (bool _found, uint256 _staffIndex) {
        assert(_staff != address(0));

        _found = false;
        _staffIndex = 0;

        for (uint256 i = 0; i < staffs.length; i++) {
            if (staffs[i] == _staff) {
                _found = true;
                _staffIndex = i;
                return;
            }
        }
    }

    // ------------------------------------------------------------------------
    // Get a total number of staffs
    // ------------------------------------------------------------------------
    function getTotalStaffs() external view returns (uint256 _total) {
        _total = 0;
        for (uint256 i = 0; i < staffs.length; i++) {
            // Staff was not removed before
            if (staffs[i] != address(0) && staffsInfo[staffs[i]].wasRegistered == true) {
                _total++;
            }
        }
    }

    // ------------------------------------------------------------------------
    // Get an info of the first found staff 
    // (start searching at _startSearchingIndex)
    // ------------------------------------------------------------------------
    function getFirstFoundStaffInfo(uint256 _startSearchingIndex) 
        external view
        returns (
            bool _endOfList, 
            uint256 _nextStartSearchingIndex,
            address _staff,
            string _name,
            uint256 _tokensBalance
        ) 
    {
        _endOfList = true;
        _nextStartSearchingIndex = staffs.length;
        _staff = address(0);
        _name = "";
        _tokensBalance = 0;

        if (_startSearchingIndex >= staffs.length) {
            return;
        }

        for (uint256 i = _startSearchingIndex; i < staffs.length; i++) {
            address staff = staffs[i];

            // Staff was not removed before
            if (staff != address(0) && staffsInfo[staff].wasRegistered == true) {
                _endOfList = false;
                _nextStartSearchingIndex = i + 1;
                _staff = staff;
                _name = staffsInfo[staff].name;
                _tokensBalance = staffsInfo[staff].tokensBalance;
                return;
            }
        }
    }

    // ------------------------------------------------------------------------
    // Get a total number of the votes ('teamsVoted' array) made by the specified staff
    // ------------------------------------------------------------------------
    function getTotalVotesByStaff(address _staff) external view returns (uint256 _total) {
        require(
            _staff != address(0),
            "'_staff' contains an invalid address."
        );

        require(
            staffsInfo[_staff].wasRegistered == true,
            "Cannot find the specified staff."
        );

        return staffsInfo[_staff].teamsVoted.length;
    }

    // ------------------------------------------------------------------------
    // Get a team voting result (at the index of 'teamsVoted' array) made by the specified staff
    // ------------------------------------------------------------------------
    function getVoteResultAtIndexByStaff(address _staff, uint256 _votingIndex) 
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
            staffsInfo[_staff].wasRegistered == true,
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
            staffsInfo[_staff].wasRegistered == true,
            "Cannot find the specified staff."
        );

        return staffsInfo[_staff].tokensBalance;
    }

    // ------------------------------------------------------------------------
    // Allow a staff to give a vote to the specified team
    // ------------------------------------------------------------------------
    function commitToVote(address _staff, uint256 _votingWeight, string _teamName) external onlyVotingState onlyPizzaCoin {
        require(
            _staff != address(0),
            "'_staff' contains an invalid address."
        );

        require(
            _votingWeight > 0,
            "'_votingWeight' must be larger than 0."
        );

        require(
            _teamName.isEmpty() == false,
            "'_teamName' might not be empty."
        );

        require(
            staffsInfo[_staff].wasRegistered == true,
            "Cannot find the specified staff."
        );

        require(
            _votingWeight <= staffsInfo[_staff].tokensBalance,
            "Insufficient voting balance."
        );

        staffsInfo[_staff].tokensBalance = staffsInfo[_staff].tokensBalance.sub(_votingWeight);

        // If staffsInfo[_staff].votesWeight[_teamName] > 0 is true, this implies that 
        // the staff was used to give a vote to the specified team previously
        if (staffsInfo[_staff].votesWeight[_teamName] == 0) {
            // The staff has never been given a vote to the specified team before
            // We, therefore, have to add a new team to the 'teamsVoted' array
            staffsInfo[_staff].teamsVoted.push(_teamName);
        }

        staffsInfo[_staff].votesWeight[_teamName] = staffsInfo[_staff].votesWeight[_teamName].add(_votingWeight);
    }
}