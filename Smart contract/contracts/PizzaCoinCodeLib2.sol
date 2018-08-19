/*
* Copyright (c) 2018, Phuwanai Thummavet (serial-coder). All rights reserved.
* Github: https://github.com/serial-coder
* Contact us: mr[dot]thummavet[at]gmail[dot]com
*/

pragma solidity ^0.4.23;

import "./SafeMath.sol";
import "./PizzaCoinStaff.sol";
import "./PizzaCoinPlayer.sol";
import "./PizzaCoinTeam.sol";


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