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
// Interface for exporting external functions of PizzaCoinTeam contract
// ------------------------------------------------------------------------
interface ITeamContract {
    function lockRegistration() external;
    function startVoting() external;
    function stopVoting() external;
    function createTeam(string _teamName) external;
    function registerPlayerToTeam(address _player, string _teamName) external;
    function kickTeam(string _teamName) external;
    function kickPlayerOutOffTeam(address _player, string _teamName) external;
    function doesTeamExist(string _teamName) external view returns (bool bTeamExist);
    function getArrayLengthOfPlayersInTeam(string _teamName) external view returns (uint256 _length);
    function getTotalPlayersInTeam(string _teamName) external view returns (uint256 _total);
    function getFirstFoundPlayerInTeam(string _teamName, uint256 _startSearchingIndex) 
        external view
        returns (
            bool _endOfList, 
            uint256 _nextStartSearchingIndex,
            address _player
        );
    function getPlayerInTeamAtIndex(string _teamName, uint256 _playerIndex) 
        external view 
        returns (
            bool _endOfList, 
            address _player
        );
    function getTotalTeams() external view returns (uint256 _total);
    function getFirstFoundTeamInfo(uint256 _startSearchingIndex) 
        external view
        returns (
            bool _endOfList, 
            uint256 _nextStartSearchingIndex,
            string _teamName,
            uint256 _totalVoted
        );
    function getTotalVotersToTeam(string _teamName) external view returns (uint256 _total);
    function getVoteResultAtIndexToTeam(string _teamName, uint256 _voterIndex) 
        external view
        returns (
            bool _endOfList,
            address _voter,
            uint256 _voteWeight
        );
    function voteToTeam(string _teamName, address _voter, uint256 _votingWeight) external;
    function getMaxTeamVotingPoints() external view returns (uint256 _maxTeamVotingPoints);
    function getTotalTeamWinners() external view returns (uint256 _total);
    function getFirstFoundTeamWinner(uint256 _startSearchingIndex) 
        external view
        returns (
            bool _endOfList,
            uint256 _nextStartSearchingIndex,
            string _teamName, 
            uint256 _totalVoted
        );
}


// ----------------------------------------------------------------------------
// Pizza Coin Team Contract
// ----------------------------------------------------------------------------
contract PizzaCoinTeam is ITeamContract, Owned {
    /*
    * Owner of the contract is PizzaCoin contract, 
    * not a project deployer (or PizzaCoin's owner)
    */

    using SafeMath for uint256;
    using BasicStringUtils for string;


    // Team with players
    struct TeamInfo {
        bool wasCreated;    // Check if the team was created for uniqueness
        address[] players;  // A list of team members (the first list member is the team leader who creates the team)
        address[] voters;   // A list of staffs and other teams' members who gave votes to this team

        // mapping(voter => votes)
        mapping(address => uint256) votesWeight;  // A collection of team voting weights from each voter (i.e., staffs + other teams' members)
        
        uint256 totalVoted;  // Total voting weight got from voters
    }

    string[] private teams;
    mapping(string => TeamInfo) private teamsInfo;  // mapping(team => TeamInfo)

    enum State { Registration, RegistrationLocked, Voting, VotingFinished }
    State private state = State.Registration;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
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
    // Determine if the specified team exists
    // ------------------------------------------------------------------------
    function doesTeamExist(string _teamName) external view returns (bool bTeamExist) {
        require(
            _teamName.isEmpty() == false,
            "'_teamName' might not be empty."
        );

        return teamsInfo[_teamName].wasCreated;
    }

    // ------------------------------------------------------------------------
    // Team leader creates a team
    // ------------------------------------------------------------------------
    function createTeam(string _teamName) external onlyRegistrationState onlyPizzaCoin {
        require(
            _teamName.isEmpty() == false,
            "'_teamName' might not be empty."
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
    }

    // ------------------------------------------------------------------------
    // Register a player to a specific team
    // ------------------------------------------------------------------------
    function registerPlayerToTeam(address _player, string _teamName) external onlyRegistrationState onlyPizzaCoin {
        require(
            _player != address(0),
            "'_player' contains an invalid address."
        );

        require(
            _teamName.isEmpty() == false,
            "'_teamName' might not be empty."
        );

        require(
            teamsInfo[_teamName].wasCreated == true,
            "The given team does not exist."
        );

        // Add a player to a team he/she associates with
        teamsInfo[_teamName].players.push(_player);
    }

    // ------------------------------------------------------------------------
    // Remove a specific team (the team must be empty of players)
    // ------------------------------------------------------------------------
    function kickTeam(string _teamName) external onlyRegistrationState onlyPizzaCoin {
        require(
            _teamName.isEmpty() == false,
            "'_teamName' might not be empty."
        );

        require(
            teamsInfo[_teamName].wasCreated == true,
            "Cannot find the specified team."
        );

        uint256 totalPlayers = __getTotalPlayersInTeam(_teamName);

        // The team can be removed if and only if it has 0 player left
        if (totalPlayers != 0) {
            revert("Team is not empty.");
        }

        bool found;
        uint teamIndex;

        (found, teamIndex) = getTeamIndex(_teamName);
        if (!found) {
            revert("Cannot find the specified team.");
        }

        // Reset an element to 0 but the array length never decrease (beware!!)
        delete teams[teamIndex];

        // Remove a specified team from a mapping
        delete teamsInfo[_teamName];
    }

    // ------------------------------------------------------------------------
    // Remove a specific player from a particular team
    // ------------------------------------------------------------------------
    function kickPlayerOutOffTeam(address _player, string _teamName) external onlyRegistrationState onlyPizzaCoin {
        require(
            _player != address(0),
            "'_player' contains an invalid address."
        );

        require(
            _teamName.isEmpty() == false,
            "'_teamName' might not be empty."
        );

        require(
            teamsInfo[_teamName].wasCreated == true,
            "Cannot find the specified team."
        );

        bool found;
        uint playerIndex;

        (found, playerIndex) = getTeamPlayerIndex(_player, _teamName);
        if (!found) {
            revert("Cannot find the specified player in a given team.");
        }

        // Reset an element to 0 but the array length never decrease (beware!!)
        delete teamsInfo[_teamName].players[playerIndex];
    }

    // ------------------------------------------------------------------------
    // Get the index of a specific player in a given team 
    // found in the the array 'players' in the mapping 'teamsInfo'
    // ------------------------------------------------------------------------
    function getTeamPlayerIndex(address _player, string _teamName) internal view onlyPizzaCoin returns (bool _found, uint256 _playerIndex) {
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
    // Get the array length of players in the specific team (including all ever removal players)
    // ------------------------------------------------------------------------
    function getArrayLengthOfPlayersInTeam(string _teamName) external view returns (uint256 _length) {
        require(
            _teamName.isEmpty() == false,
            "'_teamName' might not be empty."
        );

        require(
            teamsInfo[_teamName].wasCreated == true,
            "Cannot find the specified team."
        );

        return teamsInfo[_teamName].players.length;
    }

    // ------------------------------------------------------------------------
    // Get a total number of players in a specified team (external)
    // ------------------------------------------------------------------------
    function getTotalPlayersInTeam(string _teamName) external view returns (uint256 _total) {
        return __getTotalPlayersInTeam(_teamName);
    }

    // ------------------------------------------------------------------------
    // Get a total number of players in a specified team (internal)
    // ------------------------------------------------------------------------
    function __getTotalPlayersInTeam(string _teamName) internal view returns (uint256 _total) {
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

            // player == address(0) if the player was removed
            if (player != address(0)) {
                _total++;
            }
        }
    }

    // ------------------------------------------------------------------------
    // Get the first found player of a specified team
    // (start searching at _startSearchingIndex)
    // ------------------------------------------------------------------------
    function getFirstFoundPlayerInTeam(string _teamName, uint256 _startSearchingIndex) 
        external view
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
            if (player != address(0)) {
                _endOfList = false;
                _nextStartSearchingIndex = i + 1;
                _player = player;
                return;
            }
        }
    }

    // ------------------------------------------------------------------------
    // Get a player in the specified team at the specified index (including all ever removal players)
    // ------------------------------------------------------------------------
    function getPlayerInTeamAtIndex(string _teamName, uint256 _playerIndex) 
        external view 
        returns (
            bool _endOfList, 
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

        if (_playerIndex >= teamsInfo[_teamName].players.length) {
            _endOfList = true;
            _player = address(0);
            return;
        }

        _endOfList = false;
        _player = teamsInfo[_teamName].players[_playerIndex];
    }

    // ------------------------------------------------------------------------
    // Get the index of a specific team found in the array 'teams'
    // ------------------------------------------------------------------------
    function getTeamIndex(string _teamName) internal view onlyPizzaCoin returns (bool _found, uint256 _teamIndex) {
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
    // Get a total number of teams
    // ------------------------------------------------------------------------
    function getTotalTeams() external view returns (uint256 _total) {
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
        external view
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
    // Get a total number of voters to a specified team
    // ------------------------------------------------------------------------
    function getTotalVotersToTeam(string _teamName) external view returns (uint256 _total) {
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
        external view
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
    // Allow a staff or a player to give a vote to the specified team
    // ------------------------------------------------------------------------
    function voteToTeam(string _teamName, address _voter, uint256 _votingWeight) external onlyVotingState onlyPizzaCoin {
        require(
            _teamName.isEmpty() == false,
            "'_teamName' might not be empty."
        );

        require(
            _voter != address(0),
            "'_voter' contains an invalid address."
        );

        require(
            _votingWeight > 0,
            "'_votingWeight' must be larger than 0."
        );

        require(
            teamsInfo[_teamName].wasCreated == true,
            "Cannot find the specified team."
        );

        // If teamsInfo[_teamName].votesWeight[_voter] > 0 is true, this implies that 
        // the voter was used to give a vote to the specified team previously
        if (teamsInfo[_teamName].votesWeight[_voter] == 0) {
            // The voter has never been given a vote to the specified team before
            // We, therefore, have to add a new voter to the 'voters' array
            // which is in the 'teamsInfo' mapping
            teamsInfo[_teamName].voters.push(_voter);
        }

        teamsInfo[_teamName].votesWeight[_voter] = teamsInfo[_teamName].votesWeight[_voter].add(_votingWeight);
        teamsInfo[_teamName].totalVoted = teamsInfo[_teamName].totalVoted.add(_votingWeight);
    }

    // ------------------------------------------------------------------------
    // Find a maximum voting points from each team after voting is finished (external)
    // ------------------------------------------------------------------------
    function getMaxTeamVotingPoints() external view onlyVotingFinishedState returns (uint256 _maxTeamVotingPoints) {
        return __getMaxTeamVotingPoints();
    }

    // ------------------------------------------------------------------------
    // Find a maximum voting points from each team after voting is finished (internal)
    // ------------------------------------------------------------------------
    function __getMaxTeamVotingPoints() internal view onlyVotingFinishedState returns (uint256 _maxTeamVotingPoints) {
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
    function getTotalTeamWinners() external view onlyVotingFinishedState returns (uint256 _total) {
        uint256 maxTeamVotingPoints = __getMaxTeamVotingPoints();

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
        external view onlyVotingFinishedState
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

        uint256 maxTeamVotingPoints = __getMaxTeamVotingPoints();
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
}