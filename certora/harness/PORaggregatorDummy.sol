// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PORaggregatorDummy {
    bool public areReservesBackedFlag;
    bool[] internal unbackedAssetsFlags;

    bool internal isFirst = false;

    function initFlags(bool rand) public {
        areReservesBackedFlag = rand;
        isFirst = false;
    }

    function areAllReservesBacked(address[] calldata assets) public returns (bool, bool[] memory) {
        if(assets.length == 0) {
            areReservesBackedFlag = true;
        } else if(!isFirst) {
            isFirst = true;
            for( uint i = 0; i < assets.length; i++){
                unbackedAssetsFlags[i] = !areReservesBackedFlag;
            }
        }
        return (areReservesBackedFlag, unbackedAssetsFlags);
    }

}