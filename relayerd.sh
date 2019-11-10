#!/bin/sh

relayerd \
	--chain-id=testnet \
	--from=genesis \
	--from-passphrase="12345678" \
	--eth-from-pk="5D862464FE9303452126C8BC94274B8C5F9874CBD219789B3EB2128075A76F72" \
	--eth-filter="0xb125995F5a4766C451cD8C34C4F5CAC89b724571" \
	--eth-node="http://localhost:8545" \
	start

# Use those for a private keyfile:
#	--eth-from="0x0" \
#	--eth-from-passphrase="1234" \
