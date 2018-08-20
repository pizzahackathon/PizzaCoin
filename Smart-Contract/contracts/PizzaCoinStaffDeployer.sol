/*
* Copyright (c) 2018, Phuwanai Thummavet (serial-coder). All rights reserved.
* Github: https://github.com/serial-coder
* Contact us: mr[dot]thummavet[at]gmail[dot]com
*/

pragma solidity ^0.4.23;

import "./PizzaCoinStaff.sol";


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