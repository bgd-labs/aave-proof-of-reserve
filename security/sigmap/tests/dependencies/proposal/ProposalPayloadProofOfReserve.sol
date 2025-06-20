// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LinkTokenInterface} from 'chainlink-brownie-contracts/interfaces/LinkTokenInterface.sol';
import {KeeperRegistryInterface, Config, State} from 'chainlink-brownie-contracts/interfaces/KeeperRegistryInterface.sol';
import {KeeperRegistrarInterface} from './KeeperRegistrarInterface.sol';
import {ILendingPoolAddressesProvider} from 'aave-address-book/AaveV2.sol';
import {IACLManager} from 'aave-address-book/AaveV3.sol';
import {IProofOfReserveAggregator} from '../interfaces/IProofOfReserveAggregator.sol';
import {IProofOfReserveExecutor} from '../interfaces/IProofOfReserveExecutor.sol';
import {ICollectorController} from '../ICollectorController.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {AaveV2Avalanche, AaveV3Avalanche} from 'aave-address-book/AaveAddressBook.sol';

/**
 * @title ProposalPayloadProofOfReserve
 * @author BGD Labs
 * @dev Proposal to deploy Proof Of Reserve and enable it as proofOfReserve admin for V2 and risk admin for V3.
 * - Add pairs of token and its proof of reserves to Proof Of Reserves Aggregator
 * - V2: upgrade implementation of LendingPoolConfigurator to enable new PROOF_OF_RESERVE_ADMIN role usage
 * - V2: assign PROOF_OF_RESERVE_ADMIN role to ProofOfReserveExecutorV2 in AddressProvider
 * - V2: enable tokens for checking against their proof of reserve feed
 * - V3: assign Risk admin role to ProofOfReserveExecutorV3
 * - Transfer aAvaLINK tokens from AAVE treasury to the current address, then withdraw them to get LINK.e
 * - Register V2 and V3 upkeeps for the Chainlink Keeper
 */

contract ProposalPayloadProofOfReserve is Ownable {
  bytes32 public constant PROOF_OF_RESERVE_ADMIN = 'PROOF_OF_RESERVE_ADMIN';

  IProofOfReserveAggregator public immutable aggregator;
  IProofOfReserveExecutor public immutable executorV2;
  IProofOfReserveExecutor public immutable executorV3;
  ICollectorController public immutable collectorController;
  LinkTokenInterface public immutable linkToken;

  address public immutable LENDING_POOL_CONFIGURATOR_IMPL;
  address public immutable PROOF_OF_RESERVE_KEEPER;

  address public constant KEEPER_REGISTRAR = address(0xDb8e8e2ccb5C033938736aa89Fe4fa1eDfD15a1d);

  address public constant COLLECTOR_CONTROLLER =
    address(0xaCbE7d574EF8dC39435577eb638167Aca74F79f0);

  address public constant AAVA_LINK_TOKEN = address(0x191c10Aa4AF7C30e871E70C95dB0E4eb77237530);

  address public constant LINK_TOKEN = address(0x5947BB275c521040051D82396192181b413227A3);

  address public constant KEEPER_REGISTRY = address(0x02777053d6764996e594c3E88AF1D58D5363a2e6);

  /**
   * @dev emitted when the new upkeep is registered in Chainlink
   * @param name name of the upkeep
   * @param upkeepId id of the upkeep in chainlink
   */
  event ChainlinkUpkeepRegistered(string indexed name, uint256 indexed upkeepId);

  constructor(
    address poolConfigurator,
    address aggregatorAddress,
    address executorV2Address,
    address executorV3Address,
    address keeperAddress
  ) {
    LENDING_POOL_CONFIGURATOR_IMPL = poolConfigurator;

    aggregator = IProofOfReserveAggregator(aggregatorAddress);
    executorV2 = IProofOfReserveExecutor(executorV2Address);
    executorV3 = IProofOfReserveExecutor(executorV3Address);
    linkToken = LinkTokenInterface(LINK_TOKEN);
    collectorController = ICollectorController(AaveV3Avalanche.COLLECTOR_CONTROLLER);

    PROOF_OF_RESERVE_KEEPER = keeperAddress;
  }

  function execute() external onlyOwner {
    address[] memory assets = new address[](1);
    assets[0] = address(0x63a72806098Bd3D9520cC43356dD78afe5D386D9);

    address[] memory proofOfReserveFeeds = new address[](1);
    proofOfReserveFeeds[0] = address(0x14C4c668E34c09E1FBA823aD5DB47F60aeBDD4F7);

    // Add pairs of token and its proof of reserves to Proof Of Reserves Aggregator
    for (uint256 i; i < assets.length; i++) {
      aggregator.enableProofOfReserveFeed(assets[i], proofOfReserveFeeds[i]);
    }

    // V2

    // set the new implementation for Pool Configurator to enable PROOF_OF_RESERVE_ADMIN
    AaveV2Avalanche.POOL_ADDRESSES_PROVIDER.setLendingPoolConfiguratorImpl(
      LENDING_POOL_CONFIGURATOR_IMPL
    );

    // set ProofOfReserveExecutorV2 as PROOF_OF_RESERVE_ADMIN
    AaveV2Avalanche.POOL_ADDRESSES_PROVIDER.setAddress(PROOF_OF_RESERVE_ADMIN, address(executorV2));

    // enable checking of proof of reserve for the assets
    executorV2.enableAssets(assets);

    // V3
    // assign RiskAdmin role to ProofOfReserveExecutorV3
    AaveV3Avalanche.ACL_MANAGER.addRiskAdmin(address(executorV3));

    // enable checking of proof of reserve for the assets
    executorV3.enableAssets(assets);

    // transfer aAvaLink token from the treasury to the current address
    IERC20 aavaLinkToken = IERC20(AAVA_LINK_TOKEN);

    collectorController.transfer(aavaLinkToken, address(this), 10100000000000000000);

    // withdraw aAvaLINK from the aave pool and receive LINK.e
    AaveV3Avalanche.POOL.withdraw(LINK_TOKEN, type(uint256).max, address(this));

    // create chainlink upkeep for v2
    registerUpkeep(
      'AaveProofOfReserveKeeperV2',
      PROOF_OF_RESERVE_KEEPER,
      2500000,
      address(this),
      abi.encode(address(executorV2)),
      5000000000000000000,
      0
    );

    // create chainlink upkeep for v3
    registerUpkeep(
      'AaveProofOfReserveKeeperV3',
      PROOF_OF_RESERVE_KEEPER,
      2500000,
      address(this),
      abi.encode(address(executorV3)),
      5000000000000000000,
      0
    );
  }

  function registerUpkeep(
    string memory name,
    address upkeepContract,
    uint32 gasLimit,
    address adminAddress,
    bytes memory checkData,
    uint96 amount,
    uint8 source
  ) internal {
    KeeperRegistryInterface keeperRegistry = KeeperRegistryInterface(KEEPER_REGISTRY);

    (State memory state, Config memory _c, address[] memory _k) = keeperRegistry.getState();
    uint256 oldNonce = state.nonce;
    bytes memory payload = abi.encode(
      name,
      0x0,
      upkeepContract,
      gasLimit,
      adminAddress,
      checkData,
      amount,
      source,
      address(this)
    );

    bytes4 registerSig = KeeperRegistrarInterface.register.selector;

    linkToken.transferAndCall(KEEPER_REGISTRAR, amount, bytes.concat(registerSig, payload));

    (state, _c, _k) = keeperRegistry.getState();

    if (state.nonce == oldNonce + 1) {
      uint256 upkeepID = uint256(
        keccak256(
          abi.encodePacked(blockhash(block.number - 1), address(keeperRegistry), uint32(oldNonce))
        )
      );

      emit ChainlinkUpkeepRegistered(name, upkeepID);
    } else {
      revert('auto-approve disabled');
    }
  }
}
