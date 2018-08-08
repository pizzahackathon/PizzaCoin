/*
* Copyright (c) 2018, Phuwanai Thummavet (serial-coder). All rights reserved.
* Github: https://github.com/serial-coder
* Contact us: mr[dot]thummavet[at]gmail[dot]com
*/

pragma solidity ^0.4.23;

import "./SafeMath.sol";

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public view returns (uint256 _totalSupply);
    function balanceOf(address tokenOwner) public view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

// ----------------------------------------------------------------------------
// Basic String Utils Library - just a lazy and expensive comparison
// ----------------------------------------------------------------------------
library BasicStringUtils {

    // ------------------------------------------------------------------------
    // Determine if two strings are equal or not
    // ------------------------------------------------------------------------
    function isEqual(string self, string other) internal pure returns (bool bEqual) {
        return keccak256(self) == keccak256(other);
    }

    // ------------------------------------------------------------------------
    // Determine if the string is empty or not
    // ------------------------------------------------------------------------
    function isEmpty(string self) internal pure returns (bool bEmpty) {
        bytes memory selfInBytes = bytes(self);
        return selfInBytes.length == 0;
    }
}

// ----------------------------------------------------------------------------
// Owned Contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        owner = msg.sender;
    }

    // ------------------------------------------------------------------------
    // Guarantee that msg.sender must be a contract owner
    // ------------------------------------------------------------------------
    modifier onlyOwner {
        require(
            msg.sender == owner,
            "This address is not a contract owner."
        );
        _;
    }
}

// ----------------------------------------------------------------------------
// Pizza Coin Contract
// ----------------------------------------------------------------------------
contract PizzaCoin is ERC20Interface, Owned {
    using SafeMath for uint256;
    using BasicStringUtils for string;

    // Contract events
    event StaffRegistered(address indexed _staff, string _staffName);
    event StaffKicked(address indexed _staffToBeKicked, string _staffName, address indexed _kicker, string _kickerName);
    // The 'indexed' keyword cannot be used with any string parameter
    event TeamCreated(string _teamName, address indexed _creator, string _creatorName);
    event TeamPlayerRegistered(string _teamName, address indexed _player, string _playerName);
    event TeamPlayerKicked(
        string _teamName, address indexed _playerToBeKicked, 
        string _playerName, address indexed _kicker, string _kickerName
    );
    event TeamKicked(string _teamName, address indexed _kicker, string _kickerName);
    event TeamVotedByStaff(string _teamName, address indexed _voter, string _voterName, uint256 _votingWeight);
    event TeamVotedByPlayer(
        string _teamName, address indexed _voter, string _voterName, 
        string _teamVoterAssociatedWith, uint256 _votingWeight
    );
    event StateChanged(string _state, address indexed _staff, string _staffName);

    // Token info
    string public constant symbol = "PZC";
    string public constant name = "Pizza Coin";
    uint8 public constant decimals = 0;

    struct StaffInfo {
        bool wasRegistered;    // Check if a specific staff is being registered
        string name;
        uint256 tokensBalance; // Amount of tokens left for voting
        string[] teamsVoted;   // Record all the teams voted by this staff
        
        // mapping(team => votes)
        mapping(string => uint256) votesWeight;  // A collection of teams with voting weight approved by this staff
    }

    struct TeamPlayerInfo {
        bool wasRegistered;    // Check if a specific player is being registered
        string name;
        uint256 tokensBalance; // Amount of tokens left for voting
        string teamName;       // A team this player associates with
        string[] teamsVoted;   // Record all the teams voted by this player
        
        // mapping(team => votes)
        mapping(string => uint256) votesWeight;  // A collection of teams with voting weight approved by this player
    }

    // Team with players
    struct TeamInfo {
        bool wasCreated;    // Check if the team was created for uniqueness
        address[] players;  // A list of team members (the first list member is the team leader who creates the team)
        address[] voters;   // A list of staffs and other teams' members who gave votes to this team

        // mapping(voter => votes)
        mapping(address => uint256) votesWeight;  // A collection of team voting weights from each voter (i.e., staffs + other teams' members)
        
        uint256 totalVoted;  // Total voting weight got from voters
    }

    address[] private staffs;                                 // The first staff is the contract owner
    mapping(address => StaffInfo) private staffsInfo;         // mapping(staff => StaffInfo)

    address[] private players;
    mapping(address => TeamPlayerInfo) private playersInfo;  // mapping(player => TeamPlayerInfo)

    string[] private teams;
    mapping(string => TeamInfo) private teamsInfo;           // mapping(team => TeamInfo)

    uint256 public voterInitialTokens;
    uint256 private _totalSupply;

    enum State { Registration, RegistrationLocked, Voting, VotingFinished }

    // mapping(keccak256(state) => stateInString)
    mapping(bytes32 => string) private stateMap;
    State private state = State.Registration;


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
        voterInitialTokens = _voterInitialTokens;

        emit StateChanged(convertStateToString(), owner, _ownerName);

        // Register an owner as staff
        registerStaff(owner, _ownerName);
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
            staffsInfo[_user].wasRegistered == false && 
            playersInfo[_user].wasRegistered == false,
            "This address was registered already."
        );
        _;
    }

    // ------------------------------------------------------------------------
    // Guarantee that msg.sender has been already registered
    // ------------------------------------------------------------------------
    modifier onlyRegistered {
        require(
            staffsInfo[msg.sender].wasRegistered == true || 
            playersInfo[msg.sender].wasRegistered == true,
            "This address was not being registered."
        );
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
    // Initial a state mapping
    // ------------------------------------------------------------------------
    function initStateMap() internal onlyRegistrationState onlyOwner {
        stateMap[keccak256(State.Registration)] = "Registration";
        stateMap[keccak256(State.RegistrationLocked)] = "Registration Locked";
        stateMap[keccak256(State.Voting)] = "Voting";
        stateMap[keccak256(State.VotingFinished)] = "Voting Finished";
    }

    // ------------------------------------------------------------------------
    // Convert a state to a readable string
    // ------------------------------------------------------------------------
    function convertStateToString() internal view returns (string _state) {
        return stateMap[keccak256(state)];
    }

    // ------------------------------------------------------------------------
    // Register a new staff
    // ------------------------------------------------------------------------
    function registerStaff(address _newStaff, string _newStaffName) 
        public onlyRegistrationState onlyStaff notRegistered(_newStaff) 
        returns (bool success) 
    {
        require(
            address(_newStaff) != address(0),
            "'_newStaff' contains an invalid address."
        );

        require(
            _newStaffName.isEmpty() == false,
            "'_newStaffName' might not be empty."
        );

        require(
            staffsInfo[_newStaff].wasRegistered == false,
            "The specified staff was registered already."
        );

        // Register a new staff
        staffs.push(_newStaff);
        staffsInfo[_newStaff] = StaffInfo({
            wasRegistered: true,
            name: _newStaffName,
            tokensBalance: voterInitialTokens,
            teamsVoted: new string[](0)
            /*
                Omit 'votesWeight'
            */
        });

        _totalSupply = _totalSupply.add(voterInitialTokens);

        emit StaffRegistered(_newStaff, _newStaffName);
        return true;
    }

    // ------------------------------------------------------------------------
    // Remove a specific staff
    // ------------------------------------------------------------------------
    function kickStaff(address _staff) public onlyRegistrationState onlyOwner returns (bool success) {
        require(
            address(_staff) != address(0),
            "'_staff' contains an invalid address."
        );

        require(
            staffsInfo[_staff].wasRegistered == true,
            "Cannot find the specified staff."
        );

        require(
            _staff != owner,
            "Contract owner is not kickable."
        );

        bool found;
        uint256 staffIndex;

        (found, staffIndex) = getStaffIndex(_staff);
        if (!found) {
            revert("Cannot find the specified staff.");
        }

        address kicker = msg.sender;
        string memory staffName = staffsInfo[_staff].name;
        string memory kickerName = staffsInfo[kicker].name;

        // Reset an element to 0 but the array length never decrease (beware!!)
        delete staffs[staffIndex];

        // Remove a specified staff from a mapping
        delete staffsInfo[_staff];

        _totalSupply = _totalSupply.sub(voterInitialTokens);

        emit StaffKicked(_staff, staffName, kicker, kickerName);
        return true;
    }

    // ------------------------------------------------------------------------
    // Get the index of a specific staff found in the array 'staffs'
    // ------------------------------------------------------------------------
    function getStaffIndex(address _staff) internal view returns (bool _found, uint256 _staffIndex) {
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
    // Team leader creates a team
    // ------------------------------------------------------------------------
    function createTeam(string _teamName, string _creatorName) public onlyRegistrationState notRegistered(msg.sender) returns (bool success) {
        require(
            _teamName.isEmpty() == false,
            "'_teamName' might not be empty."
        );

        require(
            _creatorName.isEmpty() == false,
            "'_creatorName' might not be empty."
        );
        
        require(
            teamsInfo[_teamName].wasCreated == false,
            "The given team was created already."
        );

        // Create a new team
        teams.push(_teamName);
        teamsInfo[_teamName] = TeamInfo({
            wasCreated: true,
            players: new address[](0),
            voters: new address[](0),
            totalVoted: 0
            /*
                Omit 'votesWeight'
            */
        });

        address creator = msg.sender;
        emit TeamCreated(_teamName, creator, _creatorName);

        // Register a creator to a team as team leader
        registerTeamPlayer(_creatorName, _teamName);
        return true;
    }

    // ------------------------------------------------------------------------
    // Register a team player
    // ------------------------------------------------------------------------
    function registerTeamPlayer(string _playerName, string _teamName) 
        public onlyRegistrationState notRegistered(msg.sender) 
        returns (bool success) 
    {
        require(
            _playerName.isEmpty() == false,
            "'_playerName' might not be empty."
        );

        require(
            _teamName.isEmpty() == false,
            "'_teamName' might not be empty."
        );
        
        require(
            teamsInfo[_teamName].wasCreated == true,
            "The given team does not exist."
        );

        address player = msg.sender;

        // Register a new player
        players.push(player);
        playersInfo[player] = TeamPlayerInfo({
            wasRegistered: true,
            name: _playerName,
            tokensBalance: voterInitialTokens,
            teamName: _teamName,
            teamsVoted: new string[](0)
            /*
                Omit 'votesWeight'
            */
        });

        // Add a player to a team he/she associates with
        teamsInfo[_teamName].players.push(player);

        _totalSupply = _totalSupply.add(voterInitialTokens);

        emit TeamPlayerRegistered(_teamName, player, _playerName);
        return true;
    }

    // ------------------------------------------------------------------------
    // Remove the first found player in a particular team 
    // (start searching at _startSearchingIndex)
    // ------------------------------------------------------------------------
    function kickFirstFoundTeamPlayer(string _teamName, uint256 _startSearchingIndex) 
        public onlyRegistrationState onlyStaff returns (uint256 _nextStartSearchingIndex, uint256 _totalPlayersRemaining) {
        
        require(
            _teamName.isEmpty() == false,
            "'_teamName' might not be empty."
        );

        require(
            teamsInfo[_teamName].wasCreated == true,
            "Cannot find the specified team."
        );

        require(
            _startSearchingIndex < teamsInfo[_teamName].players.length,
            "'_startSearchingIndex' is out of bound."
        );

        _nextStartSearchingIndex = teamsInfo[_teamName].players.length;
        _totalPlayersRemaining = 0;

        for (uint256 i = _startSearchingIndex; i < teamsInfo[_teamName].players.length; i++) {
            if (
                playersInfo[teamsInfo[_teamName].players[i]].wasRegistered == true && 
                playersInfo[teamsInfo[_teamName].players[i]].teamName.isEqual(_teamName)
            ) {
                // Remove a specific player
                kickTeamPlayer(teamsInfo[_teamName].players[i], _teamName);

                // Start next searching at the next array element
                _nextStartSearchingIndex = i + 1;
                _totalPlayersRemaining = getTotalTeamPlayers(_teamName);
                return;     
            }
        }
    }

    // ------------------------------------------------------------------------
    // Remove a specific player from a particular team
    // ------------------------------------------------------------------------
    function kickTeamPlayer(address _player, string _teamName) public onlyRegistrationState onlyStaff returns (bool success) {
        require(
            address(_player) != address(0),
            "'_player' contains an invalid address."
        );

        require(
            _teamName.isEmpty() == false,
            "'_teamName' might not be empty."
        );
        
        require(
            playersInfo[_player].wasRegistered == true &&
            playersInfo[_player].teamName.isEqual(_teamName),
            "Cannot find the specified player in a given team."
        );

        bool found;
        uint256 playerIndex;

        (found, playerIndex) = getPlayerIndex(_player);
        if (!found) {
            revert("Cannot find the specified player.");
        }

        address kicker = msg.sender;
        string memory playerName = playersInfo[_player].name;
        string memory kickerName = staffsInfo[kicker].name;

        // Reset an element to 0 but the array length never decrease (beware!!)
        delete players[playerIndex];

        // Remove a specified player from a mapping
        delete playersInfo[_player];

        (found, playerIndex) = getTeamPlayerIndex(_player, _teamName);
        if (!found) {
            revert("Cannot find the specified player in a given team.");
        }

        // Reset an element to 0 but the array length never decrease (beware!!)
        delete teamsInfo[_teamName].players[playerIndex];

        _totalSupply = _totalSupply.sub(voterInitialTokens);

        emit TeamPlayerKicked(_teamName, _player, playerName, kicker, kickerName);
        return true;
    }

    // ------------------------------------------------------------------------
    // Get the index of a specific player found in the array 'players'
    // ------------------------------------------------------------------------
    function getPlayerIndex(address _player) internal view returns (bool _found, uint256 _playerIndex) {
        assert(_player != address(0));

        _found = false;
        _playerIndex = 0;

        for (uint256 i = 0; i < players.length; i++) {
            if (players[i] == _player) {
                _found = true;
                _playerIndex = i;
                return;
            }
        }
    }

    // ------------------------------------------------------------------------
    // Get the index of a specific player in a given team 
    // found in the the array 'players' in the mapping 'teamsInfo'
    // ------------------------------------------------------------------------
    function getTeamPlayerIndex(address _player, string _teamName) internal view returns (bool _found, uint256 _playerIndex) {
        assert(_player != address(0));
        assert(_teamName.isEmpty() == false);
        assert(teamsInfo[_teamName].wasCreated == true);

        _found = false;
        _playerIndex = 0;

        for (uint256 i = 0; i < teamsInfo[_teamName].players.length; i++) {
            if (teamsInfo[_teamName].players[i] == _player) {
                _found = true;
                _playerIndex = i;
                return;
            }
        }
    }

    // ------------------------------------------------------------------------
    // Remove a specific team (the team must be empty of players)
    // ------------------------------------------------------------------------
    function kickTeam(string _teamName) public onlyRegistrationState onlyStaff returns (bool success) {
        require(
            _teamName.isEmpty() == false,
            "'_teamName' might not be empty."
        );
        
        require(
            teamsInfo[_teamName].wasCreated == true,
            "Cannot find the specified team."
        );

        uint256 totalPlayers = getTotalTeamPlayers(_teamName);

        // The team can be removed if and only if it has 0 player left
        if (totalPlayers != 0) {
            revert("Team is not empty.");
        }

        bool found;
        uint256 teamIndex;

        (found, teamIndex) = getTeamIndex(_teamName);
        if (!found) {
            revert("Cannot find the specified team.");
        }

        // Reset an element to 0 but the array length never decrease (beware!!)
        delete teams[teamIndex];

        // Remove a specified team from a mapping
        delete teamsInfo[_teamName];

        address kicker = msg.sender;
        string memory kickerName = staffsInfo[kicker].name;
        emit TeamKicked(_teamName, kicker, kickerName);
        return true;
    }

    // ------------------------------------------------------------------------
    // Get the index of a specific team found in the array 'teams'
    // ------------------------------------------------------------------------
    function getTeamIndex(string _teamName) internal view returns (bool _found, uint256 _teamIndex) {
        assert(_teamName.isEmpty() == false);

        _found = false;
        _teamIndex = 0;

        for (uint256 i = 0; i < teams.length; i++) {
            if (teams[i].isEqual(_teamName)) {
                _found = true;
                _teamIndex = i;
                return;
            }
        }
    }

    // ------------------------------------------------------------------------
    // Allow a staff freeze Registration state and transfer the state to RegistrationLocked
    // ------------------------------------------------------------------------
    function lockRegistration() public onlyRegistrationState onlyStaff returns (bool success) {
        state = State.RegistrationLocked;

        address staff = msg.sender;
        string memory staffName = staffsInfo[staff].name;
        emit StateChanged(convertStateToString(), staff, staffName);
        return true;
    }

    // ------------------------------------------------------------------------
    // Allow a staff transfer a state from RegistrationLocked to Voting
    // ------------------------------------------------------------------------
    function startVoting() public onlyRegistrationLockedState onlyStaff returns (bool success) {
        state = State.Voting;

        address staff = msg.sender;
        string memory staffName = staffsInfo[staff].name;
        emit StateChanged(convertStateToString(), staff, staffName);
        return true;
    }

    // ------------------------------------------------------------------------
    // Allow a staff transfer a state from Voting to VotingFinished
    // ------------------------------------------------------------------------
    function stopVoting() public onlyVotingState onlyStaff returns (bool success) {
        state = State.VotingFinished;

        address staff = msg.sender;
        string memory staffName = staffsInfo[staff].name;
        emit StateChanged(convertStateToString(), staff, staffName);
        return true;
    }

    // ------------------------------------------------------------------------
    // Get a total number of staff
    // ------------------------------------------------------------------------
    function getTotalStaff() public view returns (uint256 _total) {
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
        public view 
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
    function getTotalVotesByStaff(address _staff) public view returns (uint256 _total) {
        require(
            address(_staff) != address(0),
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
        public view 
        returns (
            bool _endOfList,
            string _team,
            uint256 _voteWeight
        ) 
    {
        require(
            address(_staff) != address(0),
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
    // Get a total number of players
    // ------------------------------------------------------------------------
    function getTotalPlayers() public view returns (uint256 _total) {
        _total = 0;
        for (uint256 i = 0; i < players.length; i++) {
            // Player was not removed before
            if (players[i] != address(0) && playersInfo[players[i]].wasRegistered == true) {
                _total++;
            }
        }
    }

    // ------------------------------------------------------------------------
    // Get an info of the first found player 
    // (start searching at _startSearchingIndex)
    // ------------------------------------------------------------------------
    function getFirstFoundPlayerInfo(uint256 _startSearchingIndex) 
        public view 
        returns (
            bool _endOfList, 
            uint256 _nextStartSearchingIndex,
            address _player,
            string _name,
            uint256 _tokensBalance,
            string _teamName
        ) 
    {
        _endOfList = true;
        _nextStartSearchingIndex = players.length;
        _player = address(0);
        _name = "";
        _tokensBalance = 0;
        _teamName = "";

        if (_startSearchingIndex >= players.length) {
            return;
        }  

        for (uint256 i = _startSearchingIndex; i < players.length; i++) {
            address player = players[i];

            // Player was not removed before
            if (player != address(0) && playersInfo[player].wasRegistered == true) {
                _endOfList = false;
                _nextStartSearchingIndex = i + 1;
                _player = player;
                _name = playersInfo[player].name;
                _tokensBalance = playersInfo[player].tokensBalance;
                _teamName = playersInfo[player].teamName;
                return;
            }
        }
    }

    // ------------------------------------------------------------------------
    // Get a total number of the votes ('teamsVoted' array) made by the specified player
    // ------------------------------------------------------------------------
    function getTotalVotesByPlayer(address _player) public view returns (uint256 _total) {
        require(
            address(_player) != address(0),
            "'_player' contains an invalid address."
        );
        
        require(
            playersInfo[_player].wasRegistered == true,
            "Cannot find the specified player."
        );

        return playersInfo[_player].teamsVoted.length;
    }

    // ------------------------------------------------------------------------
    // Get a team voting result (at the index of 'teamsVoted' array) made by the specified player
    // ------------------------------------------------------------------------
    function getVoteResultAtIndexByPlayer(address _player, uint256 _votingIndex) 
        public view 
        returns (
            bool _endOfList,
            string _team,
            uint256 _voteWeight
        ) 
    {
        require(
            address(_player) != address(0),
            "'_player' contains an invalid address."
        );

        require(
            playersInfo[_player].wasRegistered == true,
            "Cannot find the specified player."
        );

        if (_votingIndex >= playersInfo[_player].teamsVoted.length) {
            _endOfList = true;
            _team = "";
            _voteWeight = 0;
            return;
        }

        _endOfList = false;
        _team = playersInfo[_player].teamsVoted[_votingIndex];
        _voteWeight = playersInfo[_player].votesWeight[_team];
    }

    // ------------------------------------------------------------------------
    // Get a total number of teams
    // ------------------------------------------------------------------------
    function getTotalTeams() public view returns (uint256 _total) {
        _total = 0;
        for (uint256 i = 0; i < teams.length; i++) {
            // Team was not removed before
            if (teams[i].isEmpty() == false && teamsInfo[teams[i]].wasCreated == true) {
                _total++;
            }
        }
    }

    // ------------------------------------------------------------------------
    // Get an info of the first found team 
    // (start searching at _startSearchingIndex)
    // ------------------------------------------------------------------------
    function getFirstFoundTeamInfo(uint256 _startSearchingIndex) 
        public view 
        returns (
            bool _endOfList, 
            uint256 _nextStartSearchingIndex,
            string _teamName,
            uint256 _totalVoted
        ) 
    {
        _endOfList = true;
        _nextStartSearchingIndex = teams.length;
        _teamName = "";
        _totalVoted = 0;

        if (_startSearchingIndex >= teams.length) {
            return;
        }  

        for (uint256 i = _startSearchingIndex; i < teams.length; i++) {
            string memory teamName = teams[i];

            // Team was not removed before
            if (teamName.isEmpty() == false && teamsInfo[teamName].wasCreated == true) {
                _endOfList = false;
                _nextStartSearchingIndex = i + 1;
                _teamName = teamName;
                _totalVoted = teamsInfo[teamName].totalVoted;
                return;
            }
        }
    }

    // ------------------------------------------------------------------------
    // Get a total number of players in a specified team
    // ------------------------------------------------------------------------
    function getTotalTeamPlayers(string _teamName) public view returns (uint256 _total) {
        require(
            _teamName.isEmpty() == false,
            "'_teamName' might not be empty."
        );

        require(
            teamsInfo[_teamName].wasCreated == true,
            "Cannot find the specified team."
        );

        _total = 0;
        for (uint256 i = 0; i < teamsInfo[_teamName].players.length; i++) {
            address player = teamsInfo[_teamName].players[i];

            // player == address(0) if the player was removed by kickTeamPlayer()
            if (player != address(0) && playersInfo[player].wasRegistered == true) {
                _total++;
            }
        }
    }

    // ------------------------------------------------------------------------
    // Get the first found player of a specified team
    // (start searching at _startSearchingIndex)
    // ------------------------------------------------------------------------
    function getFirstFoundTeamPlayer(string _teamName, uint256 _startSearchingIndex) 
        public view 
        returns (
            bool _endOfList, 
            uint256 _nextStartSearchingIndex,
            address _player
        ) 
    {
        require(
            _teamName.isEmpty() == false,
            "'_teamName' might not be empty."
        );

        require(
            teamsInfo[_teamName].wasCreated == true,
            "Cannot find the specified team."
        );
        
        _endOfList = true;
        _nextStartSearchingIndex = teamsInfo[_teamName].players.length;
        _player = address(0);

        if (_startSearchingIndex >= teamsInfo[_teamName].players.length) {
            return;
        }  

        for (uint256 i = _startSearchingIndex; i < teamsInfo[_teamName].players.length; i++) {
            address player = teamsInfo[_teamName].players[i];

            // Player was not removed before
            if (player != address(0) && playersInfo[player].wasRegistered == true) {
                _endOfList = false;
                _nextStartSearchingIndex = i + 1;
                _player = player;
                return;
            }
        }
    }

    // ------------------------------------------------------------------------
    // Get a total number of voters to a specified team
    // ------------------------------------------------------------------------
    function getTotalVotersToTeam(string _teamName) public view returns (uint256 _total) {
        require(
            _teamName.isEmpty() == false,
            "'_teamName' might not be empty."
        );
        
        require(
            teamsInfo[_teamName].wasCreated == true,
            "Cannot find the specified team."
        );

        return teamsInfo[_teamName].voters.length;
    }

    // ------------------------------------------------------------------------
    // Get a voting result (by the index of voters) to a specified team
    // ------------------------------------------------------------------------
    function getVoteResultAtIndexToTeam(string _teamName, uint256 _voterIndex) 
        public view 
        returns (
            bool _endOfList,
            address _voter,
            uint256 _voteWeight
        ) 
    {
        require(
            _teamName.isEmpty() == false,
            "'_teamName' might not be empty."
        );

        require(
            teamsInfo[_teamName].wasCreated == true,
            "Cannot find the specified team."
        );

        if (_voterIndex >= teamsInfo[_teamName].voters.length) {
            _endOfList = true;
            _voter = address(0);
            _voteWeight = 0;
            return;
        }

        _endOfList = false;
        _voter = teamsInfo[_teamName].voters[_voterIndex];
        _voteWeight = teamsInfo[_teamName].votesWeight[_voter];
    }

    // ------------------------------------------------------------------------
    // Get a contract state in String format
    // ------------------------------------------------------------------------
    function getContractState() public view returns (string _state) {
        return convertStateToString();
    }

    // ------------------------------------------------------------------------
    // Allow any staff or any player in other different teams to vote to a team
    // ------------------------------------------------------------------------
    function voteTeam(string _teamName, uint256 _votingWeight) public onlyVotingState onlyRegistered returns (bool success) {
        require(
            _teamName.isEmpty() == false,
            "'_teamName' might not be empty."
        );

        require(
            _votingWeight > 0,
            "'_votingWeight' must be larger than 0."
        );
        
        require(
            teamsInfo[_teamName].wasCreated == true,
            "Cannot find the specified team."
        );

        if (isStaff(msg.sender)) {
            return voteTeamByStaff(_teamName, _votingWeight);  // a staff
        }
        else {
            return voteTeamByDifferentTeamPlayer(_teamName, _votingWeight);  // a team player
        }
    }

    // ------------------------------------------------------------------------
    // Determine if _user is a staff or not
    // ------------------------------------------------------------------------
    function isStaff(address _user) internal view returns (bool bStaff) {
        return staffsInfo[_user].wasRegistered;
    }

    // ------------------------------------------------------------------------
    // Determine if _user is a team player or not
    // ------------------------------------------------------------------------
    function isTeamPlayer(address _user) internal view returns (bool bPlayer) {
        return playersInfo[_user].wasRegistered;
    }

    // ------------------------------------------------------------------------
    // Vote for a team by a staff
    // ------------------------------------------------------------------------
    function voteTeamByStaff(string _teamName, uint256 _votingWeight) internal onlyVotingState returns (bool success) {
        address voter = msg.sender;
        assert(_teamName.isEmpty() == false);
        assert(_votingWeight > 0);
        assert(teamsInfo[_teamName].wasCreated == true);
        assert(isStaff(voter));

        require(
            _votingWeight <= staffsInfo[voter].tokensBalance,
            "Insufficient voting balance."
        );

        staffsInfo[voter].tokensBalance = staffsInfo[voter].tokensBalance.sub(_votingWeight);

        // If staffsInfo[voter].votesWeight[_teamName] > 0 is true, this implies that 
        // the voter was used to give a vote to the specified team previously
        if (staffsInfo[voter].votesWeight[_teamName] == 0) {
            // The voter has never been given a vote to the specified team before
            // We, therefore, have to add a new team to the 'teamsVoted' array
            staffsInfo[voter].teamsVoted.push(_teamName);

            // We also need to add a new voter to the 'voters' array 
            // which is in the 'teamsInfo' mapping
            teamsInfo[_teamName].voters.push(voter);
        }

        staffsInfo[voter].votesWeight[_teamName] = staffsInfo[voter].votesWeight[_teamName].add(_votingWeight);
        teamsInfo[_teamName].votesWeight[voter] = teamsInfo[_teamName].votesWeight[voter].add(_votingWeight);
        teamsInfo[_teamName].totalVoted = teamsInfo[_teamName].totalVoted.add(_votingWeight);

        string memory voterName = staffsInfo[voter].name;
        emit TeamVotedByStaff(_teamName, voter, voterName, _votingWeight);
        return true;
    }

    // ------------------------------------------------------------------------
    // Vote for a team by a different team player
    // ------------------------------------------------------------------------
    function voteTeamByDifferentTeamPlayer(string _teamName, uint256 _votingWeight) internal onlyVotingState returns (bool success) {
        address voter = msg.sender;
        assert(_teamName.isEmpty() == false);
        assert(_votingWeight > 0);
        assert(teamsInfo[_teamName].wasCreated == true);
        assert(isTeamPlayer(voter));

        require(
            playersInfo[voter].teamName.isEqual(_teamName) == false,
            "A player does not allow to vote to his/her own team."
        );

        require(
            _votingWeight <= playersInfo[voter].tokensBalance,
            "Insufficient voting balance."
        );

        playersInfo[voter].tokensBalance = playersInfo[voter].tokensBalance.sub(_votingWeight);

        // If playersInfo[voter].votesWeight[_teamName] > 0 is true, this implies that 
        // the voter was used to give a vote to the specified team previously
        if (playersInfo[voter].votesWeight[_teamName] == 0) {
            // The voter has never been given a vote to the specified team before
            // We, therefore, have to add a new team to the 'teamsVoted' array
            playersInfo[voter].teamsVoted.push(_teamName);

            // We also need to add a new voter to the 'voters' array 
            // which is in the 'teamsInfo' mapping
            teamsInfo[_teamName].voters.push(voter);
        }

        playersInfo[voter].votesWeight[_teamName] = playersInfo[voter].votesWeight[_teamName].add(_votingWeight);
        teamsInfo[_teamName].votesWeight[voter] = teamsInfo[_teamName].votesWeight[voter].add(_votingWeight);
        teamsInfo[_teamName].totalVoted = teamsInfo[_teamName].totalVoted.add(_votingWeight);

        string memory voterName = playersInfo[voter].name;
        string memory teamVoterAssociatedWith = playersInfo[voter].teamName;
        emit TeamVotedByPlayer(_teamName, voter, voterName, teamVoterAssociatedWith, _votingWeight);
        return true;
    }

    // ------------------------------------------------------------------------
    // Find a maximum voting points from each team after voting is finished
    // ------------------------------------------------------------------------
    function getMaxTeamVotingPoints() public view onlyVotingFinishedState returns (uint256 _maxTeamVotingPoints) {
        _maxTeamVotingPoints = 0;
        for (uint256 i = 0; i < teams.length; i++) {
            // Team was not removed before
            if (teams[i].isEmpty() == false && teamsInfo[teams[i]].wasCreated == true) {
                // Find a new maximum points
                if (teamsInfo[teams[i]].totalVoted > _maxTeamVotingPoints) {
                    _maxTeamVotingPoints = teamsInfo[teams[i]].totalVoted;
                }
            }
        }
    }

    // ------------------------------------------------------------------------
    // Get a total number of team winners after voting is finished
    // It is possible to have several teams that got the equal maximum voting points 
    // ------------------------------------------------------------------------
    function getTotalTeamWinners() public view onlyVotingFinishedState returns (uint256 _total) {
        uint256 maxTeamVotingPoints = getMaxTeamVotingPoints();

        _total = 0;
        for (uint256 i = 0; i < teams.length; i++) {
            // Team was not removed before
            if (teams[i].isEmpty() == false && teamsInfo[teams[i]].wasCreated == true) {
                // Count the team winners up
                if (teamsInfo[teams[i]].totalVoted == maxTeamVotingPoints) {
                    _total++;
                }
            }
        }
    }
    
    // ------------------------------------------------------------------------
    // Get the first found team winner
    // (start searching at _startSearchingIndex)
    // It is possible to have several teams that got the equal maximum voting points 
    // ------------------------------------------------------------------------
    function getFirstFoundTeamWinner(uint256 _startSearchingIndex) 
        public view onlyVotingFinishedState 
        returns (
            bool _endOfList,
            uint256 _nextStartSearchingIndex,
            string _teamName, 
            uint256 _totalVoted
        )
    {
        _endOfList = true;
        _nextStartSearchingIndex = teams.length;
        _teamName = "";
        _totalVoted = 0;

        if (_startSearchingIndex >= teams.length) {
            return;
        }

        uint256 maxTeamVotingPoints = getMaxTeamVotingPoints();
        for (uint256 i = _startSearchingIndex; i < teams.length; i++) {
            string memory teamName = teams[i];

            // Team was not removed before
            if (teamName.isEmpty() == false && teamsInfo[teamName].wasCreated == true) {
                // Find a team winner
                if (teamsInfo[teamName].totalVoted == maxTeamVotingPoints) {
                    _endOfList = false;
                    _nextStartSearchingIndex = i + 1;
                    _teamName = teamName;
                    _totalVoted = teamsInfo[teamName].totalVoted;
                    return;
                }
            }
        }
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
    function totalSupply() public view returns (uint256 totalSupply_) {
        return _totalSupply;
    }

    // ------------------------------------------------------------------------
    // Standard function of ERC token standard #20
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint256 balance) {
        if (isStaff(tokenOwner)) {
            return staffsInfo[tokenOwner].tokensBalance;
        }
        else if (isTeamPlayer(tokenOwner)) {
            return playersInfo[tokenOwner].tokensBalance;
        }
        else {
            revert("The specified address was not being registered.");
        }
    }

    // ------------------------------------------------------------------------
    // Standard function of ERC token standard #20
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public view returns (uint256) {
        // This function is never used
        revert("We don't implement this function.");

        // These statements do nothing, just use to stop compilation warnings
        tokenOwner == tokenOwner;
        spender == spender;
    }

    // ------------------------------------------------------------------------
    // Standard function of ERC token standard #20
    // ------------------------------------------------------------------------
    function transfer(address to, uint256 tokens) public returns (bool) {
        // This function is never used
        revert("We don't implement this function.");

        // These statements do nothing, just use to stop compilation warnings
        to == to;
        tokens == tokens;
    }

    // ------------------------------------------------------------------------
    // Standard function of ERC token standard #20
    // ------------------------------------------------------------------------
    function approve(address spender, uint256 tokens) public returns (bool) {
        // This function is never used
        revert("We don't implement this function.");

        // These statements do nothing, just use to stop compilation warnings
        spender == spender;
        tokens == tokens;
    }

    // ------------------------------------------------------------------------
    // Standard function of ERC token standard #20
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint256 tokens) public returns (bool) {
        // This function is never used
        revert("We don't implement this function.");

        // These statements do nothing, just use to stop compilation warnings
        from == from;
        to == to;
        tokens == tokens;
    }
}