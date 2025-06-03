# Installation
`npm i && forge build`

# Compile
`forge build`

# Test
PreRequisites: Build Go Binary
Run `./scripts/go/build.sh` from the root directory

Test with `./scripts/go/bin/differential-testing getProveWithdrawalTransactionInputs 0 0xe05fcC23807536bEe418f142D19fa0d21BB0cfF7 0x0376AAc07Ad725E01357B1725B5ceC61aE10473c 100 100000 0x`

# Update to latest version of <PACKAGE>
`git submodule update --init --remote lib/<PACKAGE>`

# Update to FIXED version of optimism
`cd lib/optimism && git checkout -b frax-fixed-856c 856c08bf84d9aa829d1e764fc8e9a37d41960ba0`

<!-- After origin/alex/fix-fraxtal-tests -->
`cd lib/optimism && git checkout e6ef3a900c42c8722e72c2e2314027f85d12ced5`

# VoteEscrowedFXS testing
MAKE SURE TO SET YOUR .env FOUNDRY_PROFILE="fraxtal" or FOUNDRY_PROFILE="vefxs" or FOUNDRY_PROFILE="miscellany" DUE TO SOLC VERSIONING ISSUES
MAKE SURE TO SET YOUR .env FOUNDRY_PROFILE="fraxtal" or FOUNDRY_PROFILE="vefxs" or FOUNDRY_PROFILE="miscellany" DUE TO SOLC VERSIONING ISSUES
MAKE SURE TO SET YOUR .env FOUNDRY_PROFILE="fraxtal" or FOUNDRY_PROFILE="vefxs" or FOUNDRY_PROFILE="miscellany" DUE TO SOLC VERSIONING ISSUES
```clear && source .env && forge test --fork-url $MAINNET_RPC_URL --match-test test_E2E_Main -vvvvv```
```clear && source .env && forge test --fork-url $MAINNET_RPC_URL --match-test testFuzz_E2E -vvvvv```
```clear && source .env && forge test --fork-url $MAINNET_RPC_URL --match-path ./src/test/fuzz/Fuzz_Test_VoteEscrowedFXS.t.sol -vvvvv```
```clear && source .env && forge test --fork-url $MAINNET_RPC_URL --match-path ./src/test/VestedFXS-and-Flox/e2e/E2E_VeFXS.t.sol --match-contract Fuzz_MegaTest_VeFXS -vvvvv```

```clear && source .env && forge test --fork-url $MAINNET_RPC_URL --match-path ./src/test/fuzz/Fuzz_Test_VoteEscrowedFXS.t.sol --match-test testFuzz_IncreaseUnlockTime -vvvvv```
```clear && source .env && forge test --fork-url $MAINNET_RPC_URL --match-test test_createLock -vvvvv```
```clear && source .env && forge test --fork-url $MAINNET_RPC_URL --match-test testFuzz_GetAllActiveLocksOf -vvvvv```
```clear && source .env && forge test --fork-url $MAINNET_RPC_URL --match-test test_BulkGetAllActiveLocksOf -vvvvv```
```clear && source .env && forge test --fork-url $MAINNET_RPC_URL --match-test test_veFXS_Combi_Big -vvvvv```
```clear && source .env && forge test --fork-url $MAINNET_RPC_URL --match-contract Unit_Test_VestedFXSUtils -vvvvv```
```clear && source .env && forge test --fork-url $MAINNET_RPC_URL --match-path ./src/test/VestedFXS-and-Flox/e2e/E2E_VeFXS.t.sol --match-contract Fuzz_MegaTest_VeFXS --match-test testFuzz_E2E -vvvvv```
```clear && source .env && forge test --fork-url $MAINNET_RPC_URL --match-test Fuzz_Test_VestedFXS -vvvvv```
```clear && source .env && forge test --fork-url $MAINNET_RPC_URL --match-contract Unit_Test_VoteEscrowedFXSYieldDistributor --match-test test_CheckpointNormal -vvvvv```


### Deploy
```source .env && forge script src/script/VestedFXS-and-Flox/DeployL1VeFXSTotalSupplyOracle.s.sol:DeployL1VeFXSTotalSupplyOracle --chain-id 252 --with-gas-price 2500000 --rpc-url $FRAXTAL_RPC_URL --verifier-url $FRAXSCAN_API_URL --etherscan-api-key $FRAXTAL_API_KEY --optimize --optimizer-runs 100000 --use "0.8.26" --evm-version "cancun" --private-key $ROPSTEN_ONE_PKEY --broadcast``

```source .env && forge script src/script/VestedFXS-and-Flox/DeployFPISLocker.s.sol:DeployFPISLocker --chain-id 252 --with-gas-price 2500000 --rpc-url $FRAXTAL_RPC_URL --verifier-url $FRAXSCAN_API_URL --etherscan-api-key $FRAXTAL_API_KEY --optimize --optimizer-runs 10000 --use "0.8.23" --evm-version "paris" --private-key $ROPSTEN_ONE_PKEY --broadcast```

```source .env && forge script src/script/VestedFXS-and-Flox/DeployVeFXSAggregator.s.sol:DeployVeFXSAggregator --chain-id 252 --with-gas-price 2500000 --rpc-url $FRAXTAL_RPC_URL --verifier-url $FRAXSCAN_API_URL --etherscan-api-key $FRAXTAL_API_KEY --optimize --optimizer-runs 100000 --use "0.8.26" --evm-version "cancun" --private-key $ROPSTEN_ONE_PKEY --broadcast``

```source .env && forge script src/script/VestedFXS-and-Flox/DeployVestedFXS.s.sol:DeployVestedFXS --chain-id 252 --with-gas-price 2500000 --rpc-url $FRAXTAL_RPC_URL --verifier-url $FRAXSCAN_API_URL --etherscan-api-key $FRAXTAL_API_KEY --evm-version "paris" --private-key $ROPSTEN_ONE_PKEY --broadcast```

```source .env && forge script src/script/VestedFXS-and-Flox/DeployYieldDistributor.s.sol:DeployYieldDistributor --chain-id 252 --with-gas-price 2500000 --rpc-url $FRAXTAL_RPC_URL --verifier-url $FRAXSCAN_API_URL --etherscan-api-key $FRAXTAL_API_KEY --optimize --optimizer-runs 100000 --use "0.8.26" --evm-version "cancun" --private-key $ROPSTEN_ONE_PKEY --broadcast```

### Upgrade

```source .env && forge script src/script/VestedFXS-and-Flox/UpgradeFPISLocker.s.sol:UpgradeFPISLocker --chain-id 252 --with-gas-price 2500000 --rpc-url $FRAXTAL_RPC_URL --verifier-url $FRAXSCAN_API_URL --etherscan-api-key $FRAXTAL_API_KEY --optimize --optimizer-runs 200 --use "0.8.23" --evm-version "paris" --private-key $ROPSTEN_ONE_PKEY --broadcast```


### Verification


<!-- If you deployed it with forge here -->
<!-- veFXS Implementation -->
```source .env && forge verify-contract --chain-id 252 --watch --num-of-optimizations 10000 --etherscan-api-key $FRAXTAL_API_KEY 0x54bd5c72645fed784C117cA83533e0584b24Ee5c src/contracts/VestedFXS-and-Flox/VestedFXS/VestedFXS.sol:VestedFXS```

```source .env && forge verify-contract --chain-id 252 --watch --num-of-optimizations 10000 --etherscan-api-key $FRAXTAL_API_KEY 0x2816Ab1F4Db656602b6B0041c006652A4F5D0437 src/contracts/VestedFXS-and-Flox/VestedFXS/VeFXSYieldDistributor.sol```

<!-- veFXS Proxy -->
1) https://fraxscan.com/proxycontractchecker?a=0xABCDEF123456
2) ```source .env && forge verify-contract --chain-id 252 --watch --optimize --num-of-optimizations 10000 --evm-version "paris" --etherscan-api-key $FRAXTAL_API_KEY --constructor-args $(cast abi-encode "constructor(address)" "0x4600d3b12c39af925c2c07c487d31d17c1e32a35" true) 0x007FD070a7E1B0fA1364044a373Ac1339bAD89CF src/script/VestedFXS-and-Flox/Proxy.sol:Proxy```
3) OR (2) but with --show-standard-json-input and paste that into the verifier
MAKE SURE CONSTRUCTOR ARGS ARE MANUALLY SET TO JUST 0000000000000000000000004600d3b12c39af925c2c07c487d31d17c1e32a35, not the guessed one.
0000000000000000000000004600d3b12c39af925c2c07c487d31d17c1e32a35
000000000000000000000000625e700125ff054f75e5348497cbfab1ee4b7a40

```source .env && forge verify-contract --chain-id 252 --watch --optimizer-runs 100000 --evm-version "cancun" --etherscan-api-key $FRAXTAL_API_KEY --constructor-args $(cast abi-encode "constructor(address)" "0x4600d3b12c39af925c2c07c487d31d17c1e32a35" true) 0x41D9d23F52fB573e521eE882bc752D4e18299480 src/script/VestedFXS-and-Flox/Proxy.sol:Proxy```

```source .env && forge verify-contract --chain-id 252 --watch --num-of-optimizations 10000 --etherscan-api-key $FRAXTAL_API_KEY --constructor-args $(cast abi-encode "constructor(address)" "0x007FD070a7E1B0fA1364044a373Ac1339bAD89CF" true) 0xC540f05BF5a09336078634D65E46242DFBa55030 src/contracts/VestedFXS-and-Flox/VestedFXS/VestedFXSUtils.sol:VestedFXSUtils```
