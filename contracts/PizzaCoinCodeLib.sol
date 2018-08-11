/*
* Copyright (c) 2018, Phuwanai Thummavet (serial-coder). All rights reserved.
* Github: https://github.com/serial-coder
* Contact us: mr[dot]thummavet[at]gmail[dot]com
*/

pragma solidity ^0.4.23;

import "./BasicStringUtils.sol";
import "./PizzaCoinStaff.sol";
import "./PizzaCoinPlayer.sol";
import "./PizzaCoinTeam.sol";


// ----------------------------------------------------------------------------
// Pizza Coin Code Library #1
// ----------------------------------------------------------------------------
library PizzaCoinCodeLib {
    using BasicStringUtils for string;


    // ------------------------------------------------------------------------
    // Register a new staff
    // ------------------------------------------------------------------------
    function registerStaff(address _staff, string _staffName, address _staffContract) public {
        assert(_staffContract != address(0));

        // Get a contract instance from the deployed address
        IStaffContract staffContractInstance = IStaffContract(_staffContract);

        staffContractInstance.registerStaff(_staff, _staffName);
    }

    // ------------------------------------------------------------------------
    // Remove a specific staff
    // ------------------------------------------------------------------------
    function kickStaff(address _staff, address _staffContract) public {
        assert(_staffContract != address(0));

        // Get a contract instance from the deployed address
        IStaffContract staffContractInstance = IStaffContract(_staffContract);

        staffContractInstance.kickStaff(_staff);
    }

    // ------------------------------------------------------------------------
    // Register a player
    // ------------------------------------------------------------------------
    function registerPlayer(string _playerName, string _teamName, address _playerContract, address _teamContract) public {
        assert(_playerContract != address(0));
        assert(_teamContract != address(0));
        
        address player = msg.sender;

        // Get contract instances from the deployed addresses
        IPlayerContract playerContractInstance = IPlayerContract(_playerContract);
        ITeamContract teamContractInstance = ITeamContract(_teamContract);

        playerContractInstance.registerPlayer(player, _playerName, _teamName);

        // Add a player to a team that he/she is associating with
        teamContractInstance.registerPlayerToTeam(player, _teamName);
    }

    // ------------------------------------------------------------------------
    // Team leader creates a team
    // ------------------------------------------------------------------------
    function createTeam(string _teamName, string _creatorName, address _playerContract, address _teamContract) public {
        assert(_playerContract != address(0));
        assert(_teamContract != address(0));

        // Get a contract instance from the deployed address
        ITeamContract teamContractInstance = ITeamContract(_teamContract);
        
        // Create a new team
        teamContractInstance.createTeam(_teamName);

        // Register a creator to a team as team leader
        registerPlayer(_creatorName, _teamName, _playerContract, _teamContract);
    }

    // ------------------------------------------------------------------------
    // Allow only a staff transfer the state from Initial to Registration and
    // revert a transaction if the contract as well as its children contracts 
    // do not get initialized completely
    // ------------------------------------------------------------------------
    function isContractCompletelyInitialized(
        address _staff, 
        address _staffContract,
        address _playerContract,
        address _teamContract
    ) 
    public view
    {   
        require(
            _staffContract != address(0),
            "The staff contract did not get initialized"
        );

        require(
            _playerContract != address(0),
            "The player contract did not get initialized"
        );

        require(
            _teamContract != address(0),
            "The team contract did not get initialized"
        );

        // Get a contract instance from the deployed address
        IStaffContract staffContractInstance = IStaffContract(_staffContract);

        // Only a staff is allowed to call this function
        require(
            staffContractInstance.isStaff(_staff),
            "This address is not a staff."
        );
    }

    // ------------------------------------------------------------------------
    // Remove the first found player of a particular team 
    // (start searching at _startSearchingIndex)
    // ------------------------------------------------------------------------
    function kickFirstFoundPlayerInTeam(
        string _teamName, 
        uint256 _startSearchingIndex,
        address _playerContract,
        address _teamContract
    ) 
        public returns (uint256 _nextStartSearchingIndex) 
    {
        assert(_playerContract != address(0));
        assert(_teamContract != address(0));

        // Get contract instances from the deployed addresses
        IPlayerContract playerContractInstance = IPlayerContract(_playerContract);
        ITeamContract teamContractInstance = ITeamContract(_teamContract);

        // Get the array length of players in the specific team, 
        // including all ever removal players
        uint256 noOfAllEverTeamPlayers = teamContractInstance.getArrayLengthOfPlayersInTeam(_teamName);

        require(
            _startSearchingIndex < noOfAllEverTeamPlayers,
            "'_startSearchingIndex' is out of bound."
        );

        _nextStartSearchingIndex = noOfAllEverTeamPlayers;

        for (uint256 i = _startSearchingIndex; i < noOfAllEverTeamPlayers; i++) {
            bool endOfList;  // used as a temporary variable
            address player;

            (endOfList, player) = teamContractInstance.getPlayerInTeamAtIndex(_teamName, i);
            
            // player == address(0) if a player was kicked previously
            if (player != address(0) && playerContractInstance.isPlayerInTeam(player, _teamName)) {
                // Remove a specific player
                kickPlayer(player, _teamName, _playerContract, _teamContract);

                // Start next searching at the next array element
                _nextStartSearchingIndex = i + 1;
                return;     
            }
        }
    }
    
    // ------------------------------------------------------------------------
    // Remove a specific player from a particular team
    // ------------------------------------------------------------------------
    function kickPlayer(address _player, string _teamName, address _playerContract, address _teamContract) public {
        assert(_playerContract != address(0));
        assert(_teamContract != address(0));

        // Get contract instances from the deployed addresses
        IPlayerContract playerContractInstance = IPlayerContract(_playerContract);
        ITeamContract teamContractInstance = ITeamContract(_teamContract);

        // Remove a player from the player list
        playerContractInstance.kickPlayer(_player, _teamName);

        // Remove a player from the player list of the specified team
        teamContractInstance.kickPlayerOutOffTeam(_player, _teamName);
    }

    // ------------------------------------------------------------------------
    // Remove a specific team (the team must be empty of players)
    // ------------------------------------------------------------------------
    function kickTeam(string _teamName, address _teamContract) public {
        assert(_teamContract != address(0));

        // Get a contract instance from the deployed address
        ITeamContract teamContractInstance = ITeamContract(_teamContract);

        teamContractInstance.kickTeam(_teamName);
    }

    // ------------------------------------------------------------------------
    // Allow any staff or any player in other different teams to vote to a team
    // ------------------------------------------------------------------------
    function voteTeam(
        string _teamName, 
        uint256 _votingWeight, 
        address _staffContract,
        address _playerContract,
        address _teamContract
    ) 
        public returns (uint256 _totalVoted) 
    {

        assert(_staffContract != address(0));
        assert(_teamContract != address(0));

        // Get contract instances from the deployed addresses
        IStaffContract staffContractInstance = IStaffContract(_staffContract);
        ITeamContract teamContractInstance = ITeamContract(_teamContract);

        require(
            _teamName.isNotEmpty(),
            "'_teamName' might not be empty."
        );

        require(
            _votingWeight > 0,
            "'_votingWeight' must be larger than 0."
        );

        require(
            teamContractInstance.doesTeamExist(_teamName),
            "Cannot find the specified team."
        );

        if (staffContractInstance.isStaff(msg.sender)) {
            // Voter is a staff
            return voteTeamByStaff(_teamName, _votingWeight, _staffContract, _teamContract);
        }
        else {
            // Voter is a team player
            return voteTeamByDifferentTeamPlayer(_teamName, _votingWeight, _playerContract, _teamContract);
        }
    }

    // ------------------------------------------------------------------------
    // Vote for a team by a staff
    // ------------------------------------------------------------------------
    function voteTeamByStaff(
        string _teamName, 
        uint256 _votingWeight,
        address _staffContract,
        address _teamContract
    ) 
        internal returns (uint256 _totalVoted) 
    {

        assert(_staffContract != address(0));
        assert(_teamContract != address(0));

        // Get contract instances from the deployed addresses
        IStaffContract staffContractInstance = IStaffContract(_staffContract);
        ITeamContract teamContractInstance = ITeamContract(_teamContract);

        address voter = msg.sender;
        assert(_teamName.isNotEmpty());
        assert(_votingWeight > 0);
        assert(teamContractInstance.doesTeamExist(_teamName));
        assert(staffContractInstance.isStaff(voter));

        require(
            _votingWeight <= staffContractInstance.getTokenBalance(voter),
            "Insufficient voting balance."
        );

        // Staff commits to vote to the team
        staffContractInstance.commitToVote(_teamName, voter, _votingWeight);
        teamContractInstance.voteToTeam(_teamName, voter, _votingWeight);

        // Get a current voting point for the team
        _totalVoted = teamContractInstance.getVotingPointForTeam(_teamName);
    }

    // ------------------------------------------------------------------------
    // Vote for a team by a different team player
    // ------------------------------------------------------------------------
    function voteTeamByDifferentTeamPlayer(
        string _teamName, 
        uint256 _votingWeight,
        address _playerContract,
        address _teamContract
    ) 
        internal returns (uint256 _totalVoted) 
    {
        assert(_playerContract != address(0));
        assert(_teamContract != address(0));

        // Get contract instances from the deployed addresses
        IPlayerContract playerContractInstance = IPlayerContract(_playerContract);
        ITeamContract teamContractInstance = ITeamContract(_teamContract);
        
        address voter = msg.sender;
        assert(_teamName.isNotEmpty());
        assert(_votingWeight > 0);
        assert(teamContractInstance.doesTeamExist(_teamName));
        assert(playerContractInstance.isPlayer(voter));

        require(
            playerContractInstance.isPlayerInTeam(voter, _teamName) == false,
            "A player is not permitted to vote to his/her own team."
        );

        require(
            _votingWeight <= playerContractInstance.getTokenBalance(voter),
            "Insufficient voting balance."
        );

        // Player commits to vote to the team
        playerContractInstance.commitToVote(_teamName, voter, _votingWeight);
        teamContractInstance.voteToTeam(_teamName, voter, _votingWeight);

        // Get a current voting point for the team
        _totalVoted = teamContractInstance.getVotingPointForTeam(_teamName);
    }
}