## On-Chain ERC20 Poll & Voting System
A fully on-chain, upgradeable polling and voting platform built with Solidity 0.8.28 and Foundry.
Anyone can create a poll, set custom ERC20 eligibility for voters, and users vote on-chain. Voting logic is upgradeable using OpenZeppelin’s Transparent Proxy pattern

**BASE sepolia deployed contracts**

> ERC20 token : 0x692d0752DbBea2EFf4436a184D4b848Be6eb4db6
>
> Poll Creation : 0x3b9D9ee856C0b9F97fE4c04208B3FB9b59837a11
>
> VotingV1 : 0xb79E2c4cB50F3e6c893EF6A6163e4F77e932887B
>
> Proxy : 0x9e00b3571b47bA228205D05C3B5bAB757B669487
>
> VotingV2 : 0x0126100CDc3c1a78b98BE4a8756520B4601B1481

### Features:

**Any ERC20-Backed Polls**

Anyone can create a poll specifying the ERC20 token voters must hold to participate.

**Upgradeable Voting Logic**

Voting is handled by a logic contract behind a TransparentUpgradeableProxy, enabling seamless logic upgrades (e.g., change voting eligibility, anti-bot measures, weighted voting, etc.).

**Simple & Secure**

Only one poll creation fee (configurable by the admin)

Polls are permanent (poll creation is not upgradeable)

Voting requires users to hold at least 1 unit of the specified ERC20 token (for now)

**Developed with Modern Tooling**

Built using Foundry and OpenZeppelin Contracts

### Contracts Overview:

**PollCreation.sol**

Function: Allows anyone to create a poll, specifying the question, options, voting window, and ERC20 token for eligibility.

Logic: Not behind a proxy—poll creation is not upgradeable, so it will not change over time.

**VotingV1.sol**

Function: Handles all voting logic and tracks votes.

Upgradeable: Deployed behind a TransparentUpgradeableProxy so voting logic can evolve (e.g., stricter eligibility, new rules, bugfixes) without losing poll/vote data.

### Quickstart (Foundry):

#### Clone and install

```shell
git clone https://github.com/RoySudipAvi/on-chain-poll-transparent-upgradeable
cd on-chain-poll-transparent-upgradeable
forge install
```

#### Build contracts

```shell
forge build
```

#### Test contracts

```shell
forge test
```
#### Deploy

Follow the Makifile for easier deployment.
For example, to deploy the PollCreation contract first assign values to all the variable mentioned in Makefile,
then run the the following to deploy on base sepolia.

```shell
make deploy CONTRACT=PollCreation NETWORK=base_sepolia
```

### Requirements:

Foundry

Solidity 0.8.28

OpenZeppelin Contracts

### License:

MIT

