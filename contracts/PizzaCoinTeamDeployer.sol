/*
* Copyright (c) 2018, Phuwanai Thummavet (serial-coder). All rights reserved.
* Github: https://github.com/serial-coder
* Contact us: mr[dot]thummavet[at]gmail[dot]com
*/

pragma solidity ^0.4.23;

import "./PizzaCoinTeam.sol";


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