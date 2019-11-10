# Injective-Core

Home of the following services:

* [relayerd](/cmd/relayerd)
* [relayer-api](/cmd/relayer-api)

## Overall diagram

<img alt="diagram-injective.png" src="https://cl.ly/f9077bd91d24/download/diagram-injective.png" width="700px"/>



## Installation

### Getting releases

Navigate to 
https://github.com/InjectiveLabs/injective-core-releases/releases

### Using Docker

The most convenient way to launch services is by using the provided Docker container:

```bash
$ docker run --rm docker.injective.dev/injective-core relayerd -h
$ docker run --rm docker.injective.dev/injective-core relayer-api -h
```

### Setting up a node

```bash
$ relayerd init [your_custom_moniker] --chain-id testnet
```

You can edit this `moniker` later, in the `~/.relayerd/config/config.toml` file:

```toml
# A custom human readable name for this node
moniker = "<your_custom_moniker>"
```

The home directory of this node is `~/.relayerd` by default.

#### Creating validator

Step 1: Generate a new key

```bash
$ relayerd keys add genesis

$ relayerd keys show genesis -a
cosmos19pa62ludsjmrekx6ygts92h224n95ku2whkxpz
```

Step 2: Create a genesis account

```bash
$ relayerd add-genesis-account $(relayerd keys show genesis -a) 100000000000stake,10000000000atom
```

Step 3: Add a validator in genesis state

```bash
$ relayerd gentx --name genesis --amount 1000000000stake
$ relayerd collect-gentxs
```

## Running a Relayer

To start up a Relayer daemon node (Tendermint/Cosmos), which also has built-in gRPC server:

```bash
$ relayerd \
    --chain-id=testnet \
    --from=genesis \
    --from-passphrase="12345678" \
    --eth-from-pk="5D862464FE9303452126C8BC94274B8C5F9874CBD219789B3EB2128075A76F72" \
    --eth-filter="0xb125995F5a4766C451cD8C34C4F5CAC89b724571" \
    --eth-node="http://localhost:8545" \
    start
```

You can also use script `./relayerd.sh` and edit it. By default relayerd starts with these options:

* `--chain-id` specifies Cosmos chain id and must match the name set at genesis stage;
* `--from` sets the name of wallet that will be used to sign Cosmos transactions;
* `--from-passphrase` sets the passphrase for relayer's Cosmos wallet, for signing internal transactions;
* `--eth-from-pk` is a private key for Ethereum wallet, it will be used to send transactions to Ethereum, this is INSECURE AND ONLY FOR TESTING, refer to sections below and use `--eth-from` instead.
* `--eth-filter` is the address of Injective Filter contract on the Ethereum network;
* `--eth-node` is the Ethereum network node RPC API endpoint;

## Exposing Relayer REST API

By default `relayerd` RPC server listens on `grpc://localhost:9900`.

Then, in a separate process you can start an additional Relayer's REST API server that exposes SRAv2:

```
$ relayer-api

INFO[0000] HTTP "AssetPairs" mounted on GET /api/v2/asset_pairs
INFO[0000] HTTP "Orders" mounted on GET /api/v2/orders
INFO[0000] HTTP "OrderByHash" mounted on GET /api/v2/order/{orderHash}
INFO[0000] HTTP "Orderbook" mounted on GET /api/v2/orderbook
INFO[0000] HTTP "OrderConfig" mounted on POST /api/v2/order_config
INFO[0000] HTTP "FeeRecipients" mounted on GET /api/v2/fee_recipients
INFO[0000] HTTP "PostOrder" mounted on POST /api/v2/order
INFO[0000] HTTP "TakeOrder" mounted on POST /api/rest/takeOrder
INFO[0000] HTTP "GetActiveOrder" mounted on GET /api/rest/getActiveOrder
INFO[0000] HTTP "GetArchiveOrder" mounted on GET /api/rest/getArchiveOrder
INFO[0000] HTTP "ListOrders" mounted on POST /api/rest/listOrders
INFO[0000] HTTP "GetTradePair" mounted on GET /api/rest/getTradePair
INFO[0000] HTTP "ListTradePairs" mounted on POST /api/rest/listTradePairs
INFO[0000] HTTP "GetAccount" mounted on GET /api/rest/getAccount
INFO[0000] HTTP "GetOnlineAccounts" mounted on GET /api/rest/getOnlineAccounts
INFO[0000] HTTP "GetEthTransactions" mounted on POST /api/rest/getEthTransactions
...
INFO[0000] HTTP server starting                          URI="http://localhost:4444"
...
```

Notice that by default this HTTP server listens on `http://localhost:4444`. When Relayer API server starts, it connects to the Relayer daemon using gRPC protocol, you should see no warnings about connectivity and also in `relayerd` logs the following lines are mandatory:

```
I[2019-10-19|18:11:04.383] [RPC]                                        module=main id=UZuQBaJU method=/relayer_daemon.RelayerDaemon/Ping bytes=0
I[2019-10-19|18:11:04.383] [RPC]                                        module=main id=UZuQBaJU status=OK bytes=0 time=97.233µs
```

**NOTE! API is divided in two namespaces:**

* `/api/v2` is the [Standard Relayer API v2](https://github.com/0xProject/standard-relayer-api/blob/master/http/v2.md) implementation;
* `/api/rest` is a group of useful methods specific to our project and may change in the future.

## Running a validator that submits to Ethereum

In order to report to Ethereum, a validator must publish itself as an online peer. To do that, a key needs to be specified and `chain-id` to send Tednermint Txs. After start, validator starts to send MsgPing and will shutdown with a MsgLogOff tx. That will allow to participate in leaders selection to submit current trades into Ethereum.

* `--chain-id` specifies Cosmos chain id and must match the name set at genesis stage;
* `--from` sets the name of wallet that will be used to sign Cosmos transactions;
* `--from-passphrase` sets the passphrase for relayer's Cosmos wallet, for signing internal transactions;

And in order to sign Ethereum transactions for the Injective Filter smart contract, relayerd operator must provide a private key for Ethereum wallet that has value enough to pay gas and is a stake participant. There is two ways to provide a PK — `--eth-from-pk` option showed in previous section is insecure and only for testing purposes.

To provide Ethereum key, use those two options:

* `--eth-from` specifies Ethereum wallet address that will be used to pay for gas and will be checked for stake, after the transaction gets into Ethereum smart contract.
* `--eth-from-passphrase` is the passphrase for encrypted keyfile ([Ethereum Keyfile](https://github.com/ethereum/go-ethereum/wiki/Managing-your-accounts)).

All encrypted keyfiles must be placed into `~/.relayerd/eth/keystore` in order to be found. The name of the file doesn't matter.

**Example of new private keyfile creation**:

```
$ geth account new --keystore ~/.relayerd/eth/keystore/

Your new account is locked with a password. Please give a password. Do not forget this password.
Passphrase:
Repeat passphrase:
Address: {f91fb1573394a069aa0f68a3f03cd4a5e42cc3e5}
```

**Example relayerd with private keyfile:**

```
$ relayerd \
    --chain-id=testnet \
    --from=genesis \
    --from-passphrase="12345678" \
    --eth-from="0xf91fb1573394a069aa0f68a3f03cd4a5e42cc3e5" \
    --eth-from-passphrase="1234" \
    --eth-filter="0xb125995F5a4766C451cD8C34C4F5CAC89b724571" \
    --eth-node="http://localhost:8545" \
    start
```

## Maintenance

To run all unit tests:

```bash
$ make test
```

To check the coverage:

```bash
$ make cover

# opens browser with coverage report
```
