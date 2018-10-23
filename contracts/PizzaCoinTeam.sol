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
    function kickPlayerOutOfTeam(address _player, string _teamName) external;
    function doesTeamExist(string _teamName) external view returns (bool bTeamExist);
    function getTotalPlayersInTeam(string _teamName) external view returns (uint256 _total);
    function getPlayerInTeamAtIndex(string _teamName, uint256 _playerIndex) 
        external view 
        returns (
            bool _endOfList, 
            address _player
        );
    function getTotalTeams() external view returns (uint256 _total);
    function getTeamInfoAtIndex(uint256 _teamIndex) 
        external view
        returns (
            bool _endOfList,
            string _teamName,
            uint256 _totalVoted
        );
    function getVotingPointsOfTeam(string _teamName) external view returns (uint256 _totalVoted);
    function getTotalVotersToTeam(string _teamName) external view returns (uint256 _total);
    function getVotingResultToTeamAtIndex(string _teamName, uint256 _voterIndex) 
        external view
        returns (
            bool _endOfList,
            address _voter,
            uint256 _voteWeight
        );
    function voteToTeam(address _voter, string _teamName, uint256 _votingWeight) external;
    function getMaxTeamVotingPoints() external view returns (uint256 _maxTeamVotingPoints);
    function getTotalWinningTeams() external view returns (uint256 _total);
    function getFirstFoundWinningTeam(uint256 _startSearchingIndex) 
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
    * not a project deployer who is PizzaCoin owner
    */

    using SafeMath for uint256;
    using BasicStringUtils for string;


    // Team with players
    struct TeamInfo {
        // This is used to reduce potential gas cost consumption when kicking a team
        uint256 index;  // A pointing index to a particular team on the 'teams' array

        bool wasCreated;    // Check if a team is being created
        address[] players;  // A list of team members (the first member is the one who creates a team)

        // mapping(player => playerIndex)
        mapping(address => uint256) playerIndexMap;  // This is used to reduce potential gas cost consumption when kicking a player in a team

        address[] voters;  // A list of staffs and other teams' members who have ever voted to a team

        // mapping(voter => votingWeight)
        mapping(address => uint256) votesWeight;  // Voting weight from each voter
        
        uint256 totalVoted;  // Total voting weight from all voters
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
    // Determine if the specified team exists
    // ------------------------------------------------------------------------
    function doesTeamExist(string _teamName) external view returns (bool bTeamExist) {
        require(
            _teamName.isNotEmpty(),
            "'_teamName' might not be empty."
        );

        return teamsInfo[_teamName].wasCreated;
    }

    // ------------------------------------------------------------------------
    // Player creates a new team
    // ------------------------------------------------------------------------
    function createTeam(string _teamName) external onlyRegistrationState onlyPizzaCoin {
        require(
            _teamName.isNotEmpty(),
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
            totalVoted: 0,
            /*
                Omit 'votesWeight'
            */
            index: teams.length - 1
            /*
                Omit 'playerIndexMap'
            */
        });
    }

    // ------------------------------------------------------------------------
    // Register a player to a specific team
    // ------------------------------------------------------------------------
    function registerPlayerToTeam(address _player, string _teamName) 
        external onlyRegistrationState onlyPizzaCoin 
    {
        require(
            _player != address(0),
            "'_player' contains an invalid address."
        );

        require(
            _teamName.isNotEmpty(),
            "'_teamName' might not be empty."
        );

        require(
            teamsInfo[_teamName].wasCreated,
            "The given team does not exist."
        );

        // Add a player to the specified team
        teamsInfo[_teamName].players.push(_player);
        teamsInfo[_teamName].playerIndexMap[_player] = teamsInfo[_teamName].players.length - 1;
    }

    // ------------------------------------------------------------------------
    // Remove a specific team (the team must be empty of players)
    // ------------------------------------------------------------------------
    function kickTeam(string _teamName) external onlyRegistrationState onlyPizzaCoin {
        require(
            _teamName.isNotEmpty(),
            "'_teamName' might not be empty."
        );

        require(
            teamsInfo[_teamName].wasCreated,
            "Cannot find the specified team."
        );

        uint256 totalPlayers = __getTotalPlayersInTeam(_teamName);

        // The team can be removed if and only if it has 0 player left
        if (totalPlayers != 0) {
            revert("The specified team is not empty.");
        }

        uint256 teamIndex = getTeamIndex(_teamName);

        // Remove the specified team from an array by moving 
        // the last array element to the element pointed by teamIndex
        teams[teamIndex] = teams[teams.length - 1];

        // Since we have just moved the last array element to 
        // the element pointed by teamIndex, we have to update 
        // the newly moved team's index to teamIndex too
        teamsInfo[teams[teamIndex]].index = teamIndex;

        // Remove the last element
        teams.length--;

        // Remove the specified team from a mapping
        delete teamsInfo[_teamName];
    }

    // ------------------------------------------------------------------------
    // Remove a specific player from a particular team
    // ------------------------------------------------------------------------
    function kickPlayerOutOfTeam(address _player, string _teamName) 
        external onlyRegistrationState onlyPizzaCoin 
    {
        require(
            _player != address(0),
            "'_player' contains an invalid address."
        );

        require(
            _teamName.isNotEmpty(),
            "'_teamName' might not be empty."
        );

        require(
            teamsInfo[_teamName].wasCreated,
            "Cannot find the specified team."
        );

        bool found;
        uint256 playerIndex;

        (found, playerIndex) = getPlayerIndexInTeam(_player, _teamName);
        if (!found) {
            revert("Cannot find the specified player in a given team.");
        }

        // Remove the specified player from an array by moving 
        // the last array element to the element pointed by playerIndex
        teamsInfo[_teamName].players[playerIndex] = teamsInfo[_teamName].players[teamsInfo[_teamName].players.length - 1];

        // Since we have just moved the last array element to 
        // the element pointed by playerIndex, we have to update 
        // the newly moved player's index to playerIndex too
        teamsInfo[_teamName].playerIndexMap[teamsInfo[_teamName].players[playerIndex]] = playerIndex;

        // Remove the last element
        teamsInfo[_teamName].players.length--;

        // Remove the specified player from a mapping
        delete teamsInfo[_teamName].playerIndexMap[_player];
    }

    // ------------------------------------------------------------------------
    // Get an index pointing to a specific player on the array 'players' of a given team
    // ------------------------------------------------------------------------
    function getPlayerIndexInTeam(address _player, string _teamName) 
        internal view 
        returns (
            bool _found, 
            uint256 _playerIndex
        ) 
    {
        assert(_player != address(0));
        assert(_teamName.isNotEmpty());
        assert(teamsInfo[_teamName].wasCreated);

        _playerIndex = teamsInfo[_teamName].playerIndexMap[_player];
        _found = teamsInfo[_teamName].players[_playerIndex] == _player;
    }

    // ------------------------------------------------------------------------
    // Get a total number of players in the specified team (external)
    // ------------------------------------------------------------------------
    function getTotalPlayersInTeam(string _teamName) external view returns (uint256 _total) {
        return __getTotalPlayersInTeam(_teamName);
    }

    // ------------------------------------------------------------------------
    // Get a total number of players in the specified team (internal)
    // ------------------------------------------------------------------------
    function __getTotalPlayersInTeam(string _teamName) internal view returns (uint256 _total) {
        require(
            _teamName.isNotEmpty(),
            "'_teamName' might not be empty."
        );

        require(
            teamsInfo[_teamName].wasCreated,
            "Cannot find the specified team."
        );

        return teamsInfo[_teamName].players.length;
    }

    // ------------------------------------------------------------------------
    // Get a player address in the specified team at the given player index
    // ------------------------------------------------------------------------
    function getPlayerInTeamAtIndex(string _teamName, uint256 _playerIndex) 
        external view 
        returns (
            bool _endOfList, 
            address _player
        ) 
    {
        require(
            _teamName.isNotEmpty(),
            "'_teamName' might not be empty."
        );

        require(
            teamsInfo[_teamName].wasCreated,
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
    // Get an index pointing to the specified team on the array 'teams'
    // ------------------------------------------------------------------------
    function getTeamIndex(string _teamName) internal view returns (uint256 _teamIndex) {
        assert(_teamName.isNotEmpty());
        assert(teamsInfo[_teamName].wasCreated);
        return teamsInfo[_teamName].index;
    }

    // ------------------------------------------------------------------------
    // Get a total number of teams
    // ------------------------------------------------------------------------
    function getTotalTeams() external view returns (uint256 _total) {
        return teams.length;
    }

    // ------------------------------------------------------------------------
    // Get a team info at the specified index '_teamIndex'
    // ------------------------------------------------------------------------
    function getTeamInfoAtIndex(uint256 _teamIndex) 
        external view
        returns (
            bool _endOfList,
            string _teamName,
            uint256 _totalVoted
        ) 
    {
        if (_teamIndex >= teams.length) {
            _endOfList = true;
            _teamName = "";
            _totalVoted = 0;
            return;
        } 

        string memory teamName = teams[_teamIndex];
        _endOfList = false;
        _teamName = teamName;
        _totalVoted = teamsInfo[teamName].totalVoted;
    }

    // ------------------------------------------------------------------------
    // Get voting points of the specified team
    // ------------------------------------------------------------------------
    function getVotingPointsOfTeam(string _teamName) external view returns (uint256 _totalVoted) {
        require(
            _teamName.isNotEmpty(),
            "'_teamName' might not be empty."
        );

        require(
            teamsInfo[_teamName].wasCreated,
            "Cannot find the specified team."
        );

        return teamsInfo[_teamName].totalVoted;
    }

    // ------------------------------------------------------------------------
    // Get a total number of voters to the specified team
    // ------------------------------------------------------------------------
    function getTotalVotersToTeam(string _teamName) external view returns (uint256 _total) {
        require(
            _teamName.isNotEmpty(),
            "'_teamName' might not be empty."
        );

        require(
            teamsInfo[_teamName].wasCreated,
            "Cannot find the specified team."
        );

        return teamsInfo[_teamName].voters.length;
    }

    // ------------------------------------------------------------------------
    // Get a voting result to the specified team pointed by '_voterIndex'
    // ------------------------------------------------------------------------
    function getVotingResultToTeamAtIndex(string _teamName, uint256 _voterIndex) 
        external view
        returns (
            bool _endOfList,
            address _voter,
            uint256 _voteWeight
        ) 
    {
        require(
            _teamName.isNotEmpty(),
            "'_teamName' might not be empty."
        );

        require(
            teamsInfo[_teamName].wasCreated,
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
    // Allow a staff or player to give a vote to the specified team
    // ------------------------------------------------------------------------
    function voteToTeam(address _voter, string _teamName, uint256 _votingWeight) 
        external onlyVotingState onlyPizzaCoin 
    {
        require(
            _voter != address(0),
            "'_voter' contains an invalid address."
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
            teamsInfo[_teamName].wasCreated,
            "Cannot find the specified team."
        );

        // If teamsInfo[_teamName].votesWeight[_voter] > 0 is true, this implies that 
        // the voter used to give a vote to the specified team previously
        if (teamsInfo[_teamName].votesWeight[_voter] == 0) {
            // The voter has never given a vote to the specified team before
            // We, therefore, have to add a new voter to the 'voters' array
            // of the specified team
            teamsInfo[_teamName].voters.push(_voter);
        }

        teamsInfo[_teamName].votesWeight[_voter] = teamsInfo[_teamName].votesWeight[_voter].add(_votingWeight);
        teamsInfo[_teamName].totalVoted = teamsInfo[_teamName].totalVoted.add(_votingWeight);
    }

    // ------------------------------------------------------------------------
    // Find maximum voting points from all teams after voting is finished (external)
    // ------------------------------------------------------------------------
    function getMaxTeamVotingPoints() external view onlyVotingFinishedState returns (uint256 _maxTeamVotingPoints) {
        return __getMaxTeamVotingPoints();
    }

    // ------------------------------------------------------------------------
    // Find maximum voting points from all teams after voting is finished (internal)
    // ------------------------------------------------------------------------
    function __getMaxTeamVotingPoints() internal view onlyVotingFinishedState returns (uint256 _maxTeamVotingPoints) {
        _maxTeamVotingPoints = 0;
        for (uint256 i = 0; i < teams.length; i++) {
            // Find new maximum points
            if (teamsInfo[teams[i]].totalVoted > _maxTeamVotingPoints) {
                _maxTeamVotingPoints = teamsInfo[teams[i]].totalVoted;
            }
        }
    }

    // ------------------------------------------------------------------------
    // Get a total number of winning teams after voting is finished
    // It is possible to have several teams that get equal maximum voting points 
    // ------------------------------------------------------------------------
    function getTotalWinningTeams() external view onlyVotingFinishedState returns (uint256 _total) {
        uint256 maxTeamVotingPoints = __getMaxTeamVotingPoints();

        _total = 0;
        for (uint256 i = 0; i < teams.length; i++) {
            // Count up the winning teams
            if (teamsInfo[teams[i]].totalVoted == maxTeamVotingPoints) {
                _total++;
            }
        }
    }

    // ------------------------------------------------------------------------
    // Get the first found winning team by starting the search at '_startSearchingIndex'
    // It is possible to have several teams that get equal maximum voting points 
    // ------------------------------------------------------------------------
    function getFirstFoundWinningTeam(uint256 _startSearchingIndex) 
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

            // Find a winning team
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