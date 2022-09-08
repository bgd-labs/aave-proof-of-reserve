// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LinkTokenInterface} from 'chainlink-brownie-contracts/interfaces/LinkTokenInterface.sol';
import {KeeperRegistryInterface, Config, State} from 'chainlink-brownie-contracts/interfaces/KeeperRegistryInterface.sol';
import {KeeperRegistrarInterface} from './KeeperRegistrarInterface.sol';
import {ILendingPoolAddressesProvider} from 'aave-address-book/AaveV2.sol';
import {IACLManager} from 'aave-address-book/AaveV3.sol';
import {IProofOfReserveAggregator} from '../interfaces/IProofOfReserveAggregator.sol';
import {IProofOfReserveExecutor} from '../interfaces/IProofOfReserveExecutor.sol';
import {ICollectorController} from '../dependencies/ICollectorController.sol';
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
 * - V2: enable tokens for checking against their proof of reserfe feed
 * - V3: assign Risk admin role to ProofOfReserveExecutorV3
 * - Transfer aAvaLINK tokens from AAVE treasury to the current address, then withdraw them to get LINK.e
 * - Register V2 and V3 upkeeps for the Chainlink Keeper
 */

contract ProposalPayloadProofOfReserve is Ownable {
  bytes32 public constant PROOF_OF_RESERVE_ADMIN = 'PROOF_OF_RESERVE_ADMIN';

  address public constant LENDING_POOL_CONFIGURATOR_IMPL = address(0);
  address public constant PROOF_OF_RESERVE_AGGREGATOR = address(0);
  address public constant PROOF_OF_RESERVE_EXECUTOR_V2 = address(0);
  address public constant PROOF_OF_RESERVE_EXECUTOR_V3 = address(0);
  address public constant PROOF_OF_RESERVE_KEEPER = address(0);

  address[] public ASSETS = [address(0), address(1)];
  address[] public PROOF_OF_RESERVE_FEEDS = [address(10), address(11)];

  address public constant KEEPER_REGISTRAR =
    address(0xDb8e8e2ccb5C033938736aa89Fe4fa1eDfD15a1d);

  ICollectorController public collectorController =
    ICollectorController(address(0xaCbE7d574EF8dC39435577eb638167Aca74F79f0));

  IERC20 public aavaLinkToken =
    IERC20(address(0x191c10Aa4AF7C30e871E70C95dB0E4eb77237530));

  address public constant LINK_TOKEN =
    address(0x5947BB275c521040051D82396192181b413227A3);

  LinkTokenInterface public linkToken =
    LinkTokenInterface(address(0x5947BB275c521040051D82396192181b413227A3));

  KeeperRegistryInterface public keeperRegistry =
    KeeperRegistryInterface(
      address(0x02777053d6764996e594c3E88AF1D58D5363a2e6)
    );

  function execute() external onlyOwner {
    // Aggregator
    IProofOfReserveAggregator aggregator = IProofOfReserveAggregator(
      PROOF_OF_RESERVE_AGGREGATOR
    );

    // Add pairs of token and its proof of reserves to Proof Of Reserves Aggregator
    for (uint256 i; i < ASSETS.length; i++) {
      aggregator.enableProofOfReserveFeed(ASSETS[i], PROOF_OF_RESERVE_FEEDS[i]);
    }

    // V2
    ILendingPoolAddressesProvider addressesProvider = AaveV2Avalanche
      .POOL_ADDRESSES_PROVIDER;

    // set the new implementation for Pool Configurator to enable PROOF_OF_RESERVE_ADMIN
    addressesProvider.setLendingPoolConfiguratorImpl(
      LENDING_POOL_CONFIGURATOR_IMPL
    );
    // TODO: init and initReserves

    // set ProofOfReserveExecutorV2 as PROOF_OF_RESERVE_ADMIN
    addressesProvider.setAddress(
      PROOF_OF_RESERVE_ADMIN,
      PROOF_OF_RESERVE_EXECUTOR_V2
    );

    IProofOfReserveExecutor executorV2 = IProofOfReserveExecutor(
      PROOF_OF_RESERVE_EXECUTOR_V2
    );

    // enable checking of proof of reserve for the assets
    for (uint256 i; i < ASSETS.length; i++) {
      executorV2.enableAsset(ASSETS[i]);
    }

    // V3
    IACLManager aclManager = AaveV3Avalanche.ACL_MANAGER;

    // assign RiskAdmin role to ProofOfReserveExecutorV3
    aclManager.addRiskAdmin(PROOF_OF_RESERVE_EXECUTOR_V3);

    IProofOfReserveExecutor executorV3 = IProofOfReserveExecutor(
      PROOF_OF_RESERVE_EXECUTOR_V3
    );

    // enable checking of proof of reserve for the assets
    for (uint256 i; i < ASSETS.length; i++) {
      executorV3.enableAsset(ASSETS[i]);
    }

    // transfer aAvaLink token from the treasury to the current address
    collectorController.transfer(
      aavaLinkToken,
      address(this),
      10100000000000000000
    );

    // withdraw aAvaLINK from the aave pool and receive LINK.e
    AaveV3Avalanche.POOL.withdraw(LINK_TOKEN, type(uint256).max, address(this));

    // create chainlink upkeep for v2
    registerUpkeep(
      'AaveProofOfReserveKeeperV2',
      PROOF_OF_RESERVE_KEEPER,
      2500000,
      address(this),
      abi.encode(PROOF_OF_RESERVE_EXECUTOR_V2),
      5000000000000000000,
      0
    );

    // create chainlink upkeep for v3
    registerUpkeep(
      'AaveProofOfReserveKeeperV3',
      PROOF_OF_RESERVE_KEEPER,
      2500000,
      address(this),
      abi.encode(PROOF_OF_RESERVE_EXECUTOR_V3),
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
    (State memory state, Config memory _c, address[] memory _k) = keeperRegistry
      .getState();
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

    linkToken.transferAndCall(
      KEEPER_REGISTRAR,
      amount,
      bytes.concat(registerSig, payload)
    );

    (state, _c, _k) = keeperRegistry.getState();

    uint256 newNonce = state.nonce;
    if (newNonce == oldNonce + 1) {
      // uint256 upkeepID = uint256(
      //   keccak256(
      //     abi.encodePacked(
      //       blockhash(block.number - 1),
      //       address(keeperRegistry),
      //       uint32(oldNonce)
      //     )
      //   )
      // );
      // TODO: do we need to save upkeepId somewhere ?
    } else {
      revert('auto-approve disabled');
    }
  }
}
