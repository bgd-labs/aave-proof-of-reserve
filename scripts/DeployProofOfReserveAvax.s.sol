// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';
import {AaveV2Avalanche, AaveV3Avalanche} from 'aave-address-book/AaveAddressBook.sol';
import {ProofOfReserveAggregator} from '../src/contracts/ProofOfReserveAggregator.sol';
import {ProofOfReserveExecutorV2} from '../src/contracts/ProofOfReserveExecutorV2.sol';
import {ProofOfReserveExecutorV3} from '../src/contracts/ProofOfReserveExecutorV3.sol';
import {ProofOfReserveKeeper} from '../src/contracts/ProofOfReserveKeeper.sol';
import {AvaxBridgeWrapper} from '../src/contracts/AvaxBridgeWrapper.sol';
import {ProposalPayloadProofOfReserve, BridgeWrappers} from '../src/proposal/ProposalPayloadProofOfReserve.sol';

contract Deploy is Script {
  ProofOfReserveAggregator public aggregator;

  address public constant GUARDIAN = 0xa35b76E4935449E33C56aB24b23fcd3246f13470;

  function run() external {
    vm.startBroadcast();

    aggregator = new ProofOfReserveAggregator();
    aggregator.transferOwnership(GUARDIAN);

    ProofOfReserveExecutorV2 executorV2 = new ProofOfReserveExecutorV2(
      address(AaveV2Avalanche.POOL_ADDRESSES_PROVIDER),
      address(aggregator)
    );
    executorV2.transferOwnership(GUARDIAN);

    ProofOfReserveExecutorV3 executorV3 = new ProofOfReserveExecutorV3(
      address(AaveV3Avalanche.POOL_ADDRESSES_PROVIDER),
      address(aggregator)
    );
    executorV3.transferOwnership(GUARDIAN);

    ProofOfReserveKeeper keeper = new ProofOfReserveKeeper();

    // BridgeWrappers memory bridgeWrappers;

    // AAVE.e
    AvaxBridgeWrapper aaveBridgeWrapper = new AvaxBridgeWrapper(
      0x63a72806098Bd3D9520cC43356dD78afe5D386D9, // AAVE.e
      0x8cE2Dee54bB9921a2AE0A63dBb2DF8eD88B91dD9 // Deprecated bridge
    );

    // WETH.e
    AvaxBridgeWrapper wethBridgeWrapper = new AvaxBridgeWrapper(
      0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB, // WETH.e
      0xf20d962a6c8f70c731bd838a3a388D7d48fA6e15 // Deprecated bridge
    );

    // DAI.e
    AvaxBridgeWrapper daiBridgeWrapper = new AvaxBridgeWrapper(
      0xd586E7F844cEa2F87f50152665BCbc2C279D8d70, // DAI.e
      0xbA7dEebBFC5fA1100Fb055a87773e1E99Cd3507a // Deprecated bridge
    );

    // LINK.e
    AvaxBridgeWrapper linkBridgeWrapper = new AvaxBridgeWrapper(
      0x5947BB275c521040051D82396192181b413227A3, // LINK.e
      0xB3fe5374F67D7a22886A0eE082b2E2f9d2651651 // Deprecated bridge
    );

    // WBTC.e
    AvaxBridgeWrapper wbtcBridgeWrapper = new AvaxBridgeWrapper(
      0x50b7545627a5162F82A992c33b87aDc75187B218, // WBTC.e
      0xebEfEAA58636DF9B20a4fAd78Fad8759e6A20e87 // Deprecated bridge
    );

    // create proposal here and pass all the created contracts
    new ProposalPayloadProofOfReserve(
      aggregator,
      executorV2,
      executorV3,
      address(keeper),
      BridgeWrappers({
        aave: address(aaveBridgeWrapper),
        weth: address(wethBridgeWrapper),
        dai: address(daiBridgeWrapper),
        link: address(linkBridgeWrapper),
        wbtc: address(wbtcBridgeWrapper)
      })
    );

    vm.stopBroadcast();
  }
}
