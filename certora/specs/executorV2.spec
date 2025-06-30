using PORaggregatorDummy as aggregator;

methods {
  function getAssets() external returns (address[]) envfree ;
  function enableAssets(address[]) external;
  function disableAssets(address[]) external;
  function areAllReservesBacked() external returns (bool) envfree;
  function executeEmergencyAction() external envfree;
  function isEmergencyActionPossible() external returns (bool) envfree;

  // Harness:
  function enableAsset(address) external;
  function disableAsset(address) external;
  function getAssetState(address) external returns (bool) envfree;
  function getAssetsLength() external returns (uint256) envfree;
  function getAsset(uint256) external returns (address) envfree;
  function _disableBorrowingCalled() external returns (bool) envfree;

  // Dummy aggregator functions:
  function aggregator.areReservesBackedFlag() external returns (bool) envfree;
  function aggregator.initFlags(bool) external envfree;

  // For internal hooks check
  function get_values_len() external returns (uint256) envfree;
  function get_value(uint256 index) external returns (address) envfree;
  function contains(address asset) external returns (bool) envfree;
}

function assetsRequirements() {
  requireInvariant enabledAssets_integrity();
  require getAssetsLength() < max_uint160 - 1;
}

/*
  @Rule
  @Description: The integrity of disabling an asset.
  after calling to disableAsset(asset) the asset's state should be disabled (False).
  If the asset already exists, then one asset should be removed,
  otherwise, no asset should be removed.
         
  @Formula: 
  {
  assetStateBefore := getAssetState(asset),
  assetsLengthBefore := getAssetsLength()
  }
  disableAsset(asset)
  {
  !assetStateAfter,
  !assetStateAfter => assetsLengthBefore == assetsLengthAfter,
  assetStateAfter => assetsLengthBefore == assetsLengthAfter + 1
  }

  @Notes:
  @Link:
*/
rule integrityOfDisableAssets(address asset) {
  env e;
  assetsRequirements(); 
  bool assetStateBefore = getAssetState(asset);
  uint256 assetsLengthBefore = getAssetsLength();
  require assetsLengthBefore < max_uint256 - 2;
    
  disableAsset(e, asset);

  bool assetStateAfter = getAssetState(asset);
  uint256 assetsLengthAfter = getAssetsLength();

  assert !assetStateAfter;
  assert !assetStateBefore => assetsLengthBefore == assetsLengthAfter;
  assert assetStateBefore => assetsLengthBefore == assetsLengthAfter + 1;
}

/*
  @Rule
  @Description: The integrity of enabling an asset.
  after calling to enableAsset(asset) the asset's state should be enabled.
  If the asset already exists and enabled, then no assets should be added,
  otherwise, one asset should be added.
  @Formula: 
  {
  assetStateBefore := getAssetState(asset),
  assetsLengthBefore := getAssetsLength()
  }
  enableAsset(asset)
  {
  assetStateAfter,
  assetStateBefore => assetsLengthBefore == assetsLengthAfter,
  !assetStateBefore => assetsLengthBefore == assetsLengthAfter - 1
  }
  
  @Notes:
  @Link:
*/
rule integrityOfEnableAssets(address asset) {
  env e;
  assetsRequirements();
  bool assetStateBefore = getAssetState(asset);
  uint256 assetsLengthBefore = getAssetsLength();
  require assetsLengthBefore < max_uint256 - 2;
  
  enableAsset(e, asset);
    
  bool assetStateAfter = getAssetState(asset);
  uint256 assetsLengthAfter = getAssetsLength();
  
  assert assetStateAfter;
  assert assetStateBefore => assetsLengthBefore == assetsLengthAfter;
  assert !assetStateBefore => assetsLengthBefore == assetsLengthAfter - 1;
}

/*
    @Rule
    @Description: enable the same asset twice is equal to enable the asset once.
         
    @Formula: 
        {
            assetStateBefore := getAssetState(asset),
            assetsLengthBefore := getAssetsLength()
        }
        enableAsset(asset)
        enableAsset(asset)
        {
            assetStateAfter2Calls := getAssetState(asset),
            assetsLengthAfter2Calls := getAssetsLength()
        }

        enableAsset(asset)
        {
            assetStateAfter1Call := getAssetState(asset),
            assetsLengthAfter1Call := getAssetsLength()
        }
        {
            assetStateAfter2Calls == assetStateAfter1Call,
            assetsLengthAfter2Calls == assetsLengthAfter1Call
        }

    @Notes:
    @Link:
*/
rule enableDuplicationsWithStorage(address asset) {
  env e;
  assetsRequirements();
  bool assetStateBefore = getAssetState(asset);
  uint256 assetsLengthBefore = getAssetsLength();
  require assetsLengthBefore < max_uint256 - 2;

  storage initialStorage = lastStorage;

  enableAsset(e, asset);
  enableAsset(e, asset);

  bool assetStateAfter2Calls = getAssetState(asset);
  uint256 assetsLengthAfter2Calls = getAssetsLength();
  
  enableAsset(e, asset) at initialStorage;
  
  bool assetStateAfter1Call = getAssetState(asset);
  uint256 assetsLengthAfter1Call = getAssetsLength();
  
  assert assetStateAfter2Calls == assetStateAfter1Call;
  assert assetsLengthAfter2Calls == assetsLengthAfter1Call;
}

/*
  @Rule
  @Description: disable the same asset twice is equal to disable the asset once.
  
  @Formula: 
  {
  assetStateBefore := getAssetState(asset),
  assetsLengthBefore := getAssetsLength()
  }
  disableAsset(asset)
  disableAsset(asset)
  {
  assetStateAfter2Calls := getAssetState(asset),
  assetsLengthAfter2Calls := getAssetsLength()
  }
  
  disableAsset(asset)
  {
  assetStateAfter1Call := getAssetState(asset),
  assetsLengthAfter1Call := getAssetsLength()
  }
  {
  assetStateAfter2Calls == assetStateAfter1Call,
  assetsLengthAfter2Calls == assetsLengthAfter1Call
  }
  
  @Notes:
  @Link:
*/
rule disableDuplicationsWithStorage(address asset) {
  env e;
  assetsRequirements();
  bool assetStateBefore = getAssetState(asset);
  uint256 assetsLengthBefore = getAssetsLength();
  require assetsLengthBefore < max_uint256 - 2;
  
  storage initialStorage = lastStorage;
    
  disableAsset(e, asset);
  disableAsset(e, asset);
    
  bool assetStateAfter2Calls = getAssetState(asset);
  uint256 assetsLengthAfter2Calls = getAssetsLength();
  
  disableAsset(e, asset) at initialStorage;
  
  bool assetStateAfter1Call = getAssetState(asset);
  uint256 assetsLengthAfter1Call = getAssetsLength();
  
  assert assetStateAfter2Calls == assetStateAfter1Call;
  assert assetsLengthAfter2Calls == assetsLengthAfter1Call;
}

/*
    @Rule
    @Description: call executeEmergencyAction(), if areAllReservesBacked is false then _disableborrowing() was called,
                                                else, _disableborrowing() was not called
         
    @Formula: 
        {
            allReservesBacked := areAllReservesBacked()
        }
        executeEmergencyAction()
        {
            !allReservesBacked => disableBorrowingCalled
            allReservesBacked => !disableBorrowingCalled
        }

    @Notes:
    @Link:
*/
rule integrityOfExecuteEmergencyAction(bool rand) {
  require _disableBorrowingCalled() == false;
  aggregator.initFlags(rand);
  bool allReservesBacked = areAllReservesBacked();
  
  executeEmergencyAction();
  
  bool disableBorrowingCalled = _disableBorrowingCalled();
  
  assert !allReservesBacked => disableBorrowingCalled;
  assert allReservesBacked => !disableBorrowingCalled;
}



// *********************************************************************
// The following ghost are mirrors of the enumerableSet: _enabledAssets
// --------------------------------------------------------------------
persistent ghost mapping(uint256 => bytes32) mirrorArray {
  init_state axiom forall uint256 i. mirrorArray[i] == to_bytes32(0);
}
persistent ghost uint256 mirrorArrayLen {
  init_state axiom mirrorArrayLen == 0;
}
persistent ghost mapping(bytes32 => uint256) mirrorMap {
  init_state axiom forall bytes32 a. mirrorMap[a] == 0;
}
// **********************************************************************

hook Sstore _enabledAssets.(offset 0).(offset 0) uint256 newLen (uint256 oldLen) {
  mirrorArrayLen = newLen;
}
hook Sload uint256 len _enabledAssets.(offset 0).(offset 0) {
  require mirrorArrayLen == len;
}

hook Sstore _enabledAssets.(offset 0)[INDEX uint256 index] bytes32 newValue (bytes32 oldValue) {
  mirrorArray[index] = newValue;
  address newAddress = require_address(newValue);
}
hook Sload bytes32 value _enabledAssets.(offset 0)[INDEX uint256 index] {
  require(mirrorArray[index] == value);
}

hook Sstore _enabledAssets.(offset 32)[KEY bytes32 key] uint256 newIndex (uint256 oldIndex) {
  mirrorMap[key] = newIndex;
}
hook Sload uint256 index _enabledAssets .(offset 32)[KEY bytes32 key] {
  require(mirrorMap[key] == index);
}


// *********************************************************************
// The following 3 rules are for internal checking that our hooks are correct
// --------------------------------------------------------------------
rule mirrorMap_correctness() {
  address asset;
  assert mirrorMap[to_bytes32(asset)]!=0 <=> contains(asset);
}
rule mirrorArrayLen_correctness() {
  assert mirrorArrayLen == get_values_len();
}
rule mirrorArray_correctness() {
  uint256 index;
  address real_add = require_address(mirrorArray[index]);
  assert to_bytes32(get_value(index))==mirrorArray[index];
}
// *********************************************************************



// *********************************************************************
// The main invariant for the enumerableSet
// --------------------------------------------------------------------
invariant enabledAssets_integrity()
  (forall uint256 i. i < mirrorArrayLen => mirrorMap[mirrorArray[i]]==i+1)
  &&
  (forall bytes32 val. forall uint256 index. forall uint256 index_minus_1.
   (index==mirrorMap[val] && index!=0 && index_minus_1==index-1) => (mirrorMap[val]-1 < mirrorArrayLen &&
                                                                     mirrorArray[index_minus_1] == val)
  )
  &&
  (forall uint256 i. forall uint256 j. (i < mirrorArrayLen && j < mirrorArrayLen && i!=j) => (mirrorArray[i] != mirrorArray[j]))
  &&
  (forall uint256 i. (i < mirrorArrayLen) => (mirrorArray[i] != to_bytes32(0)))
{
  preserved{
    require getAssetsLength() < max_uint160 - 1;
  }
}

