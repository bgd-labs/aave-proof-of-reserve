```diff
diff --git a/./src/etherscan/FlattenedCurrent.sol b/./src/etherscan/FlattenedNew.sol
index f3d8e40..9e41571 100644
--- a/./src/etherscan/FlattenedCurrent.sol
+++ b/./src/etherscan/FlattenedNew.sol
@@ -612,6 +612,7 @@ library Errors {
   string public constant LPC_INVALID_ADDRESSES_PROVIDER_ID = '40'; // 'The liquidity of the reserve needs to be 0'
   string public constant LPC_INVALID_CONFIGURATION = '75'; // 'Invalid risk parameters for the reserve'
   string public constant LPC_CALLER_NOT_EMERGENCY_ADMIN = '76'; // 'The caller must be the emergency admin'
+  string public constant LPC_CALLER_NOT_POOL_OR_PROOF_OF_RESERVE_ADMIN = '81'; // 'The caller must be the pool or proof of reserve admin'
   string public constant LPAPR_PROVIDER_NOT_REGISTERED = '41'; // 'Provider is not registered'
   string public constant LPCM_HEALTH_FACTOR_NOT_BELOW_THRESHOLD = '42'; // 'Health factor is not below the threshold'
   string public constant LPCM_COLLATERAL_CANNOT_BE_LIQUIDATED = '43'; // 'The collateral chosen cannot be liquidated'
@@ -2114,7 +2115,16 @@ contract LendingPoolConfigurator is VersionedInitializable, ILendingPoolConfigur
     _;
   }

-  uint256 internal constant CONFIGURATOR_REVISION = 0x1;
+  modifier onlyPoolOrProofOfReserveAdmin {
+    require(
+      addressesProvider.getPoolAdmin() == msg.sender ||
+        addressesProvider.getAddress('PROOF_OF_RESERVE_ADMIN') == msg.sender,
+      Errors.LPC_CALLER_NOT_POOL_OR_PROOF_OF_RESERVE_ADMIN
+    );
+    _;
+  }
+
+  uint256 internal constant CONFIGURATOR_REVISION = 0x2;

   function getRevision() internal pure override returns (uint256) {
     return CONFIGURATOR_REVISION;
@@ -2219,7 +2229,8 @@ contract LendingPoolConfigurator is VersionedInitializable, ILendingPoolConfigur

     (, , , uint256 decimals, ) = cachedPool.getConfiguration(input.asset).getParamsMemory();

-    bytes memory encodedCall = abi.encodeWithSelector(
+    bytes memory encodedCall =
+      abi.encodeWithSelector(
         IInitializableAToken.initialize.selector,
         cachedPool,
         input.treasury,
@@ -2231,11 +2242,7 @@ contract LendingPoolConfigurator is VersionedInitializable, ILendingPoolConfigur
         input.params
       );

-    _upgradeTokenImplementation(
-      reserveData.aTokenAddress,
-      input.implementation,
-      encodedCall
-    );
+    _upgradeTokenImplementation(reserveData.aTokenAddress, input.implementation, encodedCall);

     emit ATokenUpgraded(input.asset, reserveData.aTokenAddress, input.implementation);
   }
@@ -2250,7 +2257,8 @@ contract LendingPoolConfigurator is VersionedInitializable, ILendingPoolConfigur

     (, , , uint256 decimals, ) = cachedPool.getConfiguration(input.asset).getParamsMemory();

-    bytes memory encodedCall = abi.encodeWithSelector(
+    bytes memory encodedCall =
+      abi.encodeWithSelector(
         IInitializableDebtToken.initialize.selector,
         cachedPool,
         input.asset,
@@ -2277,17 +2285,15 @@ contract LendingPoolConfigurator is VersionedInitializable, ILendingPoolConfigur
   /**
    * @dev Updates the variable debt token implementation for the asset
    **/
-  function updateVariableDebtToken(UpdateDebtTokenInput calldata input)
-    external
-    onlyPoolAdmin
-  {
+  function updateVariableDebtToken(UpdateDebtTokenInput calldata input) external onlyPoolAdmin {
     ILendingPool cachedPool = pool;

     DataTypes.ReserveData memory reserveData = cachedPool.getReserveData(input.asset);

     (, , , uint256 decimals, ) = cachedPool.getConfiguration(input.asset).getParamsMemory();

-    bytes memory encodedCall = abi.encodeWithSelector(
+    bytes memory encodedCall =
+      abi.encodeWithSelector(
         IInitializableDebtToken.initialize.selector,
         cachedPool,
         input.asset,
@@ -2334,7 +2340,7 @@ contract LendingPoolConfigurator is VersionedInitializable, ILendingPoolConfigur
    * @dev Disables borrowing on a reserve
    * @param asset The address of the underlying asset of the reserve
    **/
-  function disableBorrowingOnReserve(address asset) external onlyPoolAdmin {
+  function disableBorrowingOnReserve(address asset) external onlyPoolOrProofOfReserveAdmin {
     DataTypes.ReserveConfigurationMap memory currentConfig = pool.getConfiguration(asset);

     currentConfig.setBorrowingEnabled(false);
@@ -2414,7 +2420,7 @@ contract LendingPoolConfigurator is VersionedInitializable, ILendingPoolConfigur
    * @dev Disable stable rate borrowing on a reserve
    * @param asset The address of the underlying asset of the reserve
    **/
-  function disableReserveStableRate(address asset) external onlyPoolAdmin {
+  function disableReserveStableRate(address asset) external onlyPoolOrProofOfReserveAdmin {
     DataTypes.ReserveConfigurationMap memory currentConfig = pool.getConfiguration(asset);

     currentConfig.setStableRateBorrowingEnabled(false);
@@ -2459,7 +2465,7 @@ contract LendingPoolConfigurator is VersionedInitializable, ILendingPoolConfigur
    *  but allows repayments, liquidations, rate rebalances and withdrawals
    * @param asset The address of the underlying asset of the reserve
    **/
-  function freezeReserve(address asset) external onlyPoolAdmin {
+  function freezeReserve(address asset) external onlyPoolOrProofOfReserveAdmin {
     DataTypes.ReserveConfigurationMap memory currentConfig = pool.getConfiguration(asset);

     currentConfig.setFrozen(true);
```
