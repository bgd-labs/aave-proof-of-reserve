// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../src/contracts/ProofOfReserveAggregator.sol';

contract ProofOfReserveAggregatorHarness is ProofOfReserveAggregator {

    bool public allBacked;
    bool[] public unbackedFlags;

    function areAllReservesBackedCorrelation(address[] calldata assets) public returns (bool) {
        bool exist_unbacked = false;
        
        (allBacked, unbackedFlags) = this.areAllReservesBacked(assets);
        for (uint256 i = 0; i < unbackedFlags.length; i++){
            if (unbackedFlags[i]){
                exist_unbacked = true;
                break;
            }
        }
        return !exist_unbacked;
    }
}