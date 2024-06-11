# Fraxtal Contracts

## Setup
1) `npm install`
2) Make sure your submodules in /lib are `optimism@e6ef3a900c42c8722e72c2e2314027f85d12ced5` and `frax-standard-solidity@latest`. See https://www.git-scm.com/book/en/v2/Git-Tools-Submodules for additional help
3) Install the Go binary.
4) `forge build`
5) Set up your `.env` based on `.env.EXAMPLE`
6) In your `.env`, set FOUNDRY_PROFILE to the folder group you want to work with

## Test Example
MAKE SURE TO SET YOUR `.env` `FOUNDRY_PROFILE="fraxtal"` or `FOUNDRY_PROFILE="vefxs"` or `FOUNDRY_PROFILE="miscellany"` DUE TO SOLC VERSIONING ISSUES, AS MENTIONED ABOVE
```clear && source .env && forge test --fork-url $MAINNET_RPC_URL --match-path ./src/test/VestedFXS-and-Flox/e2e/E2E_VeFXS.t.sol --match-contract Fuzz_MegaTest_VeFXS -vvvvv```

## Deploy Example
```source .env && forge script src/script/VestedFXS-and-Flox/DeployL1VeFXSTotalSupplyOracle.s.sol:DeployL1VeFXSTotalSupplyOracle --chain-id 252 --with-gas-price 2500000 --rpc-url $FRAXTAL_RPC_URL --verifier-url $FRAXSCAN_API_URL --etherscan-api-key $FRAXTAL_API_KEY --optimize --optimizer-runs 100000 --use "0.8.26" --evm-version "cancun" --private-key $PK --broadcast```

## Upgrade Proxy Example
```source .env && forge script src/script/VestedFXS-and-Flox/UpgradeFPISLocker.s.sol:UpgradeFPISLocker --chain-id 252 --with-gas-price 2500000 --rpc-url $FRAXTAL_RPC_URL --verifier-url $FRAXSCAN_API_URL --etherscan-api-key $FRAXTAL_API_KEY --optimize --optimizer-runs 200 --use "0.8.23" --evm-version "paris" --private-key $PK --broadcast```

## Verification
### Regular contracts
Try using forge verify-contract first
```source .env && forge verify-contract --chain-id 252 --watch --num-of-optimizations 10000 --etherscan-api-key $FRAXTAL_API_KEY --constructor-args $(cast abi-encode "constructor(address)" "0x007FD070a7E1B0fA1364044a373Ac1339bAD89CF" true) 0xC540f05BF5a09336078634D65E46242DFBa55030 src/contracts/VestedFXS-and-Flox/VestedFXS/VestedFXSUtils.sol:VestedFXSUtils```

If this fails, try `forge flatten`
1) `forge flatten --output src/flattened.sol src/contracts/VestedFXS-and-Flox/VestedFXS/VeFXSYieldDistributor.sol`
2) `sed -i '/SPDX-License-Identifier/d' ./src/flattened.sol && sed -i '/pragma solidity/d' ./src/flattened.sol && sed -i '1s/^/\/\/ SPDX-License-Identifier: GPL-2.0-or-later\npragma solidity >=0.8.0;\n\n/' ./src/flattened.sol`
3) Take the contents of your new flattened.sol file and do the Etherscan verification manually

### Verifying a proxy
1) https://fraxscan.com/proxycontractchecker?a=PROXY_ADDRESS_HERE
2) TRY ```source .env && forge verify-contract --chain-id 252 --watch --optimize --num-of-optimizations 10000 --evm-version "paris" --etherscan-api-key $FRAXTAL_API_KEY --constructor-args $(cast abi-encode "constructor(address)" "0x4600d3b12c39af925c2c07c487d31d17c1e32a35" true) 0x007FD070a7E1B0fA1364044a373Ac1339bAD89CF src/script/VestedFXS-and-Flox/Proxy.sol:Proxy```
3) OR (2) but with ```--show-standard-json-input``` and paste that into the verifier
4) If you are still having problems, make sure the constructor args are padded properly, etc. Sometimes Etherscan guesses the wrong ones.


### Code Coverage
1) ```forge coverage --report lcov && genhtml lcov.info -o report --branch-coverage```. 
2) Go to /report and browse the html 
3) OPTIONAL: ```forge coverage --report summary``` (shows a coverage report in the terminal)
4) OPTIONAL: VS Code: install Coverage Gutters or a similar extension to see the coverage inside VSCode tabs

## Tooling
This repo uses the following tools:
- frax-standard-solidity for testing and scripting helpers
- forge fmt & prettier for code formatting
- lint-staged & husky for pre-commit formatting checks
- solhint for code quality and style hints
- foundry for compiling, testing, and deploying
