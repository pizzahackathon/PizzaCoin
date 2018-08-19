/*
* Copyright (c) 2018, Phuwanai Thummavet (serial-coder). All rights reserved.
* Github: https://github.com/serial-coder
* Contact us: mr[dot]thummavet[at]gmail[dot]com
*/

pragma solidity ^0.4.23;


// ----------------------------------------------------------------------------
// SafeMath Library
// https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol
// ----------------------------------------------------------------------------

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20 {
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
        return keccak256(abi.encodePacked(self)) == keccak256(abi.encodePacked(other));
    }

    // ------------------------------------------------------------------------
    // Determine if the string is empty or not
    // ------------------------------------------------------------------------
    function isNotEmpty(string self) internal pure returns (bool bEmpty) {
        bytes memory selfInBytes = bytes(self);
        return selfInBytes.length != 0;
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
    function getFirstFoundStaffInfo(uint256 _startSearchingIndex) 
        external view
        returns (
            bool _endOfList, 
            uint256 _nextStartSearchingIndex,
            address _staff,
            string _name,
            uint256 _tokensBalance
        );
    function getTotalTeamsVotedByStaff(address _staff) external view returns (uint256 _total);
    function getVoteResultAtIndexByStaff(address _staff, uint256 _votingIndex) 
        external view
        returns (
            bool _endOfList,
            string _team,
            uint256 _voteWeight
        );
    function getTokenBalance(address _staff) external view returns (uint256 _tokenBalance);
    function commitToVote(string _teamName, address _staff, uint256 _votingWeight) external;
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
        bool wasRegistered;    // Check if a specific staff is being registered or not
        string name;
        uint256 tokensBalance; // Amount of tokens left for voting
        string[] teamsVoted;   // Record all the teams voted by this staff
        
        // mapping(team => votes)
        mapping(string => uint256) votesWeight;  // A collection of teams with voting weight approved by this staff

        // The following is used to reduce the potential gas cost consumption when kicking a staff
        uint256 id;  // A pointing index to a particular staff on the 'staffs' array
    }

    address[] private staffs;                          // staffs[0] denotes a project deployer (i.e., PizzaCoin's owner)
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
    // Determine if _user is a project deployer (i.e., PizzaCoin's owner) or not
    // ------------------------------------------------------------------------
    function isProjectDeployer(address _user) internal view returns (bool _bDeployer) {
        /*
        * Owner of the contract is PizzaCoin contract, 
        * not a project deployer (or PizzaCoin's owner)
        *
        * Let staffs[0] denote a project deployer (i.e., PizzaCoin's owner)
        */

        assert(_user != address(0));

        address deployer = staffs[0];
        return deployer == _user && staffsInfo[deployer].wasRegistered;
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
            tokensBalance: voterInitialTokens,
            teamsVoted: new string[](0),
            /*
                Omit 'votesWeight'
            */
            id: staffs.length - 1
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

        bool found;
        uint256 staffIndex;

        (found, staffIndex) = getStaffIndex(_staff);
        if (!found) {
            revert("Cannot find the specified staff.");
        }

        // Reset the element pointed by staffIndex to 0. However,
        // that array element never get really removed. (beware!!)
        delete staffs[staffIndex];

        // Remove the specified staff from a mapping
        delete staffsInfo[_staff];

        totalSupply = totalSupply.sub(voterInitialTokens);
    }

    // ------------------------------------------------------------------------
    // Get an index pointed to a specific staff on the mapping 'staffsInfo'
    // ------------------------------------------------------------------------
    function getStaffIndex(address _staff) internal view returns (bool _found, uint256 _staffIndex) {
        assert(_staff != address(0));

        _found = staffsInfo[_staff].wasRegistered;
        _staffIndex = staffsInfo[_staff].id;
    }

    // ------------------------------------------------------------------------
    // Get a total number of staffs
    // ------------------------------------------------------------------------
    function getTotalStaffs() external view returns (uint256 _total) {
        _total = 0;
        for (uint256 i = 0; i < staffs.length; i++) {
            // Staff might not be removed before
            if (staffs[i] != address(0) && staffsInfo[staffs[i]].wasRegistered) {
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

            // Staff might not be removed before
            if (staff != address(0) && staffsInfo[staff].wasRegistered) {
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

        return staffsInfo[_staff].tokensBalance;
    }

    // ------------------------------------------------------------------------
    // Allow a staff give a vote to the specified team
    // ------------------------------------------------------------------------
    function commitToVote(string _teamName, address _staff, uint256 _votingWeight) 
        external onlyVotingState onlyPizzaCoin 
    {
        require(
            _teamName.isNotEmpty(),
            "'_teamName' might not be empty."
        );

        require(
            _staff != address(0),
            "'_staff' contains an invalid address."
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
            _votingWeight <= staffsInfo[_staff].tokensBalance,
            "Insufficient voting balance."
        );

        staffsInfo[_staff].tokensBalance = staffsInfo[_staff].tokensBalance.sub(_votingWeight);

        // If staffsInfo[_staff].votesWeight[_teamName] > 0 is true, this implies that 
        // the staff was used to give a vote to the specified team previously
        if (staffsInfo[_staff].votesWeight[_teamName] == 0) {
            // The staff has never given a vote to the specified team before
            // We, therefore, have to add a new team to the 'teamsVoted' array
            staffsInfo[_staff].teamsVoted.push(_teamName);
        }

        staffsInfo[_staff].votesWeight[_teamName] = staffsInfo[_staff].votesWeight[_teamName].add(_votingWeight);
    }
}


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
    function getFirstFoundPlayerInfo(uint256 _startSearchingIndex) 
        external view
        returns (
            bool _endOfList, 
            uint256 _nextStartSearchingIndex,
            address _player,
            string _name,
            uint256 _tokensBalance,
            string _teamName
        );
    function getTotalTeamsVotedByPlayer(address _player) external view returns (uint256 _total);
    function getVoteResultAtIndexByPlayer(address _player, uint256 _votingIndex) 
        external view
        returns (
            bool _endOfList,
            string _team,
            uint256 _voteWeight
        );
    function getTokenBalance(address _player) external view returns (uint256 _tokenBalance);
    function commitToVote(string _teamName, address _player, uint256 _votingWeight) external;
}


// ----------------------------------------------------------------------------
// Pizza Coin Player Contract
// ----------------------------------------------------------------------------
contract PizzaCoinPlayer is IPlayerContract, Owned {
    /*
    * Owner of the contract is PizzaCoin contract, 
    * not a project deployer (or PizzaCoin's owner)
    */

    using SafeMath for uint256;
    using BasicStringUtils for string;


    struct PlayerInfo {
        bool wasRegistered;    // Check if a specific player is being registered or not
        string name;
        uint256 tokensBalance; // Amount of tokens left for voting
        string teamName;       // A team this player associates with
        string[] teamsVoted;   // Record all the teams voted by this player
        
        // mapping(team => votes)
        mapping(string => uint256) votesWeight;  // A collection of teams with voting weight approved by this player

        // The following is used to reduce the potential gas cost consumption when kicking a player
        uint256 id;  // A pointing index to a particular player on the 'players' array
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
            tokensBalance: voterInitialTokens,
            teamName: _teamName,
            teamsVoted: new string[](0),
            /*
                Omit 'votesWeight'
            */
            id: players.length - 1
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

        bool found;
        uint256 playerIndex;

        (found, playerIndex) = getPlayerIndex(_player);
        if (!found) {
            revert("Cannot find the specified player.");
        }

        // Reset the element pointed by playerIndex to 0. However,
        // that array element never get really removed. (beware!!)
        delete players[playerIndex];

        // Remove the specified player from a mapping
        delete playersInfo[_player];

        totalSupply = totalSupply.sub(voterInitialTokens);
    }

    // ------------------------------------------------------------------------
    // Get an index pointed to a specific player on the mapping 'playersInfo'
    // ------------------------------------------------------------------------
    function getPlayerIndex(address _player) internal view returns (bool _found, uint256 _playerIndex) {
        assert(_player != address(0));

        _found = playersInfo[_player].wasRegistered;
        _playerIndex = playersInfo[_player].id;
    }

    // ------------------------------------------------------------------------
    // Get a total number of players
    // ------------------------------------------------------------------------
    function getTotalPlayers() external view returns (uint256 _total) {
        _total = 0;
        for (uint256 i = 0; i < players.length; i++) {
            // Player might not be removed before
            if (players[i] != address(0) && playersInfo[players[i]].wasRegistered) {
                _total++;
            }
        }
    }

    // ------------------------------------------------------------------------
    // Get an info of the first found player 
    // (start searching at _startSearchingIndex)
    // ------------------------------------------------------------------------
    function getFirstFoundPlayerInfo(uint256 _startSearchingIndex) 
        external view
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

            // Player might not be removed before
            if (player != address(0) && playersInfo[player].wasRegistered) {
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
    function getVoteResultAtIndexByPlayer(address _player, uint256 _votingIndex) 
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

        return playersInfo[_player].tokensBalance;
    }

    // ------------------------------------------------------------------------
    // Allow a player in other different teams vote to the specified team
    // ------------------------------------------------------------------------
    function commitToVote(string _teamName, address _player, uint256 _votingWeight) 
        external onlyVotingState onlyPizzaCoin 
    {
        require(
            _teamName.isNotEmpty(),
            "'_teamName' might not be empty."
        );
        
        require(
            _player != address(0),
            "'_player' contains an invalid address."
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
            _votingWeight <= playersInfo[_player].tokensBalance,
            "Insufficient voting balance."
        );

        playersInfo[_player].tokensBalance = playersInfo[_player].tokensBalance.sub(_votingWeight);

        // If playersInfo[_player].votesWeight[_teamName] > 0 is true, this implies that 
        // the player was used to give a vote to the specified team previously
        if (playersInfo[_player].votesWeight[_teamName] == 0) {
            // The player has never given a vote to the specified team before
            // We, therefore, have to add a new team to the 'teamsVoted' array
            playersInfo[_player].teamsVoted.push(_teamName);
        }

        playersInfo[_player].votesWeight[_teamName] = playersInfo[_player].votesWeight[_teamName].add(_votingWeight);
    }
}


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
    function getTeamArrayLength() external view returns (uint256 _length);
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
    // Get a length of 'team' array (including all ever removal teams)
    // ------------------------------------------------------------------------
    function getTeamArrayLength() external view returns (uint256 _length) {
        return teams.length;
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


// ----------------------------------------------------------------------------
// Pizza Coin Staff Deployer Library
// ----------------------------------------------------------------------------
library PizzaCoinStaffDeployer {

    // ------------------------------------------------------------------------
    // Create a staff contract
    // ------------------------------------------------------------------------
    function deployContract(uint256 _voterInitialTokens) 
        public
        returns (
            PizzaCoinStaff _staffContract
        ) 
    {
        require(
            _voterInitialTokens > 0,
            "'_voterInitialTokens' must be larger than 0."
        );

        _staffContract = new PizzaCoinStaff(_voterInitialTokens);
    }
}


// ----------------------------------------------------------------------------
// Pizza Coin Player Deployer Library
// ----------------------------------------------------------------------------
library PizzaCoinPlayerDeployer {

    // ------------------------------------------------------------------------
    // Create a player contract
    // ------------------------------------------------------------------------
    function deployContract(uint256 _voterInitialTokens) 
        public
        returns (
            PizzaCoinPlayer _playerContract
        ) 
    {
        require(
            _voterInitialTokens > 0,
            "'_voterInitialTokens' must be larger than 0."
        );

        _playerContract = new PizzaCoinPlayer(_voterInitialTokens);
    }
}


// ----------------------------------------------------------------------------
// Pizza Coin Team Deployer Library
// ----------------------------------------------------------------------------
library PizzaCoinTeamDeployer {

    // ------------------------------------------------------------------------
    // Create a team contract
    // ------------------------------------------------------------------------
    function deployContract() 
        public 
        returns (
            PizzaCoinTeam _teamContract
        ) 
    {
        _teamContract = new PizzaCoinTeam();
    }
}


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


// ----------------------------------------------------------------------------
// Pizza Coin Code Library #2
// ----------------------------------------------------------------------------
library PizzaCoinCodeLib2 {
    using SafeMath for uint256;


    // ------------------------------------------------------------------------
    // Determine if _user is a staff or not
    // ------------------------------------------------------------------------
    function isStaff(address _user, address _staffContract) public view returns (bool bStaff) {
        assert(_staffContract != address(0));

        // Get a contract instance from the deployed address
        IStaffContract staffContractInstance = IStaffContract(_staffContract);

        return staffContractInstance.isStaff(_user);
    }

    // ------------------------------------------------------------------------
    // Determine if _user is a player or not
    // ------------------------------------------------------------------------
    function isPlayer(address _user, address _playerContract) public view returns (bool bPlayer) {
        assert(_playerContract != address(0));

        // Get a contract instance from the deployed address
        IPlayerContract playerContractInstance = IPlayerContract(_playerContract);

        return playerContractInstance.isPlayer(_user);
    }

    // ------------------------------------------------------------------------
    // Transfer the state of children contracts from Registration to RegistrationLocked state
    // ------------------------------------------------------------------------
    function signalChildrenContractsToLockRegistration(
        address _staffContract,
        address _playerContract,
        address _teamContract
    ) 
    public 
    {
        assert(_staffContract != address(0));
        assert(_playerContract != address(0));
        assert(_teamContract != address(0));

        // Get contract instances from the deployed addresses
        IStaffContract staffContractInstance = IStaffContract(_staffContract);
        IPlayerContract playerContractInstance = IPlayerContract(_playerContract);
        ITeamContract teamContractInstance = ITeamContract(_teamContract);

        // Transfer the state of children contracts
        staffContractInstance.lockRegistration();
        playerContractInstance.lockRegistration();
        teamContractInstance.lockRegistration();
    }

    // ------------------------------------------------------------------------
    // Transfer the state of children contracts from RegistrationLocked to Voting state
    // ------------------------------------------------------------------------
    function signalChildrenContractsToStartVoting(
        address _staffContract,
        address _playerContract,
        address _teamContract
    ) 
    public 
    {
        assert(_staffContract != address(0));
        assert(_playerContract != address(0));
        assert(_teamContract != address(0));

        // Get contract instances from the deployed addresses
        IStaffContract staffContractInstance = IStaffContract(_staffContract);
        IPlayerContract playerContractInstance = IPlayerContract(_playerContract);
        ITeamContract teamContractInstance = ITeamContract(_teamContract);

        // Transfer the state of children contracts
        staffContractInstance.startVoting();
        playerContractInstance.startVoting();
        teamContractInstance.startVoting();
    }

    // ------------------------------------------------------------------------
    // Transfer the state of children contracts from Voting to VotingFinished state
    // ------------------------------------------------------------------------
    function signalChildrenContractsToStopVoting(
        address _staffContract,
        address _playerContract,
        address _teamContract
    ) 
    public 
    {
        assert(_staffContract != address(0));
        assert(_playerContract != address(0));
        assert(_teamContract != address(0));

        // Get contract instances from the deployed addresses
        IStaffContract staffContractInstance = IStaffContract(_staffContract);
        IPlayerContract playerContractInstance = IPlayerContract(_playerContract);
        ITeamContract teamContractInstance = ITeamContract(_teamContract);

        // Transfer the state of children contracts
        staffContractInstance.stopVoting();
        playerContractInstance.stopVoting();
        teamContractInstance.stopVoting();
    }

    /*
    *
    * This contract is partially compatible with ERC token standard #20 interface.
    * That is, only the balanceOf() and totalSupply() would be implemented.
    *
    */

    // ------------------------------------------------------------------------
    // Standard function of ERC token standard #20
    // ------------------------------------------------------------------------
    function totalSupply(address _staffContract, address _playerContract) 
        public view returns (uint256 _totalSupply) 
    {
        assert(_staffContract != address(0));
        assert(_playerContract != address(0));

        // Get contract instances from the deployed addresses
        IStaffContract staffContractInstance = IStaffContract(_staffContract);
        IPlayerContract playerContractInstance = IPlayerContract(_playerContract);

        uint256 staffTotalSupply = staffContractInstance.getTotalSupply();
        uint256 playerTotalSupply = playerContractInstance.getTotalSupply();
        return staffTotalSupply.add(playerTotalSupply);
    }

    // ------------------------------------------------------------------------
    // Standard function of ERC token standard #20
    // ------------------------------------------------------------------------
    function balanceOf(
        address _tokenOwner, 
        address _staffContract, 
        address _playerContract
    ) 
        public view 
        returns (uint256 _balance) 
    {
        assert(_staffContract != address(0));
        assert(_playerContract != address(0));

        // Get contract instances from the deployed addresses
        IStaffContract staffContractInstance = IStaffContract(_staffContract);
        IPlayerContract playerContractInstance = IPlayerContract(_playerContract);

        if (staffContractInstance.isStaff(_tokenOwner)) {
            return staffContractInstance.getTokenBalance(_tokenOwner);
        }
        else if (playerContractInstance.isPlayer(_tokenOwner)) {
            return playerContractInstance.getTokenBalance(_tokenOwner);
        }
        else {
            revert("The specified address was not being registered.");
        }
    }

    // ------------------------------------------------------------------------
    // Standard function of ERC token standard #20
    // ------------------------------------------------------------------------
    function allowance(address _tokenOwner, address _spender) public pure returns (uint256) {
        // This function does nothing, just revert a transaction
        revert("We don't implement this function.");

        // These statements do nothing, just use to stop compilation warnings
        _tokenOwner == _tokenOwner;
        _spender == _spender;
    }

    // ------------------------------------------------------------------------
    // Standard function of ERC token standard #20
    // ------------------------------------------------------------------------
    function transfer(address _to, uint256 _tokens) public pure returns (bool) {
        // This function does nothing, just revert a transaction
        revert("We don't implement this function.");

        // These statements do nothing, just use to stop compilation warnings
        _to == _to;
        _tokens == _tokens;
    }

    // ------------------------------------------------------------------------
    // Standard function of ERC token standard #20
    // ------------------------------------------------------------------------
    function approve(address _spender, uint256 _tokens) public pure returns (bool) {
        // This function does nothing, just revert a transaction
        revert("We don't implement this function.");

        // These statements do nothing, just use to stop compilation warnings
        _spender == _spender;
        _tokens == _tokens;
    }

    // ------------------------------------------------------------------------
    // Standard function of ERC token standard #20
    // ------------------------------------------------------------------------
    function transferFrom(address _from, address _to, uint256 _tokens) public pure returns (bool) {
        // This function does nothing, just revert a transaction
        revert("We don't implement this function.");

        // These statements do nothing, just use to stop compilation warnings
        _from == _from;
        _to == _to;
        _tokens == _tokens;
    }
}


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
    event TeamVoted(string _teamName, uint256 _totalVoted);


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
            _ownerName.isNotEmpty(),
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
    // Guarantee that _user has not been registered before
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
    // Guarantee that msg.sender has already been registered
    // ------------------------------------------------------------------------
    modifier onlyRegistered {
        require(
            PizzaCoinCodeLib2.isStaff(msg.sender, staffContract) ||
            PizzaCoinCodeLib2.isPlayer(msg.sender, playerContract),
            "This address was not being registered."
        );
        _;
    }

    // ------------------------------------------------------------------------
    // Guarantee that msg.sender must be a staff
    // ------------------------------------------------------------------------
    modifier onlyStaff {
        require(
            PizzaCoinCodeLib2.isStaff(msg.sender, staffContract) || msg.sender == owner,
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
        stateMap[keccak256(abi.encodePacked(State.Initial))] = "Initial";
        stateMap[keccak256(abi.encodePacked(State.Registration))] = "Registration";
        stateMap[keccak256(abi.encodePacked(State.RegistrationLocked))] = "Registration Locked";
        stateMap[keccak256(abi.encodePacked(State.Voting))] = "Voting";
        stateMap[keccak256(abi.encodePacked(State.VotingFinished))] = "Voting Finished";
    }

    // ------------------------------------------------------------------------
    // Get a contract state in String format
    // ------------------------------------------------------------------------
    function getContractState() public view returns (string _state) {
        return stateMap[keccak256(abi.encodePacked(state))];
    }

    // ------------------------------------------------------------------------
    // Allow a staff transfer the state from Initial to Registration
    // ------------------------------------------------------------------------
    function startRegistration() public onlyInitialState {
        // isContractCompletelyInitialized() eventually checks if 
        // the msg.sender is a real staff or not
        address staff = msg.sender;

        // Allow only a staff transfer the state from Initial to Registration and
        // revert a transaction if the contract as well as its children contracts 
        // do not get initialized completely
        PizzaCoinCodeLib.isContractCompletelyInitialized(
            staff, staffContract, playerContract, teamContract
        );

        state = State.Registration;

        // The state of children contracts do not need to do transfer because 
        // their state were set to Registration state once they were created

        emit StateChanged();
    }

    // ------------------------------------------------------------------------
    // Allow a staff freeze Registration state and transfer the state to RegistrationLocked
    // ------------------------------------------------------------------------
    function lockRegistration() public onlyRegistrationState onlyStaff {
        state = State.RegistrationLocked;

        // Transfer the state of children contracts
        PizzaCoinCodeLib2.signalChildrenContractsToLockRegistration(
            staffContract, 
            playerContract, 
            teamContract
        );

        emit StateChanged();
    }

    // ------------------------------------------------------------------------
    // Allow a staff transfer a state from RegistrationLocked to Voting
    // ------------------------------------------------------------------------
    function startVoting() public onlyRegistrationLockedState onlyStaff {
        state = State.Voting;

        // Transfer the state of children contracts
        PizzaCoinCodeLib2.signalChildrenContractsToStartVoting(
            staffContract, 
            playerContract, 
            teamContract
        );

        emit StateChanged();
    }

    // ------------------------------------------------------------------------
    // Allow a staff transfer a state from Voting to VotingFinished
    // ------------------------------------------------------------------------
    function stopVoting() public onlyVotingState onlyStaff {
        state = State.VotingFinished;

        // Transfer the state of children contracts
        PizzaCoinCodeLib2.signalChildrenContractsToStopVoting(
            staffContract, 
            playerContract, 
            teamContract
        );

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

        // Register an owner as a staff. Note that, we cannot make a call to 
        // PizzaCoin.registerStaff() directly at this moment because 
        // the contract state is Initial.
        PizzaCoinCodeLib.registerStaff(owner, ownerName, staffContract);

        emit ChildContractCreated(staffContract);
        return staffContract;
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
    // Register a new staff
    // ------------------------------------------------------------------------
    function registerStaff(address _newStaff, string _newStaffName) 
        public onlyRegistrationState onlyStaff notRegistered(_newStaff) 
    {
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
    // Team leader creates a team
    // ------------------------------------------------------------------------
    function createTeam(string _teamName, string _creatorName) 
        public onlyRegistrationState notRegistered(msg.sender) 
    {
        PizzaCoinCodeLib.createTeam(_teamName, _creatorName, playerContract, teamContract);
        emit TeamCreated();
    }

    // ------------------------------------------------------------------------
    // Remove a specific team (the team must be empty of players)
    // ------------------------------------------------------------------------
    function kickTeam(string _teamName) public onlyRegistrationState onlyStaff {
        PizzaCoinCodeLib.kickTeam(_teamName, teamContract);
        emit TeamKicked();
    }

    // ------------------------------------------------------------------------
    // Register a player
    // ------------------------------------------------------------------------
    function registerPlayer(string _playerName, string _teamName) 
        public onlyRegistrationState notRegistered(msg.sender) 
    {
        PizzaCoinCodeLib.registerPlayer(_playerName, _teamName, playerContract, teamContract);
        emit PlayerRegistered();
    }

    // ------------------------------------------------------------------------
    // Remove a specific player from a particular team
    // ------------------------------------------------------------------------
    function kickPlayer(address _player, string _teamName) public onlyRegistrationState onlyStaff {
        PizzaCoinCodeLib.kickPlayer(_player, _teamName, playerContract, teamContract);
        emit PlayerKicked();
    }

    // ------------------------------------------------------------------------
    // Remove the first found player of a particular team 
    // (start searching at _startSearchingIndex)
    // ------------------------------------------------------------------------
    function kickFirstFoundPlayerInTeam(string _teamName, uint256 _startSearchingIndex) 
        public onlyRegistrationState onlyStaff returns (uint256 _nextStartSearchingIndex) {

        _nextStartSearchingIndex = PizzaCoinCodeLib.kickFirstFoundPlayerInTeam(
            _teamName, _startSearchingIndex, playerContract, teamContract);

        emit PlayerKicked();
        emit FirstFoundPlayerInTeamKicked(_nextStartSearchingIndex);
    }

    // ------------------------------------------------------------------------
    // Allow any staff or any player in other different teams to vote to a team
    // ------------------------------------------------------------------------
    function voteTeam(string _teamName, uint256 _votingWeight) public onlyVotingState onlyRegistered {
        uint256 totalVoted;
        totalVoted = PizzaCoinCodeLib.voteTeam(
            _teamName, 
            _votingWeight, 
            staffContract, 
            playerContract, 
            teamContract
        );
        emit TeamVoted(_teamName, totalVoted);
    }


    /*
    *
    * This contract is partially compatible with ERC token standard #20 interface.
    * That is, only the balanceOf() and totalSupply() would be implemented.
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
    function balanceOf(address _tokenOwner) public view returns (uint256 _balance) {
        return PizzaCoinCodeLib2.balanceOf(_tokenOwner, staffContract, playerContract);
    }

    // ------------------------------------------------------------------------
    // Standard function of ERC token standard #20
    // ------------------------------------------------------------------------
    function allowance(address _tokenOwner, address _spender) public view returns (uint256) {
        // This function does nothing, just revert a transaction
        PizzaCoinCodeLib2.allowance(_tokenOwner, _spender);
    }

    // ------------------------------------------------------------------------
    // Standard function of ERC token standard #20
    // ------------------------------------------------------------------------
    function transfer(address _to, uint256 _tokens) public returns (bool) {
        // This function does nothing, just revert a transaction
        PizzaCoinCodeLib2.transfer(_to, _tokens);
    }

    // ------------------------------------------------------------------------
    // Standard function of ERC token standard #20
    // ------------------------------------------------------------------------
    function approve(address _spender, uint256 _tokens) public returns (bool) {
        // This function does nothing, just revert a transaction
        PizzaCoinCodeLib2.approve(_spender, _tokens);
    }

    // ------------------------------------------------------------------------
    // Standard function of ERC token standard #20
    // ------------------------------------------------------------------------
    function transferFrom(address _from, address _to, uint256 _tokens) public returns (bool) {
        // This function does nothing, just revert a transaction
        PizzaCoinCodeLib2.transferFrom(_from, _to, _tokens);
    }
}