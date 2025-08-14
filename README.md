# 🎤 Event Ticket with Resale Royalty — Smart Contract

## ✨ What

A **Remix-friendly ERC-721 ticketing smart contract** that allows:

- **Primary sales** (organizer → buyer) at a fixed price.
- **Secondary sales** (owner → new buyer) with **automatic royalty** payment to the organizer.
- **No direct transfers** — tickets can only change hands via the contract, ensuring royalties cannot be bypassed.
 
This is a **self-contained** contract (no OpenZeppelin imports) so it **compiles instantly in Remix IDE**.

---

## 💡 Why

In traditional ticketing:

- Organizers often lose out on revenue from resold tickets.
- Scalpers can buy and sell at inflated prices without sharing profits.
- Tracking resale transactions is difficult and often off-chain.

With this contract:

- **👑 Organizers always benefit** — a % of every resale is automatically sent to them.
- **🧯 Scalping deterrent** — royalty collection adds a cost to quick resales.
- **📜 Transparent records** — every ticket issuance and resale is stored on-chain.
- **🚫 No royalty evasion** — all transfers are handled by the contract, and peer-to-peer transfers are blocked.

---

## 🧱 Features

- **Mint tickets** individually with a token ID and metadata URI.
- **Set primary sale price** for each ticket (can be zero to skip primary sales).
- **Buy tickets** directly from the organizer during the primary sale phase.
- **List tickets for resale** with your chosen price.
- **Automatic royalty split** when resold:
  - Organizer gets `(price × royaltyBps / 10000)`.
  - Seller gets the remainder.
- **Prevent bypass** of royalty by disabling direct `transferFrom`.

---

## 🔄 Ticket Lifecycle

1. **Organizer mints ticket**  
   → Can set a primary price for initial sale.

2. **Buyer purchases from organizer** (primary sale)  
   → 100% of payment goes to organizer.

3. **Owner lists ticket for resale** (secondary sale)  
   → NFT moves into escrow (contract).

4. **New buyer purchases**  
   → Royalty auto-sent to organizer, remainder to seller, NFT to buyer.

---

## 📦 Functions Overview

| Function                                              | Purpose                                              |
| ----------------------------------------------------- | ---------------------------------------------------- |
| `mintTicket(tokenId, uri, primaryPriceWei, receiver)` | Mint new ticket (to organizer or specified receiver) |
| `buyPrimary(tokenId)`                                 | Buy ticket from organizer at primary price           |
| `listForResale(tokenId, priceWei)`                    | List owned ticket for resale                         |
| `cancelListing(tokenId)`                              | Cancel resale listing                                |
| `buyResale(tokenId)`                                  | Buy ticket from resale listing                       |
| `ownerOf(tokenId)`                                    | Get current owner of ticket                          |
| `tokenURI(tokenId)`                                   | Get ticket metadata URI                              |

---

## 🚀 Deployment (Remix IDE)

1. Go to [Remix IDE](https://remix.ethereum.org)
2. Create file `EventTicketRoyalty.sol`
3. Paste the **self-contained contract** (no imports).
4. Compile with Solidity `0.8.24`.
5. Deploy with constructor inputs:
   - `_name`: `"Concert2025"`
   - `_symbol`: `"C25"`
   - `_organizer`: Your wallet address
   - `_royaltyBps`: `500` (for 5% royalty)

---
