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

        // Add a player to the specified team
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
    // Remove the first player on the list from a particular team 
    // ------------------------------------------------------------------------
    function kickFirstPlayerInTeam(
        string _teamName, 
        address _playerContract,
        address _teamContract
    ) 
    public
    {
        assert(_playerContract != address(0));
        assert(_teamContract != address(0));

        // Get a contract instance from the deployed addresses
        ITeamContract teamContractInstance = ITeamContract(_teamContract);

        bool endOfList;
        address player;

        // Get the first player in the specified team
        (endOfList, player) = teamContractInstance.getPlayerInTeamAtIndex(_teamName, 0);

        if (endOfList) {
            revert("There is no player in the specified team.");
        }
        
        // Remove a specific player
        kickPlayer(player, _teamName, _playerContract, _teamContract);
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
        teamContractInstance.kickPlayerOutOfTeam(_player, _teamName);
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
    // Allow any staff or any player vote to a favourite team
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
            // Voter is a player
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
        staffContractInstance.commitToVote(voter, _teamName, _votingWeight);
        teamContractInstance.voteToTeam(voter, _teamName, _votingWeight);

        // Get the current voting points of the team
        _totalVoted = teamContractInstance.getVotingPointsOfTeam(_teamName);
    }

    // ------------------------------------------------------------------------
    // Vote for a team by a different team's player
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
        playerContractInstance.commitToVote(voter, _teamName, _votingWeight);
        teamContractInstance.voteToTeam(voter, _teamName, _votingWeight);

        // Get the current voting points of the team
        _totalVoted = teamContractInstance.getVotingPointsOfTeam(_teamName);
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
    * That is, only balanceOf() and totalSupply() would really be implemented.
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
    // Guarantee that _user is not registered
    // ------------------------------------------------------------------------
    modifier notRegistered(address _user) {
        require(
            PizzaCoinCodeLib2.isStaff(_user, staffContract) == false && 
            PizzaCoinCodeLib2.isPlayer(_user, playerContract) == false,
            "This address is registered already."
        );
        _;
    }

    // ------------------------------------------------------------------------
    // Guarantee that msg.sender is already registered
    // ------------------------------------------------------------------------
    modifier onlyRegistered {
        require(
            PizzaCoinCodeLib2.isStaff(msg.sender, staffContract) ||
            PizzaCoinCodeLib2.isPlayer(msg.sender, playerContract),
            "This address is not being registered."
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
    // Initial the state mapping
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
        // the contract is in Initial state.
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
    // Remove the first player on the list from a particular team 
    // ------------------------------------------------------------------------
    function kickFirstPlayerInTeam(string _teamName) public onlyRegistrationState onlyStaff {
        PizzaCoinCodeLib.kickFirstPlayerInTeam(_teamName, playerContract, teamContract);
        emit PlayerKicked();
    }

    // ------------------------------------------------------------------------
    // Allow any staff or any player vote to a favourite team
    // ------------------------------------------------------------------------
    function voteTeam(string _teamName, uint256 _votingWeight) public onlyVotingState onlyRegistered {
        uint256 totalVoted = PizzaCoinCodeLib.voteTeam(
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
    * That is, only balanceOf() and totalSupply() would really be implemented.
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