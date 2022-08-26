// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ProposalPayloadProofOfReserve
 * @author BGD Labs
 * @dev Proposal to deploy Proof Of Reserve and enable it as proofOfReserve admin for V2 and risk admin for V3.
 * - Add tokens and their proof of reserves to registry
 * - V2: upgrade implementation of LendingPoolConfigurator to enable new PROOF_OF_RESERVE_ADMIN role usage
 * - V2: assign PROOF_OF_RESERVE_ADMIN role to ProofOfReserveExecutorV2
 * - V2: enable tokens for checking against their proof of reserfe feed
 * - V3: assign Risk admin role to ProofOfReserveExecutorV3
 * - V3: enable tokens for checking against their proof of reserfe feed
 */
contract ProposalPayloadProofOfReserve {
  function execute() external {}
}
