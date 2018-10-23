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
// Interface for exporting external functions of PizzaCoinPlayer contract
// ------------------------------------------------------------------------
interface IPlayerContract {
    function lockRegistration() external;
    function startVoting() external;
    function stopVoting() external;
    function getTotalSupply() external view returns (uint256 _totalSupply);
    function isPlayer(address _user) external view returns (bool _bPlayer);
    function isPlayerInTeam(address _user, string _teamName) external view returns (bool _bTeamPlayer);
    function getPlayerName(address _player) external view returns (string _name);
    function getTeamNamePlayerJoined(address _player) external view returns (string _name);
    function registerPlayer(address _player, string _playerName, string _teamName) external;
    function kickPlayer(address _player, string _teamName) external;
    function getTotalPlayers() external view returns (uint256 _total);
    function getPlayerInfoAtIndex(uint256 _playerIndex) 
        external view
        returns (
            bool _endOfList,
            address _player,
            string _name,
            uint256 _tokenBalance,
            string _teamName
        );
    function getTotalTeamsVotedByPlayer(address _player) external view returns (uint256 _total);
    function getVotingResultByPlayerAtIndex(address _player, uint256 _votingIndex) 
        external view
        returns (
            bool _endOfList,
            string _team,
            uint256 _voteWeight
        );
    function getTokenBalance(address _player) external view returns (uint256 _tokenBalance);
    function commitToVote(address _player, string _teamName, uint256 _votingWeight) external;
}


// ----------------------------------------------------------------------------
// Pizza Coin Player Contract
// ----------------------------------------------------------------------------
contract PizzaCoinPlayer is IPlayerContract, Owned {
    /*
    * Owner of the contract is PizzaCoin contract, 
    * not a project deployer who is PizzaCoin owner
    */

    using SafeMath for uint256;
    using BasicStringUtils for string;


    struct PlayerInfo {
        // This is used to reduce potential gas cost consumption when kicking a player
        uint256 index;  // A pointing index to a particular player on the 'players' array

        string name;
        bool wasRegistered;    // Check if a specific player is being registered
        string teamName;       // A team this player associates with
        uint256 tokenBalance;  // Amount of tokens left for voting
        string[] teamsVoted;   // A collection of teams voted by this player
        
        // mapping(team => votingWeight)
        mapping(string => uint256) votesWeight;  // Teams with voting weight approved by this player
    }

    address[] private players;
    mapping(address => PlayerInfo) private playersInfo;  // mapping(player => PlayerInfo)

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
    // Determine if _user is a player or not (external)
    // ------------------------------------------------------------------------
    function isPlayer(address _user) external view returns (bool _bPlayer) {
        return __isPlayer(_user);
    }

    // ------------------------------------------------------------------------
    // Determine if _user is a player or not (internal)
    // ------------------------------------------------------------------------
    function __isPlayer(address _user) internal view returns (bool _bPlayer) {
        require(
            _user != address(0),
            "'_user' contains an invalid address."
        );

        return playersInfo[_user].wasRegistered;
    }

    // ------------------------------------------------------------------------
    // Determine if _user is a player in the specified _teamName or not (external)
    // ------------------------------------------------------------------------
    function isPlayerInTeam(address _user, string _teamName) external view returns (bool _bTeamPlayer) {
        return __isPlayerInTeam(_user, _teamName);
    }

    // ------------------------------------------------------------------------
    // Determine if _user is a player in the specified _teamName or not (internal)
    // ------------------------------------------------------------------------
    function __isPlayerInTeam(address _user, string _teamName) internal view returns (bool _bTeamPlayer) {
        require(
            _user != address(0),
            "'_user' contains an invalid address."
        );

        require(
            _teamName.isNotEmpty(),
            "'_teamName' might not be empty."
        );

        return (
            playersInfo[_user].wasRegistered && 
            playersInfo[_user].teamName.isEqual(_teamName)
        );
    }

    // ------------------------------------------------------------------------
    // Get a player name
    // ------------------------------------------------------------------------
    function getPlayerName(address _player) external view returns (string _name) {
        require(
            _player != address(0),
            "'_player' contains an invalid address."
        );

        require(
            __isPlayer(_player),
            "Cannot find the specified player."
        );

        return playersInfo[_player].name;
    }

    // ------------------------------------------------------------------------
    // Get a team name the player associates with
    // ------------------------------------------------------------------------
    function getTeamNamePlayerJoined(address _player) external view returns (string _name) {
        require(
            _player != address(0),
            "'_player' contains an invalid address."
        );

        require(
            __isPlayer(_player),
            "Cannot find the specified player."
        );

        return playersInfo[_player].teamName;
    }

    // ------------------------------------------------------------------------
    // Register a player
    // ------------------------------------------------------------------------
    function registerPlayer(address _player, string _playerName, string _teamName) 
        external onlyRegistrationState onlyPizzaCoin 
    {
        require(
            _player != address(0),
            "'_player' contains an invalid address."
        );

        require(
            _playerName.isNotEmpty(),
            "'_playerName' might not be empty."
        );

        require(
            _teamName.isNotEmpty(),
            "'_teamName' might not be empty."
        );

        require(
            playersInfo[_player].wasRegistered == false,
            "The specified player was registered already."
        );

        // Register a new player
        players.push(_player);
        playersInfo[_player] = PlayerInfo({
            wasRegistered: true,
            name: _playerName,
            tokenBalance: voterInitialTokens,
            teamName: _teamName,
            teamsVoted: new string[](0),
            /*
                Omit 'votesWeight'
            */
            index: players.length - 1
        });

        totalSupply = totalSupply.add(voterInitialTokens);
    }

    // ------------------------------------------------------------------------
    // Remove a specific player from a particular team
    // ------------------------------------------------------------------------
    function kickPlayer(address _player, string _teamName) external onlyRegistrationState onlyPizzaCoin {
        require(
            _player != address(0),
            "'_player' contains an invalid address."
        );

        require(
            _teamName.isNotEmpty(),
            "'_teamName' might not be empty."
        );
        
        require(
            __isPlayerInTeam(_player, _teamName),
            "Cannot find the specified player in a given team."
        );

        uint256 playerIndex = getPlayerIndex(_player);

        // Remove the specified player from an array by moving 
        // the last array element to the element pointed by playerIndex
        players[playerIndex] = players[players.length - 1];

        // Since we have just moved the last array element to 
        // the element pointed by playerIndex, we have to update 
        // the newly moved player's index to playerIndex too
        playersInfo[players[playerIndex]].index = playerIndex;

        // Remove the last element
        players.length--;

        // Remove the specified player from a mapping
        delete playersInfo[_player];

        totalSupply = totalSupply.sub(voterInitialTokens);
    }

    // ------------------------------------------------------------------------
    // Get an index pointing to the specified player on the array 'players'
    // ------------------------------------------------------------------------
    function getPlayerIndex(address _player) internal view returns (uint256 _playerIndex) {
        assert(_player != address(0));
        assert(playersInfo[_player].wasRegistered);
        return playersInfo[_player].index;
    }

    // ------------------------------------------------------------------------
    // Get a total number of players
    // ------------------------------------------------------------------------
    function getTotalPlayers() external view returns (uint256 _total) {
        return players.length;
    }

    // ------------------------------------------------------------------------
    // Get a player info at the specified index '_playerIndex'
    // ------------------------------------------------------------------------
    function getPlayerInfoAtIndex(uint256 _playerIndex) 
        external view
        returns (
            bool _endOfList,
            address _player,
            string _name,
            uint256 _tokenBalance,
            string _teamName
        )
    {
        if (_playerIndex >= players.length) {
            _endOfList = true;
            _player = address(0);
            _name = "";
            _tokenBalance = 0;
            _teamName = "";
            return;
        }  

        address player = players[_playerIndex];
        _endOfList = false;
        _player = player;
        _name = playersInfo[player].name;
        _tokenBalance = playersInfo[player].tokenBalance;
        _teamName = playersInfo[player].teamName;
    }

    // ------------------------------------------------------------------------
    // Get a total number of teams voted by the specified player
    // ------------------------------------------------------------------------
    function getTotalTeamsVotedByPlayer(address _player) external view returns (uint256 _total) {
        require(
            _player != address(0),
            "'_player' contains an invalid address."
        );
        
        require(
            playersInfo[_player].wasRegistered,
            "Cannot find the specified player."
        );

        return playersInfo[_player].teamsVoted.length;
    }

    // ------------------------------------------------------------------------
    // Get a voting result to a team pointed by _votingIndex committed by the specified player
    // ------------------------------------------------------------------------
    function getVotingResultByPlayerAtIndex(address _player, uint256 _votingIndex) 
        external view
        returns (
            bool _endOfList,
            string _team,
            uint256 _voteWeight
        ) 
    {
        require(
            _player != address(0),
            "'_player' contains an invalid address."
        );

        require(
            playersInfo[_player].wasRegistered,
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
    // Get a token balance of the specified player
    // ------------------------------------------------------------------------
    function getTokenBalance(address _player) external view returns (uint256 _tokenBalance) {
        require(
            _player != address(0),
            "'_player' contains an invalid address."
        );

        require(
            playersInfo[_player].wasRegistered,
            "Cannot find the specified player."
        );

        return playersInfo[_player].tokenBalance;
    }

    // ------------------------------------------------------------------------
    // Allow a player vote to other different teams
    // ------------------------------------------------------------------------
    function commitToVote(address _player, string _teamName, uint256 _votingWeight) 
        external onlyVotingState onlyPizzaCoin 
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
            _votingWeight > 0,
            "'_votingWeight' must be larger than 0."
        );

        require(
            playersInfo[_player].wasRegistered,
            "Cannot find the specified player."
        );

        require(
            playersInfo[_player].teamName.isEqual(_teamName) == false,
            "A player is not permitted to vote to his/her own team."
        );

        require(
            _votingWeight <= playersInfo[_player].tokenBalance,
            "Insufficient voting balance."
        );

        playersInfo[_player].tokenBalance = playersInfo[_player].tokenBalance.sub(_votingWeight);

        // If playersInfo[_player].votesWeight[_teamName] > 0 is true, this implies that 
        // the player used to give a vote to the specified team previously
        if (playersInfo[_player].votesWeight[_teamName] == 0) {
            // The player has never given a vote to the specified team before
            // We, therefore, have to add a new team to the 'teamsVoted' array
            playersInfo[_player].teamsVoted.push(_teamName);
        }

        playersInfo[_player].votesWeight[_teamName] = playersInfo[_player].votesWeight[_teamName].add(_votingWeight);
    }
}