import {
  CollateralClaimed,
  CollateralCommitted,
  CollateralDeposited,
  CollateralEscrowDeployed,
  CollateralWithdrawn
} from "../../generated/CollateralManager/CollateralManager";
import { Bid } from "../../generated/schema";
import { BidStatus } from "../helpers/bid";
import { loadBidById, loadCollateral } from "../helpers/loaders";
import { updateBidStatus, updateCollateral } from "../helpers/updaters";

export function handleCollateralEscrowDeployed(
  event: CollateralEscrowDeployed
): void {
  const bid: Bid = loadBidById(event.params._bidId);
  bid.collateralEscrow = event.params._collateralEscrow;
  bid.save();
}

export function handleCollateralEscrowDeployeds(
  events: CollateralEscrowDeployed[]
): void {
  events.forEach(event => {
    handleCollateralEscrowDeployed(event);
  });
}

export function handleCollateralCommitted(event: CollateralCommitted): void {
  // Load collateral by bidId and collateral address
  const collateral = loadCollateral(
    event.params._bidId.toString(),
    event.params._collateralAddress,
    collateralTypeToTokenType(event.params._type),
    event.params._tokenId
  );
  updateCollateral(collateral, event);
  collateral.status = "Committed";
  collateral.save();
}

export function handleCollateralCommitteds(
  events: CollateralCommitted[]
): void {
  events.forEach(event => {
    handleCollateralCommitted(event);
  });
}

export function handleCollateralDeposited(event: CollateralDeposited): void {
  const collateral = loadCollateral(
    event.params._bidId.toString(),
    event.params._collateralAddress,
    collateralTypeToTokenType(event.params._type),
    event.params._tokenId
  );
  updateCollateral(collateral, event);
  collateral.status = "Deposited";
  collateral.save();
}

export function handleCollateralDepositeds(
  events: CollateralDeposited[]
): void {
  events.forEach(event => {
    handleCollateralDeposited(event);
  });
}

export function handleCollateralWithdrawn(event: CollateralWithdrawn): void {
  const collateral = loadCollateral(
    event.params._bidId.toString(),
    event.params._collateralAddress,
    collateralTypeToTokenType(event.params._type),
    event.params._tokenId
  );
  updateCollateral(collateral, event);
  collateral.receiver = event.params._recipient;
  collateral.status = "Withdrawn";
  collateral.save();
}

/**
 * Converts the collateral type to the token type. Collateral type enum on the contract is:
 * enum CollateralType {
 *   ERC20,
 *   ERC721,
 *   ERC1155
 * }
 * and the token type enum for Subgraph has 1 extra value for UNKNOWN
 *
 * @param type
 */
function collateralTypeToTokenType(type: i32): i32 {
  return i32.add(type, 1);
}

export function handleCollateralWithdrawns(
  events: CollateralWithdrawn[]
): void {
  events.forEach(event => {
    handleCollateralWithdrawn(event);
  });
}

/**
 * Sets the bid status to `Liquidated` when the collateral is claimed from a defaulted loan.
 * @param event
 */
export function handleCollateralClaimed(event: CollateralClaimed): void {
  const bid = loadBidById(event.params._bidId);
  updateBidStatus(bid, BidStatus.Liquidated);
}

export function handleCollateralClaimeds(events: CollateralClaimed[]): void {
  events.forEach(event => {
    handleCollateralClaimed(event);
  });
}
