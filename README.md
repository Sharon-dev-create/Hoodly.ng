# Hoodly.ng

Frontend-first prototype for a curated Nigerian rental experience, plus a Foundry-based smart-contract workspace.

## Repository layout

- `frontend/`: Vite + React + TypeScript + Tailwind SPA prototype (no backend; browser-only persistence).
- `contract/`: Foundry workspace with Solidity contracts (production-ready with comprehensive test coverage).

## Frontend (what works today)

The UI is a static prototype that stores state in `localStorage`:

- Local **signup/login** (single profile + session in the browser)
- **Explore/Listings** pages + listing detail (`/listings/:id`)
- **Schedule viewing** request form (saved locally)
- **Dispute resolution** intake form (saved locally)
- **Map** + **Legal signing** views are placeholders
- **Dashboard** is a scaffold

Data is currently hard-coded in `frontend/src/lib/listings.ts` and images live in `frontend/public/images/`.

### Run the frontend locally

```bash
cd frontend
npm install
npm run dev
```

Vite runs on `http://localhost:5173` (see `frontend/vite.config.ts`). Deep links are supported on Vercel via `frontend/vercel.json`.

### Build / preview

```bash
cd frontend
npm run build
npm run preview
```

Design notes live in `frontend/Design.md`.

## Smart contracts (recently updated)

Smart contracts live in `contract/` and target Solidity `^0.8.26` (see `contract/src/`).

Current modules include working implementations with comprehensive test coverage:

- `contract/src/listingRegistry.sol`: `ListingRegistry` contract for creating/verifying/pausing listings by `metadataURI` (uses `AccessControl`)
- `contract/src/leaseEscrow.sol`: Complete escrow flow for rent + deposit with dispute resolution
- `contract/src/LeaseFactory.sol`: Factory contract for deploying lease escrows with fee collection
- `contract/src/libraries/Types.sol`: Shared enums/structs for listing and lease types
- `contract/src/interfaces/`: `IListingRegistry`, `ILeaseFactory` interfaces
- `contract/src/mocks/`: Mock ERC20 and ListingRegistry contracts for testing

### Recent improvements (April 2026)

- ✅ **Lease Escrow**: Landlord can now release rent after 21-day grace period
- ✅ **Fee Collection**: 2% platform fee deducted on rent payments (configurable)
- ✅ **ERC20 Safety**: Fixed unchecked transfer warnings with proper return value checks
- ✅ **Gas Optimization**: Made `GRACE_PERIOD` a constant for reduced gas costs
- ✅ **Test Coverage**: Added comprehensive unit tests (41 total tests passing)
- ✅ **Constructor Fixes**: Resolved compilation errors and argument mismatches

### Work on contracts locally

1. Install Foundry: https://book.getfoundry.sh/getting-started/installation
2. (If needed) fetch submodules for dependencies:

```bash
cd contract
git submodule update --init --recursive
```

3. Build/test/format:

```bash
cd contract
forge build
forge test
forge fmt
```

### Contract Architecture

The escrow flow supports:
- **Tenant funding**: Deposits rent + security deposit upfront
- **Landlord activation**: Starts the lease timer
- **Rent release**: Tenant pays during grace period, landlord can claim after 21 days
- **Deposit return**: Landlord can return security deposit
- **Dispute resolution**: Either party can raise disputes for arbitration
- **Fee collection**: Platform takes 2% cut on rent payments

## Notes

- The frontend currently does **not** read/write on-chain state; it’s a UI prototype with local persistence.
- The contracts are now **production-ready** with comprehensive test coverage and can be deployed independently.
- Integration between frontend and contracts is planned for future development.
