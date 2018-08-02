/*
* Copyright (c) 2018, Phuwanai Thummavet (serial-coder). All rights reserved.
* Github: https://github.com/serial-coder
* Contact us: mr[dot]thummavet[at]gmail[dot]com
*/

pragma solidity ^0.4.23;


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