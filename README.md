# validate_ibc_lightclient_update_proposal.sh

A simple Bash script to validate IBC light client update proposals by comparing the host and reference chain validator set hashes. This script should be compatible with any blockchain built with the [Cosmos SDK](https://github.com/cosmos/cosmos-sdk) 

## Prerequisites

- Bash (with `set -euo pipefail` support)
- `curl`
- `jq`

## Usage

```bash
./validate_ibc_lightclient_update_proposal.sh [--v1] <PROPOSAL_ID> <GOV_CHAIN_LCD>
```

- `<PROPOSAL_ID>`: The ID of the governance proposal to validate.
- `<GOV_CHAIN_LCD>`: The LCD endpoint of the governance (host) chain (e.g., `https://lcd.cosmos.network`).

### Options

- `--v1`: Enable multi-message mode for proposals containing multiple `MsgRecoverClient` entries.  
- `-h, --help`: Show help message and exit.

## What It Does

1. Fetches proposal data (title, summary, client IDs).  
2. For each message, prompts for a reference chain RPC endpoint.  
3. Retrieves the light client state and consensus state on both host and reference chains.  
4. Compares the `next_validators_hash` values and reports whether each client update is valid.

## Example

```bash
# Single-message proposal
./validate_ibc_lightclient_update_proposal.sh 42 https://lcd.chain.example.com
```

```bash
# Multi-message proposal (v1)
./validate_ibc_lightclient_update_proposal.sh --v1 42 https://lcd.chain.example.com
```

## License

MIT
