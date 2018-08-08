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
    function getVotingPointForTeam(string _teamName) external view returns (uint256 _totalVoted);
    function getTotalVotersToTeam(string _teamName) external view returns (uint256 _total);
    function getVoteResultAtIndexToTeam(string _teamName, uint256 _voterIndex) 
        external view
        returns (
            bool _endOfList,
            address _voter,
            uint256 _voteWeight
        );
    function voteToTeam(string _teamName, address _voter, uint256 _votingWeight) external;
    function getMaxTeamVotingPoint() external view returns (uint256 _maxTeamVotingPoint);
    function getTotalWinnerTeams() external view returns (uint256 _total);
    function getFirstFoundWinnerTeam(uint256 _startSearchingIndex) 
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
        bool wasCreated;    // Check if the team was created or not (for uniqueness)
        address[] players;  // A list of team members (the first list member is the team leader who creates the team)
        address[] voters;   // A list of staffs and other teams' members who gave votes to this team

        // mapping(voter => votes)
        mapping(address => uint256) votesWeight;  // A collection of team voting weights from each voter (i.e., staffs + other teams' members)
        
        uint256 totalVoted;  // Total voting weight got from all voters

        // The following are used to reduce the potential gas cost consumption when kicking a team and/or a player in a team
        uint256 id;            // A pointing index to a particular team on the 'teams' array
        uint256 totalPlayers;  // Total players in a team
        mapping(address => uint256) playerIdMap;  // mapping(player => id)
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
    // Team leader creates a team
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
            id: teams.length - 1,
            totalPlayers: 0
            /*
                Omit 'playerIdMap'
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

        // Add a player to a team that he/she is associating with
        teamsInfo[_teamName].players.push(_player);

        teamsInfo[_teamName].totalPlayers = teamsInfo[_teamName].totalPlayers.add(1);
        teamsInfo[_teamName].playerIdMap[_player] = teamsInfo[_teamName].players.length - 1;
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
            revert("Team is not empty.");
        }

        bool found;
        uint256 teamIndex;

        (found, teamIndex) = getTeamIndex(_teamName);
        if (!found) {
            revert("Cannot find the specified team.");
        }

        // Reset the element pointed by teamIndex to 0. However,
        // that array element never get really removed. (beware!!)
        delete teams[teamIndex];

        // Remove the specified team from a mapping
        delete teamsInfo[_teamName];
    }

    // ------------------------------------------------------------------------
    // Remove a specific player from a particular team
    // ------------------------------------------------------------------------
    function kickPlayerOutOffTeam(address _player, string _teamName) 
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

        // Reset the element pointed by playerIndex to 0. However,
        // that array element never get really removed. (beware!!)
        delete teamsInfo[_teamName].players[playerIndex];
        teamsInfo[_teamName].totalPlayers = teamsInfo[_teamName].totalPlayers.sub(1);
    }

    // ------------------------------------------------------------------------
    // Get an index pointed to a specific player on the mapping 'playerIdMap' in a given team
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

        _playerIndex = teamsInfo[_teamName].playerIdMap[_player];
        _found = teamsInfo[_teamName].players[_playerIndex] == _player;
    }

    // ------------------------------------------------------------------------
    // Get an array length of players in a specified team (including all ever removal players)
    // ------------------------------------------------------------------------
    function getArrayLengthOfPlayersInTeam(string _teamName) external view returns (uint256 _length) {
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
            _teamName.isNotEmpty(),
            "'_teamName' might not be empty."
        );

        require(
            teamsInfo[_teamName].wasCreated,
            "Cannot find the specified team."
        );

        _total = teamsInfo[_teamName].totalPlayers;
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
            _teamName.isNotEmpty(),
            "'_teamName' might not be empty."
        );

        require(
            teamsInfo[_teamName].wasCreated,
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

            // Player might not be removed before
            if (player != address(0)) {
                _endOfList = false;
                _nextStartSearchingIndex = i + 1;
                _player = player;
                return;
            }
        }
    }

    // ------------------------------------------------------------------------
    // Get a player in a specified team at a given index (including all ever removal players)
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
    // Get an index pointed to a specific team on the mapping 'teamsInfo'
    // ------------------------------------------------------------------------
    function getTeamIndex(string _teamName) internal view returns (bool _found, uint256 _teamIndex) {
        assert(_teamName.isNotEmpty());

        _found = teamsInfo[_teamName].wasCreated;
        _teamIndex = teamsInfo[_teamName].id;
    }

    // ------------------------------------------------------------------------
    // Get a total number of teams
    // ------------------------------------------------------------------------
    function getTotalTeams() external view returns (uint256 _total) {
        _total = 0;
        for (uint256 i = 0; i < teams.length; i++) {
            // Team might not be removed before
            if (teams[i].isNotEmpty() && teamsInfo[teams[i]].wasCreated) {
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

            // Team might not be removed before
            if (teamName.isNotEmpty() && teamsInfo[teamName].wasCreated) {
                _endOfList = false;
                _nextStartSearchingIndex = i + 1;
                _teamName = teamName;
                _totalVoted = teamsInfo[teamName].totalVoted;
                return;
            }
        }
    }

    // ------------------------------------------------------------------------
    // Get a voting point for a specified team
    // ------------------------------------------------------------------------
    function getVotingPointForTeam(string _teamName) external view returns (uint256 _totalVoted) {
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
    // Get a total number of all voters to a specified team
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
    // Get a voting result to a specified team pointed by _voterIndex
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
    // Allow a staff or a player to give a vote to the specified team
    // ------------------------------------------------------------------------
    function voteToTeam(string _teamName, address _voter, uint256 _votingWeight) 
        external onlyVotingState onlyPizzaCoin 
    {
        require(
            _teamName.isNotEmpty(),
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
            teamsInfo[_teamName].wasCreated,
            "Cannot find the specified team."
        );

        // If teamsInfo[_teamName].votesWeight[_voter] > 0 is true, this implies that 
        // the voter was used to give a vote to the specified team previously
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
    // Find a maximum voting point from each team after voting is finished (external)
    // ------------------------------------------------------------------------
    function getMaxTeamVotingPoint() external view onlyVotingFinishedState returns (uint256 _maxTeamVotingPoint) {
        return __getMaxTeamVotingPoint();
    }

    // ------------------------------------------------------------------------
    // Find a maximum voting point from each team after voting is finished (internal)
    // ------------------------------------------------------------------------
    function __getMaxTeamVotingPoint() internal view onlyVotingFinishedState returns (uint256 _maxTeamVotingPoint) {
        _maxTeamVotingPoint = 0;
        for (uint256 i = 0; i < teams.length; i++) {
            // Team might not be removed before
            if (teams[i].isNotEmpty() && teamsInfo[teams[i]].wasCreated) {
                // Find a new maximum point
                if (teamsInfo[teams[i]].totalVoted > _maxTeamVotingPoint) {
                    _maxTeamVotingPoint = teamsInfo[teams[i]].totalVoted;
                }
            }
        }
    }

    // ------------------------------------------------------------------------
    // Get a total number of winner teams after voting is finished
    // It is possible to have several teams that get the equal maximum voting points 
    // ------------------------------------------------------------------------
    function getTotalWinnerTeams() external view onlyVotingFinishedState returns (uint256 _total) {
        uint256 maxTeamVotingPoint = __getMaxTeamVotingPoint();

        _total = 0;
        for (uint256 i = 0; i < teams.length; i++) {
            // Team might not be removed before
            if (teams[i].isNotEmpty() && teamsInfo[teams[i]].wasCreated) {
                // Count the winner teams up
                if (teamsInfo[teams[i]].totalVoted == maxTeamVotingPoint) {
                    _total++;
                }
            }
        }
    }

    // ------------------------------------------------------------------------
    // Get the first found winner team
    // (start searching at _startSearchingIndex)
    // It is possible to have several teams that get the equal maximum voting points 
    // ------------------------------------------------------------------------
    function getFirstFoundWinnerTeam(uint256 _startSearchingIndex) 
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

        uint256 maxTeamVotingPoint = __getMaxTeamVotingPoint();
        for (uint256 i = _startSearchingIndex; i < teams.length; i++) {
            string memory teamName = teams[i];

            // Team might not be removed before
            if (teamName.isNotEmpty() && teamsInfo[teamName].wasCreated) {
                // Find a winner team
                if (teamsInfo[teamName].totalVoted == maxTeamVotingPoint) {
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