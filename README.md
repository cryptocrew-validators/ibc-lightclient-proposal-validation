# validate_ibc_lightclient_update_proposal.sh

A simple Bash script to validate IBC light client update proposals by comparing the host and reference chain validator set hashes. This script should be compatible with any blockchain built with the [Cosmos SDK](https://github.com/cosmos/cosmos-sdk) 

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

## Expected Output

The script outputs and validates the consensus states of all involved light clients on host- and reference chain. It is expected that the consensus state hash matches for both subject and substitute client if the consensus states are actually part of the historic ledger of the reference chain.
```bash
Title: IBC light client recovery omnibus for Juno and Mantrachain
Summary: This proposal will update the expired IBC light client `07-tendermint-101` for `juno-1` with the state of client `07-tendermint-311`, and the expired client `07-tendermint-275` for `mantra-1` with the state of client `07-tendermint-312`.

=== Message #1 ===
 subject_client_id = 07-tendermint-101
 substitute_client_id = 07-tendermint-311

Enter REFERENCE_CHAIN_RPC for this message: https://rpc.cosmos.directory:443/juno
  → host client state for 07-tendermint-101
  → host client state for 07-tendermint-311
  → reference header for height 26295351
  → reference header for height 26294346

----------------------------------------
Proposal title: IBC light client recovery omnibus for Juno and Mantrachain
Message #1: subject=07-tendermint-101 substitute=07-tendermint-311
Reference RPC: https://rpc.cosmos.directory:443/juno
  host:      D1B2A5BD74F34DDAA147A06A046BEA53E69F501FA55901DCA6A9DE41B7ADDA12
  reference: D1B2A5BD74F34DDAA147A06A046BEA53E69F501FA55901DCA6A9DE41B7ADDA12
  host:      388DDCB7CDAE59B0A7D9170796961C07CA491A1B9DADFAF047844EEF3A555D14
  reference: 388DDCB7CDAE59B0A7D9170796961C07CA491A1B9DADFAF047844EEF3A555D14
----------------------------------------
✅ subject client valid
✅ substitute client valid


Title: IBC light client recovery omnibus for Juno and Mantrachain
Summary: This proposal will update the expired IBC light client `07-tendermint-101` for `juno-1` with the state of client `07-tendermint-311`, and the expired client `07-tendermint-275` for `mantra-1` with the state of client `07-tendermint-312`.

=== Message #2 ===
 subject_client_id = 07-tendermint-275
 substitute_client_id = 07-tendermint-312

Enter REFERENCE_CHAIN_RPC for this message: https://rpc.cosmos.directory:443/mantrachain
  → host client state for 07-tendermint-275
  → host client state for 07-tendermint-312
  → reference header for height 5313762
  → reference header for height 5313760

----------------------------------------
Proposal title: IBC light client recovery omnibus for Juno and Mantrachain
Message #2: subject=07-tendermint-275 substitute=07-tendermint-312
Reference RPC: https://rpc.cosmos.directory:443/mantrachain
  host:      9BE66136BDCA3C0A1DB5AABDDA616EC809A570E8FA78C91B7EDF7C5CC5024B79
  reference: 9BE66136BDCA3C0A1DB5AABDDA616EC809A570E8FA78C91B7EDF7C5CC5024B79
  host:      9BE66136BDCA3C0A1DB5AABDDA616EC809A570E8FA78C91B7EDF7C5CC5024B79
  reference: 9BE66136BDCA3C0A1DB5AABDDA616EC809A570E8FA78C91B7EDF7C5CC5024B79
----------------------------------------
✅ subject client valid
✅ substitute client valid
```

## License

MIT
