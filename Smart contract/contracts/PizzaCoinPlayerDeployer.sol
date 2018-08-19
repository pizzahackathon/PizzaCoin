/*
* Copyright (c) 2018, Phuwanai Thummavet (serial-coder). All rights reserved.
* Github: https://github.com/serial-coder
* Contact us: mr[dot]thummavet[at]gmail[dot]com
*/

pragma solidity ^0.4.23;

import "./PizzaCoinPlayer.sol";


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