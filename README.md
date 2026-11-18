# AgentTipJar

A tip jar on **BNB Chain** that **only Agent ID (.ai) holders can use** — both to send and to receive. Agent ID is not a login decoration here: it is the access control, the identity layer and the anti-spam gate of the product's core flow.

Built for the **Binance Wallet × BNB Chain Agent ID Hackathon** (submission period 2026-11-18 → 2026-12-09 UTC).

## How Agent ID is used (core, not cosmetic)

Every state-changing function calls `balanceOf(address)` on the official Agent ID registry (`0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F`, SPACE ID Agent ID, ERC-721 non-transferable):

- `tip(address)` reverts unless **both** sender and receiver hold an Agent ID.
- `setMotto(string)` reverts unless the caller holds an Agent ID.
- The contract counts **distinct Agent ID addresses that interact** (`uniqueAgents`) — the ecosystem metric this product is designed to grow: tipping is a reason for Agent ID holders to find, address and transact with each other by identity instead of by raw address.

## Design choices

- **Non-custodial.** Tips are forwarded to the receiver inside the same transaction. The contract never holds funds.
- **No owner, no admin keys, no pause, no upgrade, no withdrawal function.** There is nothing to rug and nothing to seize; the deployed bytecode is the whole product.
- **Checks-effects-interactions** in `tip()`: all accounting is written before the value transfer; a failed transfer reverts the whole transaction and the tipper keeps the funds.
- **Open source** (MIT) and verified on BscScan.

## Contract

- `src/AgentTipJar.sol` — the product contract.
- Registry: `0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F` (BNB Chain mainnet).
- Mainnet deployment: _to be filled after deploy_ (`TBD_MAINNET` in `web/index.html`).

## Tests

```bash
forge test -vv
```

Unit tests (mock registry) cover: happy-path tipping with accounting, non-holders cannot tip, cannot tip non-holders, motto gating + length limit.

The contract was additionally validated on a **BNB Chain mainnet fork** against the real registry: a real Agent ID holder address passes `isAgent`, a random address does not, and a full tip flow updates `totalTips`, `uniqueAgents` and receiver totals correctly.

## Web app

`web/index.html` — a single-file dApp (ethers.js via CDN): live stats read from the contract over a public RPC, wallet connect, Agent ID status of the connected address, tip form and motto form. Trading is not involved; the page still carries a risk warning because tips are irreversible BNB transfers.

## Safety self-check (hackathon red lines)

- No web QR-code / pairing-code login; no session storage server-side. The dApp uses the standard injected-wallet flow and every transaction is confirmed by the user in their own wallet.
- No approvals requested, ever. No transfers other than the exact tip the user types and confirms.
- No collection of seed phrases, private keys, API secrets or pairing codes.
- No return promises anywhere in the product copy.
- Contract permissions are fully disclosed: there are none beyond the immutable registry address set at deployment.
