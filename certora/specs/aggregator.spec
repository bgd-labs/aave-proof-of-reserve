methods {
  function getProofOfReserveFeedForAsset(address) external returns (address) envfree;
  function disableProofOfReserveFeed(address) external;
  function enableProofOfReserveFeed(address, address) external;
  function areAllReservesBacked(address[]) external returns (bool, bool[]) envfree;
  function getReservesProviderForAsset(address) external returns (address) envfree;
  function enableProofOfReserveFeedWithBridgeWrapper(address, address, address) external;

    // summarizations:
  function  _.latestRoundData() external => NONDET;
    // Getters: 
  function  allBacked() external returns (bool) envfree;
}


// calling function with specific parameters
function call_f_with_params(method f, env e, address asset , address PoRFeed, address wrapper) {
    calldataarg args;
    if (f.selector == sig:enableProofOfReserveFeed(address, address).selector) {
        enableProofOfReserveFeed(e, asset, PoRFeed);
    } else if (f.selector == sig:disableProofOfReserveFeed(address).selector) {
        disableProofOfReserveFeed(e, asset);
    } else if (f.selector == sig:enableProofOfReserveFeedWithBridgeWrapper(address, address, address).selector) {
        enableProofOfReserveFeedWithBridgeWrapper(e, asset, PoRFeed, wrapper);
    } else {
        f(e, args);
    }
}

// modification to the PoR feed of assets
// if enableProofOfReserveFeed called -> price feed must be a non-zero address
// if enableProofOfReserveFeedWithBridgeWrapper called -> price feed and bridgeWrapper must be a non-zero address
// if disableProofOfReserveFeed called -> price feed and bridgeWrapper assigned to the asset must be nullified
// if any other function called -> price and bridgeWrapper mustn't change
rule PoRFeedChange(address asset, address PoRFeed, address wrapper){
    
    address feedBefore = getProofOfReserveFeedForAsset(asset);
    address bridgeWrapperBefore = getReservesProviderForAsset(asset);
    
    method f; env e;
    call_f_with_params(f, e, asset, PoRFeed, wrapper);

    address feedAfter = getProofOfReserveFeedForAsset(asset);
    address bridgeWrapperAfter = getReservesProviderForAsset(asset);

    assert f.selector == sig:enableProofOfReserveFeed(address, address).selector => (feedAfter != 0 && feedAfter == PoRFeed);
    assert f.selector == sig:enableProofOfReserveFeedWithBridgeWrapper(address, address, address).selector => 
                        (feedAfter != 0 && feedAfter == PoRFeed && bridgeWrapperAfter != 0 && bridgeWrapperAfter == wrapper);
    assert f.selector == sig:disableProofOfReserveFeed(address).selector => feedAfter == 0 && bridgeWrapperAfter == 0;
    assert (f.selector != sig:enableProofOfReserveFeed(address, address).selector && 
            f.selector != sig:disableProofOfReserveFeed(address).selector &&
            f.selector != sig:enableProofOfReserveFeedWithBridgeWrapper(address, address, address).selector) => 
                        feedBefore == feedAfter && bridgeWrapperBefore == bridgeWrapperAfter;
}

// if areAllReservesBacked is false then at least one slot in tokenBacked array is false, otherwise all slots in tokenBacked array is true.
rule notAllReservesBacked_UnbackedArry_Correlation() {
    env e; address[] assets;
    
    bool reservesArrayIsBacked = areAllReservesBackedCorrelation(e, assets);
    bool areAllReservesBacked = allBacked();
    assert reservesArrayIsBacked == areAllReservesBacked;
}
