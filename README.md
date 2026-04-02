# Hoodly.ng

Frontend-first prototype for a curated Nigerian rental experience, plus a Foundry-based smart-contract workspace (WIP).

## Repository layout

- `frontend/`: Vite + React + TypeScript + Tailwind SPA prototype (no backend; browser-only persistence).
- `contract/`: Foundry workspace with Solidity contracts (scaffolding / incomplete; not wired to the UI yet).

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

## Smart contracts (WIP / not integrated yet)

Smart contracts live in `contract/` and target Solidity `^0.8.26` (see `contract/src/`).

Current modules are **scaffolding** with stubbed / incomplete implementations:

- `contract/src/listingRegistry.sol`: `ListingRegistry` intended to create/verify/pause listings by `metadataURI` (uses `AccessControl`)
- `contract/src/leaseEscrow.sol`: escrow flow skeleton for rent + deposit
- `contract/src/DisputeManager.sol`: dispute flow skeleton
- `contract/src/libraries/Types.sol`: shared enums/structs (listing + lease types)
- `contract/src/interfaces/`: `IListingRegistry`, `ILeaseFactory` interfaces for planned integrations

### Work on contracts locally

1. Install Foundry: https://book.getfoundry.sh/getting-started/installation
2. (If needed) fetch submodules for dependencies:

```bash
cd contract
git submodule update --init --recursive
```

3. Build/format (note: contracts may not compile until stubs are implemented):

```bash
cd contract
forge build
forge fmt
```

## Notes

- The frontend currently does **not** read/write on-chain state; it’s a UI prototype with local persistence.
- The contracts directory is early-stage scaffolding and needs implementation + tests before deployment scripts make sense.
