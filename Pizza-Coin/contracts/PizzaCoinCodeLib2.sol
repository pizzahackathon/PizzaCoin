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

        // Get a contract instance from the deployed addresses
        IStaffContract staffContractInstance = IStaffContract(_staffContract);

        return staffContractInstance.isStaff(_user);
    }

    // ------------------------------------------------------------------------
    // Determine if _user is a player or not
    // ------------------------------------------------------------------------
    function isPlayer(address _user, address _playerContract) public view returns (bool bPlayer) {
        assert(_playerContract != address(0));

        // Get a contract instance from the deployed addresses
        IPlayerContract playerContractInstance = IPlayerContract(_playerContract);

        return playerContractInstance.isPlayer(_user);
    }

    // ------------------------------------------------------------------------
    // Transfer the state of child contracts from Registration to RegistrationLocked state
    // ------------------------------------------------------------------------
    function signalChildContractsToLockRegistration(
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

        // Transfer the state of child contracts
        staffContractInstance.lockRegistration();
        playerContractInstance.lockRegistration();
        teamContractInstance.lockRegistration();
    }

    // ------------------------------------------------------------------------
    // Transfer the state of child contracts from RegistrationLocked to Voting state
    // ------------------------------------------------------------------------
    function signalChildContractsToVoting(
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

        // Transfer the state of child contracts
        staffContractInstance.startVoting();
        playerContractInstance.startVoting();
        teamContractInstance.startVoting();
    }

    // ------------------------------------------------------------------------
    // Transfer the state of child contracts from Voting to VotingFinished state
    // ------------------------------------------------------------------------
    function signalChildContractsToStopVoting(
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

        // Transfer the state of child contracts
        staffContractInstance.stopVoting();
        playerContractInstance.stopVoting();
        teamContractInstance.stopVoting();
    }

    /*
    *
    * Our PizzaCoin contract partially complies with ERC token standard #20 interface.
    * That is, only the balanceOf() and totalSupply() will be used.
    *
    */

    // ------------------------------------------------------------------------
    // Standard function of ERC token standard #20
    // ------------------------------------------------------------------------
    function totalSupply(address _staffContract, address _playerContract) public view returns (uint256 _totalSupply) {
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
        address tokenOwner, 
        address _staffContract, 
        address _playerContract
    ) 
    public view 
    returns (uint256 balance) 
    {
        assert(_staffContract != address(0));
        assert(_playerContract != address(0));

        // Get contract instances from the deployed addresses
        IStaffContract staffContractInstance = IStaffContract(_staffContract);
        IPlayerContract playerContractInstance = IPlayerContract(_playerContract);

        if (staffContractInstance.isStaff(tokenOwner)) {
            return staffContractInstance.getTokenBalance(tokenOwner);
        }
        else if (playerContractInstance.isPlayer(tokenOwner)) {
            return playerContractInstance.getTokenBalance(tokenOwner);
        }
        else {
            revert("The specified address was not being registered.");
        }
    }

    // ------------------------------------------------------------------------
    // Standard function of ERC token standard #20
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public pure returns (uint256) {
        // This function is never used
        revert("We don't implement this function.");

        // These statements do nothing, just use to stop compilation warnings
        tokenOwner == tokenOwner;
        spender == spender;
    }

    // ------------------------------------------------------------------------
    // Standard function of ERC token standard #20
    // ------------------------------------------------------------------------
    function transfer(address to, uint256 tokens) public pure returns (bool) {
        // This function is never used
        revert("We don't implement this function.");

        // These statements do nothing, just use to stop compilation warnings
        to == to;
        tokens == tokens;
    }

    // ------------------------------------------------------------------------
    // Standard function of ERC token standard #20
    // ------------------------------------------------------------------------
    function approve(address spender, uint256 tokens) public pure returns (bool) {
        // This function is never used
        revert("We don't implement this function.");

        // These statements do nothing, just use to stop compilation warnings
        spender == spender;
        tokens == tokens;
    }

    // ------------------------------------------------------------------------
    // Standard function of ERC token standard #20
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint256 tokens) public pure returns (bool) {
        // This function is never used
        revert("We don't implement this function.");

        // These statements do nothing, just use to stop compilation warnings
        from == from;
        to == to;
        tokens == tokens;
    }
}