// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {ISpoke} from 'aave-address-book/AaveV4.sol';

import {ProofOfReserveExecutorV4} from '../src/contracts/ProofOfReserveExecutorV4.sol';
import {IProofOfReserveExecutorV4} from '../src/interfaces/IProofOfReserveExecutorV4.sol';

/**
 * @dev Minimal mock of the ProofOfReserveAggregator, letting the test toggle whether a given
 * asset is reported as unbacked.
 */
contract MockAggregator {
  mapping(address => bool) internal _unbacked;

  function setUnbacked(address asset, bool unbacked) external {
    _unbacked[asset] = unbacked;
  }

  function areAllReservesBacked(
    address[] calldata assets
  ) external view returns (bool, bool[] memory) {
    bool[] memory flags = new bool[](assets.length);
    bool areBacked = true;
    for (uint256 i = 0; i < assets.length; ++i) {
      if (_unbacked[assets[i]]) {
        flags[i] = true;
        areBacked = false;
      }
    }
    return (areBacked, flags);
  }
}

/**
 * @dev Minimal mock of an Aave V4 Spoke, exposing only the reserve lookups used by the Executor
 * and the SpokeConfigurator.
 */
contract MockSpoke {
  mapping(bytes32 => bool) internal _hasReserve;
  mapping(bytes32 => uint256) internal _reserveId;
  mapping(uint256 => ISpoke.ReserveConfig) internal _configs;

  function addReserve(
    address hub,
    uint256 assetId,
    uint256 reserveId
  ) external {
    bytes32 key = keccak256(abi.encode(hub, assetId));
    _hasReserve[key] = true;
    _reserveId[key] = reserveId;
    _configs[reserveId] = ISpoke.ReserveConfig({
      collateralRisk: 0,
      paused: false,
      frozen: false,
      borrowable: true,
      receiveSharesEnabled: true
    });
  }

  function getReserveId(
    address hub,
    uint256 assetId
  ) external view returns (uint256) {
    bytes32 key = keccak256(abi.encode(hub, assetId));
    require(_hasReserve[key], 'RESERVE_NOT_LISTED');
    return _reserveId[key];
  }

  function getReserveConfig(
    uint256 reserveId
  ) external view returns (ISpoke.ReserveConfig memory) {
    return _configs[reserveId];
  }

  function updateReserveConfig(
    uint256 reserveId,
    ISpoke.ReserveConfig calldata config
  ) external {
    _configs[reserveId] = config;
  }
}

/**
 * @dev Minimal mock of the Aave V4 SpokeConfigurator, mimicking the real `freezeReserve` behaviour
 * of reading the reserve config, flipping the `frozen` flag, and writing it back.
 */
contract MockSpokeConfigurator {
  function freezeReserve(address spoke, uint256 reserveId) external {
    ISpoke.ReserveConfig memory config = MockSpoke(spoke).getReserveConfig(
      reserveId
    );
    config.frozen = true;
    MockSpoke(spoke).updateReserveConfig(reserveId, config);
  }
}

/**
 * @dev Minimal mock of an Aave V4 Hub, exposing only the asset/spoke lookups used by the Executor.
 */
contract MockHub {
  mapping(address => bool) internal _listed;
  mapping(address => uint256) internal _assetId;
  mapping(uint256 => address[]) internal _spokes;

  function listAsset(address underlying, uint256 assetId) external {
    _listed[underlying] = true;
    _assetId[underlying] = assetId;
  }

  function addSpokeToAsset(uint256 assetId, address spoke) external {
    _spokes[assetId].push(spoke);
  }

  function isUnderlyingListed(address underlying) external view returns (bool) {
    return _listed[underlying];
  }

  function getAssetId(address underlying) external view returns (uint256) {
    require(_listed[underlying], 'ASSET_NOT_LISTED');
    return _assetId[underlying];
  }

  function getSpokeCount(uint256 assetId) external view returns (uint256) {
    return _spokes[assetId].length;
  }

  function getSpokeAddress(
    uint256 assetId,
    uint256 index
  ) external view returns (address) {
    return _spokes[assetId][index];
  }
}

contract ProofOfReserveExecutorV4Test is Test {
  ProofOfReserveExecutorV4 internal executor;
  MockAggregator internal aggregator;
  MockSpokeConfigurator internal spokeConfigurator;
  MockHub internal hub;
  MockSpoke internal spokeA;
  MockSpoke internal spokeB;
  MockSpoke internal spokeNoReserve;

  address internal constant ASSET = address(0xA55E7);
  address internal constant OTHER_ASSET = address(0x0DDE7);
  uint256 internal constant ASSET_ID = 3;
  uint256 internal constant RESERVE_ID_A = 0;
  uint256 internal constant RESERVE_ID_B = 5;

  address internal constant ALICE = address(0xA11CE);

  event AssetStateChanged(address indexed asset, bool enabled);
  event AssetIsNotBacked(address indexed asset);
  event EmergencyActionExecuted();
  event HubStateChanged(address indexed hub, bool enabled);

  function setUp() public {
    aggregator = new MockAggregator();
    spokeConfigurator = new MockSpokeConfigurator();
    executor = new ProofOfReserveExecutorV4(
      address(spokeConfigurator),
      address(aggregator)
    );

    hub = new MockHub();
    spokeA = new MockSpoke();
    spokeB = new MockSpoke();
    spokeNoReserve = new MockSpoke();

    // list ASSET on the hub and register three spokes for it
    hub.listAsset(ASSET, ASSET_ID);
    hub.addSpokeToAsset(ASSET_ID, address(spokeA));
    hub.addSpokeToAsset(ASSET_ID, address(spokeB));
    hub.addSpokeToAsset(ASSET_ID, address(spokeNoReserve));

    // only spokeA and spokeB actually hold a reserve for (hub, ASSET_ID)
    spokeA.addReserve(address(hub), ASSET_ID, RESERVE_ID_A);
    spokeB.addReserve(address(hub), ASSET_ID, RESERVE_ID_B);

    _enableAsset(ASSET);
    _enableHub(address(hub));
  }

  // ---------------------------------------------------------------------------
  // Hub management
  // ---------------------------------------------------------------------------

  function test_enableHubs() public {
    MockHub hub2 = new MockHub();

    vm.expectEmit(true, false, false, true);
    emit HubStateChanged(address(hub2), true);
    _enableHub(address(hub2));

    address[] memory hubs = executor.getHubs();
    assertEq(hubs.length, 2);
    assertEq(hubs[0], address(hub));
    assertEq(hubs[1], address(hub2));
  }

  function test_enableHubs_isIdempotent() public {
    _enableHub(address(hub));
    assertEq(executor.getHubs().length, 1);
  }

  function test_enableHubs_revertsOnZeroAddress() public {
    address[] memory hubs = new address[](1);
    hubs[0] = address(0);
    vm.expectRevert(IProofOfReserveExecutorV4.ZeroAddress.selector);
    executor.enableHubs(hubs);
  }

  function test_enableHubs_revertsIfNotOwner() public {
    address[] memory hubs = new address[](1);
    hubs[0] = address(hub);
    vm.prank(ALICE);
    vm.expectRevert(
      abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, ALICE)
    );
    executor.enableHubs(hubs);
  }

  function test_disableHubs() public {
    vm.expectEmit(true, false, false, true);
    emit HubStateChanged(address(hub), false);
    _disableHub(address(hub));

    assertEq(executor.getHubs().length, 0);
  }

  function test_disableHubs_revertsIfNotOwner() public {
    address[] memory hubs = new address[](1);
    hubs[0] = address(hub);
    vm.prank(ALICE);
    vm.expectRevert(
      abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, ALICE)
    );
    executor.disableHubs(hubs);
  }

  // ---------------------------------------------------------------------------
  // Emergency action
  // ---------------------------------------------------------------------------

  function test_isEmergencyActionPossible_falseWhenBacked() public view {
    assertFalse(executor.isEmergencyActionPossible());
  }

  function test_isEmergencyActionPossible_trueWhenUnbacked() public {
    aggregator.setUnbacked(ASSET, true);
    assertTrue(executor.isEmergencyActionPossible());
  }

  function test_isEmergencyActionPossible_falseWhenAlreadyFrozen() public {
    aggregator.setUnbacked(ASSET, true);
    // freeze both reserves ahead of time
    executor.executeEmergencyAction();
    assertFalse(executor.isEmergencyActionPossible());
  }

  function test_executeEmergencyAction_allBacked() public {
    executor.executeEmergencyAction();

    assertFalse(_isFrozen(spokeA, RESERVE_ID_A));
    assertFalse(_isFrozen(spokeB, RESERVE_ID_B));
  }

  function test_executeEmergencyAction_freezesUnbackedReserves() public {
    aggregator.setUnbacked(ASSET, true);

    vm.expectEmit(true, false, false, true);
    emit AssetIsNotBacked(ASSET);
    vm.expectEmit(false, false, false, true);
    emit EmergencyActionExecuted();

    executor.executeEmergencyAction();

    // the reserves of the two spokes holding a reserve for the asset are frozen
    assertTrue(_isFrozen(spokeA, RESERVE_ID_A));
    assertTrue(_isFrozen(spokeB, RESERVE_ID_B));

    // subsequent calls are a no-op since everything is already frozen
    assertFalse(executor.isEmergencyActionPossible());
  }

  function test_executeEmergencyAction_onlyFreezesUnbackedAsset() public {
    // list and monitor a second, still-backed asset on the same hub
    uint256 otherAssetId = 9;
    hub.listAsset(OTHER_ASSET, otherAssetId);
    MockSpoke otherSpoke = new MockSpoke();
    hub.addSpokeToAsset(otherAssetId, address(otherSpoke));
    otherSpoke.addReserve(address(hub), otherAssetId, 1);
    _enableAsset(OTHER_ASSET);

    aggregator.setUnbacked(ASSET, true);
    executor.executeEmergencyAction();

    assertTrue(_isFrozen(spokeA, RESERVE_ID_A));
    assertTrue(_isFrozen(spokeB, RESERVE_ID_B));
    // the backed asset is untouched
    assertFalse(_isFrozen(otherSpoke, 1));
  }

  function test_executeEmergencyAction_skipsHubsWithoutAsset() public {
    // a second hub that does not list the asset should simply be skipped
    MockHub hub2 = new MockHub();
    _enableHub(address(hub2));

    aggregator.setUnbacked(ASSET, true);
    executor.executeEmergencyAction();

    assertTrue(_isFrozen(spokeA, RESERVE_ID_A));
    assertTrue(_isFrozen(spokeB, RESERVE_ID_B));
  }

  // ---------------------------------------------------------------------------
  // helpers
  // ---------------------------------------------------------------------------

  function _enableAsset(address asset) internal {
    address[] memory assets = new address[](1);
    assets[0] = asset;
    executor.enableAssets(assets);
  }

  function _enableHub(address hub_) internal {
    address[] memory hubs = new address[](1);
    hubs[0] = hub_;
    executor.enableHubs(hubs);
  }

  function _disableHub(address hub_) internal {
    address[] memory hubs = new address[](1);
    hubs[0] = hub_;
    executor.disableHubs(hubs);
  }

  function _isFrozen(
    MockSpoke spoke,
    uint256 reserveId
  ) internal view returns (bool) {
    return spoke.getReserveConfig(reserveId).frozen;
  }
}
