/*
* Copyright (c) 2018, Phuwanai Thummavet (serial-coder). All rights reserved.
* Github: https://github.com/serial-coder
* Contact us: mr[dot]thummavet[at]gmail[dot]com
*/

pragma solidity ^0.4.23;

import "./ERC20.sol";
import "./BasicStringUtils.sol";
import "./Owned.sol";
import "./PizzaCoinStaff.sol";
import "./PizzaCoinPlayer.sol";
import "./PizzaCoinTeam.sol";
import "./PizzaCoinStaffDeployer.sol";
import "./PizzaCoinPlayerDeployer.sol";
import "./PizzaCoinTeamDeployer.sol";
import "./PizzaCoinCodeLib.sol";
import "./PizzaCoinCodeLib2.sol";


// ----------------------------------------------------------------------------
// Pizza Coin Contract
// ----------------------------------------------------------------------------
contract PizzaCoin is ERC20, Owned {
    using BasicStringUtils for string;


    // Contract events (the 'indexed' keyword cannot be used with any string parameter)
    event StateChanged();
    event ChildContractCreated(address indexed _contract);
    event StaffRegistered();
    event StaffKicked();
    event PlayerRegistered();
    event TeamCreated();
    event PlayerKicked();
    event FirstFoundPlayerInTeamKicked(uint256 _nextStartSearchingIndex);
    event TeamKicked();
    event TeamVoted();


    // Token info
    string public constant symbol = "PZC";
    string public constant name = "Pizza Coin";
    uint8 public constant decimals = 0;

    string private ownerName;
    uint256 private voterInitialTokens;

    address private staffContract;
    address private playerContract;
    address private teamContract;

    enum State { Initial, Registration, RegistrationLocked, Voting, VotingFinished }
    State private state = State.Initial;

    // mapping(keccak256(state) => stateInString)
    mapping(bytes32 => string) private stateMap;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor(string _ownerName, uint256 _voterInitialTokens) public {

        require(
            _ownerName.isEmpty() == false,
            "'_ownerName' might not be empty."
        );

        require(
            _voterInitialTokens > 0,
            "'_voterInitialTokens' must be larger than 0."
        );

        initStateMap();

        ownerName = _ownerName;
        voterInitialTokens = _voterInitialTokens;

        emit StateChanged();
    }

    // ------------------------------------------------------------------------
    // Don't accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
        revert("We don't accept ETH.");
    }

    // ------------------------------------------------------------------------
    // Guarantee that msg.sender has not been registered before
    // ------------------------------------------------------------------------
    modifier notRegistered(address _user) {
        require(
            PizzaCoinCodeLib2.isStaff(_user, staffContract) == false && 
            PizzaCoinCodeLib2.isPlayer(_user, playerContract) == false,
            "This address was registered already."
        );
        _;
    }

    // ------------------------------------------------------------------------
    // Guarantee that msg.sender has been already registered
    // ------------------------------------------------------------------------
    modifier onlyRegistered {
        require(
            PizzaCoinCodeLib2.isStaff(msg.sender, staffContract) == true ||
            PizzaCoinCodeLib2.isPlayer(msg.sender, playerContract) == true,
            "This address was not being registered."
        );
        _;
    }

    // ------------------------------------------------------------------------
    // Guarantee that msg.sender must be a staff
    // ------------------------------------------------------------------------
    modifier onlyStaff {
        require(
            PizzaCoinCodeLib2.isStaff(msg.sender, staffContract) == true || msg.sender == owner,
            "This address is not a staff."
        );
        _;
    }

    // ------------------------------------------------------------------------
    // Guarantee that the present state is Initial
    // ------------------------------------------------------------------------
    modifier onlyInitialState {
        require(
            state == State.Initial,
            "The present state is not Initial."
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
    // Initial a state mapping
    // ------------------------------------------------------------------------
    function initStateMap() internal onlyInitialState onlyOwner {
        stateMap[keccak256(State.Initial)] = "Initial";
        stateMap[keccak256(State.Registration)] = "Registration";
        stateMap[keccak256(State.RegistrationLocked)] = "Registration Locked";
        stateMap[keccak256(State.Voting)] = "Voting";
        stateMap[keccak256(State.VotingFinished)] = "Voting Finished";
    }

    // ------------------------------------------------------------------------
    // Get a contract state in String format
    // ------------------------------------------------------------------------
    function getContractState() public view returns (string _state) {
        return stateMap[keccak256(state)];
    }

    // ------------------------------------------------------------------------
    // Allow a staff transfer the state from Initial to Registration
    // ------------------------------------------------------------------------
    function startRegistration() public onlyInitialState {
        address staff = msg.sender;

        // Allow only a staff transfer the state from Initial to Registration
        // Revert a transaction if the contract does not get initialized completely
        PizzaCoinCodeLib.isContractCompletelyInitialized(
            staff, staffContract, playerContract, teamContract
        );

        state = State.Registration;

        // The state of child contracts does not need to do transfer because 
        // their state was set to Registration state once they were created

        emit StateChanged();
    }

    // ------------------------------------------------------------------------
    // Allow a staff freeze Registration state and transfer the state to RegistrationLocked
    // ------------------------------------------------------------------------
    function lockRegistration() public onlyRegistrationState onlyStaff {
        state = State.RegistrationLocked;

        // Transfer the state of child contracts
        PizzaCoinCodeLib2.signalChildContractsToLockRegistration(staffContract, playerContract, teamContract);

        emit StateChanged();
    }

    // ------------------------------------------------------------------------
    // Allow a staff transfer a state from RegistrationLocked to Voting
    // ------------------------------------------------------------------------
    function startVoting() public onlyRegistrationLockedState onlyStaff {
        state = State.Voting;

        // Transfer the state of child contracts
        PizzaCoinCodeLib2.signalChildContractsToVoting(staffContract, playerContract, teamContract);

        emit StateChanged();
    }

    // ------------------------------------------------------------------------
    // Allow a staff transfer a state from Voting to VotingFinished
    // ------------------------------------------------------------------------
    function stopVoting() public onlyVotingState onlyStaff {
        state = State.VotingFinished;

        // Transfer the state of child contracts
        PizzaCoinCodeLib2.signalChildContractsToStopVoting(staffContract, playerContract, teamContract);

        emit StateChanged();
    }

    // ------------------------------------------------------------------------
    // Create a staff contract
    // ------------------------------------------------------------------------
    function createStaffContract() public onlyInitialState onlyOwner returns (address _contract) {
        require(
            staffContract == address(0),
            "The staff contract got initialized already."
        );

        // Create a staff contract
        staffContract = PizzaCoinStaffDeployer.deployContract(voterInitialTokens);

        // Register an owner as a staff. We cannot use calling to registerStaff() 
        // because the contract state is Initial.
        PizzaCoinCodeLib.registerStaff(owner, ownerName, staffContract);

        emit ChildContractCreated(staffContract);
        return staffContract;
    }

    // ------------------------------------------------------------------------
    // Register a new staff
    // ------------------------------------------------------------------------
    function registerStaff(address _newStaff, string _newStaffName) public onlyRegistrationState onlyStaff notRegistered(_newStaff) {
        PizzaCoinCodeLib.registerStaff(_newStaff, _newStaffName, staffContract);
        emit StaffRegistered();
    }

    // ------------------------------------------------------------------------
    // Remove a specific staff
    // ------------------------------------------------------------------------
    function kickStaff(address _staff) public onlyRegistrationState onlyOwner {
        PizzaCoinCodeLib.kickStaff(_staff, staffContract);
        emit StaffKicked();
    }

    // ------------------------------------------------------------------------
    // Create a player contract
    // ------------------------------------------------------------------------
    function createPlayerContract() public onlyInitialState onlyOwner returns (address _contract) {
        require(
            playerContract == address(0),
            "The player contract got initialized already."
        );

        // Create a player contract
        playerContract = PizzaCoinPlayerDeployer.deployContract(voterInitialTokens);

        emit ChildContractCreated(playerContract);
        return playerContract;
    }

    // ------------------------------------------------------------------------
    // Register a player
    // ------------------------------------------------------------------------
    function registerPlayer(string _playerName, string _teamName) public onlyRegistrationState notRegistered(msg.sender) {
        PizzaCoinCodeLib.registerPlayer(_playerName, _teamName, playerContract, teamContract);
        emit PlayerRegistered();
    }

    // ------------------------------------------------------------------------
    // Create a team contract
    // ------------------------------------------------------------------------
    function createTeamContract() public onlyInitialState onlyOwner returns (address _contract) {
        require(
            teamContract == address(0),
            "The team contract got initialized already."
        );

        // Create a team contract
        teamContract = PizzaCoinTeamDeployer.deployContract();

        emit ChildContractCreated(teamContract);
        return teamContract;
    }

    // ------------------------------------------------------------------------
    // Team leader creates a team
    // ------------------------------------------------------------------------
    function createTeam(string _teamName, string _creatorName) public onlyRegistrationState notRegistered(msg.sender) {
        PizzaCoinCodeLib.createTeam(_teamName, _creatorName, playerContract, teamContract);
        emit TeamCreated();
    }

    // ------------------------------------------------------------------------
    // Remove the first found player in a particular team 
    // (start searching at _startSearchingIndex)
    // ------------------------------------------------------------------------
    function kickFirstFoundPlayerInTeam(string _teamName, uint256 _startSearchingIndex) 
        public onlyRegistrationState onlyStaff returns (uint256 _nextStartSearchingIndex) {

        _nextStartSearchingIndex = PizzaCoinCodeLib.kickFirstFoundPlayerInTeam(
            _teamName, _startSearchingIndex, staffContract, playerContract, teamContract);

        emit PlayerKicked();
        emit FirstFoundPlayerInTeamKicked(_nextStartSearchingIndex);
    }

    // ------------------------------------------------------------------------
    // Remove a specific player from a particular team
    // ------------------------------------------------------------------------
    function kickPlayer(address _player, string _teamName) public onlyRegistrationState onlyStaff {
        PizzaCoinCodeLib.kickPlayer(_player, _teamName, staffContract, playerContract, teamContract);
        emit PlayerKicked();
    }

    // ------------------------------------------------------------------------
    // Remove a specific team (the team must be empty of players)
    // ------------------------------------------------------------------------
    function kickTeam(string _teamName) public onlyRegistrationState onlyStaff {
        PizzaCoinCodeLib.kickTeam(_teamName, staffContract, teamContract);
        emit TeamKicked();
    }

    // ------------------------------------------------------------------------
    // Allow any staff or any player in other different teams to vote to a team
    // ------------------------------------------------------------------------
    function voteTeam(string _teamName, uint256 _votingWeight) public onlyVotingState onlyRegistered {
        PizzaCoinCodeLib.voteTeam(_teamName, _votingWeight, staffContract, playerContract, teamContract);
        emit TeamVoted();
    }


    /*
    *
    * This contract partially complies with ERC token standard #20 interface.
    * That is, only the balanceOf() and totalSupply() will be used.
    *
    */

    // ------------------------------------------------------------------------
    // Standard function of ERC token standard #20
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint256 _totalSupply) {
        return PizzaCoinCodeLib2.totalSupply(staffContract, playerContract);
    }

    // ------------------------------------------------------------------------
    // Standard function of ERC token standard #20
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint256 balance) {
        return PizzaCoinCodeLib2.balanceOf(tokenOwner, staffContract, playerContract);
    }

    // ------------------------------------------------------------------------
    // Standard function of ERC token standard #20
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public view returns (uint256) {
        
        // This function is never used
        PizzaCoinCodeLib2.allowance(tokenOwner, spender);
    }

    // ------------------------------------------------------------------------
    // Standard function of ERC token standard #20
    // ------------------------------------------------------------------------
    function transfer(address to, uint256 tokens) public returns (bool) {

        // This function is never used
        PizzaCoinCodeLib2.transfer(to, tokens);
    }

    // ------------------------------------------------------------------------
    // Standard function of ERC token standard #20
    // ------------------------------------------------------------------------
    function approve(address spender, uint256 tokens) public returns (bool) {
        
        // This function is never used
        PizzaCoinCodeLib2.approve(spender, tokens);
    }

    // ------------------------------------------------------------------------
    // Standard function of ERC token standard #20
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint256 tokens) public returns (bool) {
        
        // This function is never used
        PizzaCoinCodeLib2.transferFrom(from, to, tokens);
    }
}