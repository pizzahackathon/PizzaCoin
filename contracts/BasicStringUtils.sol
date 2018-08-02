/*
* Copyright (c) 2018, Phuwanai Thummavet (serial-coder). All rights reserved.
* Github: https://github.com/serial-coder
* Contact us: mr[dot]thummavet[at]gmail[dot]com
*/

pragma solidity ^0.4.23;


// ----------------------------------------------------------------------------
// Basic String Utils Library - just a lazy and expensive comparison
// ----------------------------------------------------------------------------
library BasicStringUtils {

    // ------------------------------------------------------------------------
    // Determine if two strings are equal or not
    // ------------------------------------------------------------------------
    function isEqual(string self, string other) internal pure returns (bool bEqual) {
        return keccak256(self) == keccak256(other);
    }

    // ------------------------------------------------------------------------
    // Determine if the string is empty or not
    // ------------------------------------------------------------------------
    function isEmpty(string self) internal pure returns (bool bEmpty) {
        bytes memory selfInBytes = bytes(self);
        return selfInBytes.length == 0;
    }
}