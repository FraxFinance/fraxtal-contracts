# Fraxtal Contracts

## Setup
1) `npm install`
<!-- 2) Make sure your submodules in /lib are `optimism@e6ef3a900c42c8722e72c2e2314027f85d12ced5` and  -->
2) Make sure your submodules in /lib are `optimism@2073f4059bd806af3e8b76b820aa3fa0b42016d0` (cd /lib/optimism/ && git fetch --tags && git checkout op-contracts/v1.8.0) and 
`frax-standard-solidity@latest`. See https://www.git-scm.com/book/en/v2/Git-Tools-Submodules for additional help
3) cd into lib/optimism/packages/contracts-bedrock, 
4) forge install, to update the bedrock lib submodules
5) Go back to the project root and run `pnpm install && pnpm build`.
6) Install the Go binary.
7) `foundryup`
8) `forge install`
9) `forge build`
10) Set up your `.env` based on `.env.EXAMPLE`
11) In your `.env`, set FOUNDRY_PROFILE to the folder group you want to work with

## Test Example
MAKE SURE TO SET YOUR `.env` to `FOUNDRY_PROFILE="fraxtal"` or `FOUNDRY_PROFILE="vefxs"` or `FOUNDRY_PROFILE="miscellany"` DUE TO SOLC VERSIONING ISSUES, AS MENTIONED ABOVE
```clear && source .env && forge test --fork-url $MAINNET_RPC_URL --match-path ./src/test/VestedFXS-and-Flox/e2e/E2E_VeFXS.t.sol --match-contract Fuzz_MegaTest_VeFXS -vvvvv```

## Storage Layout (Deployed contracts)
```source .env && cast storage --chain-id 252 --rpc-url $FRAXTAL_RPC_URL --etherscan-api-key $FRAXTAL_API_KEY 0xfc00000000000000000000000000000000000001``` <!-- frxUSD (ex FRAX) -->
```source .env && cast storage --chain-id 252 --rpc-url $FRAXTAL_RPC_URL --etherscan-api-key $FRAXTAL_API_KEY 0xfc00000000000000000000000000000000000002```
```source .env && cast storage --chain-id 252 --rpc-url $FRAXTAL_RPC_URL --etherscan-api-key $FRAXTAL_API_KEY 0xfc00000000000000000000000000000000000006```
```source .env && cast storage --chain-id 252 --rpc-url $FRAXTAL_RPC_URL --etherscan-api-key $FRAXTAL_API_KEY 0x4200000000000000000000000000000000000019``` <!-- BaseFeeVault Proxy -->
```source .env && cast storage --chain-id 252 --rpc-url $FRAXTAL_RPC_URL --etherscan-api-key $FRAXTAL_API_KEY 0x4200000000000000000000000000000000000015``` <!-- FraxchainL1Block Proxy -->
```source .env && cast storage --chain-id 252 --rpc-url $FRAXTAL_RPC_URL --etherscan-api-key $FRAXTAL_API_KEY 0x4200000000000000000000000000000000000007``` <!-- L2CrossDomainMessenger Proxy -->
```source .env && cast storage --chain-id 252 --rpc-url $FRAXTAL_RPC_URL --etherscan-api-key $FRAXTAL_API_KEY 0x4200000000000000000000000000000000000010``` <!-- L2StandardBridge Proxy -->
```source .env && cast storage --chain-id 252 --rpc-url $FRAXTAL_RPC_URL --etherscan-api-key $FRAXTAL_API_KEY 0xBFc4D34Db83553725eC6c768da71D2D9c1456B55```
```source .env && cast storage --chain-id 1 --rpc-url $L1_DEVNET_RPC_URL 0xD943EF21D6Af93DDF42a5cc91Ca46D7dA8582339```
```source .env && cast storage --chain-id 252 --rpc-url $L2_DEVNET_RPC_URL 0xFc00000000000000000000000000000000000002 --etherscan-api-key $FRAXTAL_API_KEY```
```source .env && cast storage --chain-id 252 --rpc-url $L2_DEVNET_RPC_URL 0xFc00000000000000000000000000000000000009 --etherscan-api-key $FRAXTAL_API_KEY```
```source .env && cast storage --chain-id 252 --rpc-url $L2_DEVNET_RPC_URL 0xFc0000000000000000000000000000000000000a --etherscan-api-key $FRAXTAL_API_KEY```
```source .env && cast storage --chain-id 252 --rpc-url $L2_DEVNET_RPC_URL 0xFcc0d3000000000000000000000000000000000A --etherscan-api-key $FRAXTAL_API_KEY```
```source .env && cast storage --chain-id 1 --rpc-url $MAINNET_RPC_URL 0x126bcc31Bc076B3d515f60FBC81FddE0B0d542Ed```
```source .env && cast storage --chain-id 1 --rpc-url $MAINNET_RPC_URL 0xCC26248B71284B812Ff7825e005560DB01a874C7```

## Storage Layout (Undeployed contracts)
```forge inspect src/contracts/Fraxtal/universal/ERC20ExPPOMWrapped.sol:ERC20ExPPOMWrapped storageLayout```
```forge inspect src/contracts/Fraxtal/universal/ERC20ExWrappedPPOM.sol:ERC20ExWrappedPPOM storageLayout```<!-- may need to comment out assembly in initializer -->
```forge inspect src/contracts/Fraxtal/L1/FraxtalPortal.sol:FraxtalPortal storageLayout```
```forge inspect src/contracts/Fraxtal/L1/FraxtalPortal2.sol:FraxtalPortal2 storageLayout```
```forge inspect src/contracts/Fraxtal/L1/L1CrossDomainMessengerFxtl.sol:L1CrossDomainMessengerFxtl storageLayout```
```forge inspect src/contracts/Miscellany/FraxtalERC4626MintRedeemer.sol:FraxtalERC4626MintRedeemer storageLayout```
```forge inspect src/contracts/Fraxtal/L2/BaseFeeVaultCGT.sol:BaseFeeVaultCGT storageLayout```
```forge inspect src/contracts/Fraxtal/L2/L1BlockCGT.sol:L1BlockCGT storageLayout```

## ABI Layout (Undeployed contracts)
```forge inspect src/contracts/Fraxtal/universal/ERC20ExPPOMWrapped.sol:ERC20ExPPOMWrapped abi --pretty```
```forge inspect src/contracts/Fraxtal/universal/ERC20ExWrappedPPOM.sol:ERC20ExWrappedPPOM abi --pretty```
```forge inspect src/contracts/Fraxtal/universal/ERC20PermitPermissionedOptiMintable.sol:ERC20PermitPermissionedOptiMintable abi --pretty```
```forge inspect src/contracts/Fraxtal/L1/FraxtalPortal2.sol:FraxtalPortal2 abi --pretty```

## Generate Interfaces (Undeployed contracts)
<!-- https://book.getfoundry.sh/reference/cast/cast-interface -->
```cast interface src/contracts/Fraxtal/universal/ERC20ExPPOMWrapped.sol:ERC20ExPPOMWrapped```
```cast interface src/contracts/Fraxtal/universal/ERC20ExWrappedPPOM.sol:ERC20ExWrappedPPOM```
```cast interface src/contracts/Fraxtal/universal/vanity/wfrxETH.sol:wfrxETH```

## Create Examples
<!-- Fraxtal -->
```source .env && forge create src/contracts/Miscellany/frxUSD_Distribution/FrxUSDDistributor.sol:FrxUSDDistributor --chain-id 252 --gas-price 15000 --priority-gas-price 1000 --rpc-url $FRAXTAL_RPC_URL --verify --verifier-url $FRAXSCAN_API_URL --verifier-api-key $FRAXTAL_API_KEY --optimize --optimizer-runs 1000000 --use "0.8.29" --evm-version "cancun" --private-key $PK --broadcast```

## Deploy Examples
<!-- Fraxtal -->
```source .env && forge script src/script/VestedFXS-and-Flox/DeployFPISLocker.s.sol:DeployFPISLocker --chain-id 252 --with-gas-price 15000 --priority-gas-price 1000 --rpc-url $FRAXTAL_RPC_URL --verifier-url $FRAXSCAN_API_URL --etherscan-api-key $FRAXTAL_API_KEY --optimize --optimizer-runs 200 --use "0.8.26" --evm-version "cancun" --private-key $PK --broadcast```

```source .env && forge script src/script/VestedFXS-and-Flox/DeployL1VeFXSTotalSupplyOracle.s.sol:DeployL1VeFXSTotalSupplyOracle --chain-id 252 --with-gas-price 15000 --priority-gas-price 1000 --rpc-url $FRAXTAL_RPC_URL --verifier-url $FRAXSCAN_API_URL --etherscan-api-key $FRAXTAL_API_KEY --optimize --optimizer-runs 100000 --use "0.8.26" --evm-version "cancun" --private-key $PK --broadcast```

```source .env && forge script src/script/VestedFXS-and-Flox/DeployVeFXSAggregator.s.sol --chain-id 252 --with-gas-price 15000 --priority-gas-price 1000 --rpc-url $FRAXTAL_RPC_URL --verifier-url $FRAXSCAN_API_URL --etherscan-api-key $FRAXTAL_API_KEY --optimize --optimizer-runs 100000 --use "0.8.26" --evm-version "cancun" --private-key $PK --broadcast```

```source .env && forge script src/script/VestedFXS-and-Flox/DeployYieldDistributor.s.sol --chain-id 252 --with-gas-price 15000 --priority-gas-price 1000 --rpc-url $FRAXTAL_RPC_URL --verifier-url $FRAXSCAN_API_URL --etherscan-api-key $FRAXTAL_API_KEY --optimize --optimizer-runs 100000 --use "0.8.26" --evm-version "cancun" --private-key $PK --broadcast```

```source .env && forge script src/script/Miscellany/DeployTimedLocker.s.sol:DeployTimedLocker --chain-id 252 --with-gas-price 15000 --priority-gas-price 1000 --rpc-url $FRAXTAL_RPC_URL --verifier-url $FRAXSCAN_API_URL --etherscan-api-key $FRAXTAL_API_KEY --optimize --optimizer-runs 100000 --use "0.8.26" --evm-version "cancun" --private-key $PK --broadcast```

```source .env && forge script src/script/Miscellany/DeploySfraxMintRedeemer.s.sol:DeploySfraxMintRedeemer --chain-id 252 --with-gas-price 15000 --priority-gas-price 1000 --rpc-url $FRAXTAL_RPC_URL --verifier-url $FRAXSCAN_API_URL --etherscan-api-key $FRAXTAL_API_KEY --optimize --optimizer-runs 100000 --use "0.8.26" --evm-version "cancun" --private-key $PK --broadcast```

```source .env && forge script src/script/Miscellany/DeploySfxEthMintRedeemer.s.sol:DeploySfxEthMintRedeemer --chain-id 252 --with-gas-price 15000 --priority-gas-price 1000 --rpc-url $FRAXTAL_RPC_URL --verifier-url $FRAXSCAN_API_URL --etherscan-api-key $FRAXTAL_API_KEY --optimize --optimizer-runs 100000 --use "0.8.26" --evm-version "cancun" --private-key $PK --broadcast```

```source .env && forge script src/script/Miscellany/DeployL1QuitCreditorReceiverConverters.s.sol:DeployL1QuitCreditorReceiverConverters --chain-id 252 --with-gas-price 15000 --priority-gas-price 1000 --rpc-url $FRAXTAL_RPC_URL --verifier-url $FRAXSCAN_API_URL --etherscan-api-key $FRAXTAL_API_KEY --optimize --optimizer-runs 100000 --use "0.8.26" --evm-version "cancun" --private-key $PK --broadcast```

```source .env && forge script src/script/VestedFXS-and-Flox/DeployDoubleOptInVeFXSDelegation.s.sol:DeployDoubleOptInVeFXSDelegation --chain-id 252 --with-gas-price 15000 --priority-gas-price 1000 --rpc-url $FRAXTAL_RPC_URL --verifier-url $FRAXSCAN_API_URL --etherscan-api-key $FRAXTAL_API_KEY --optimize --optimizer-runs 100000 --use "0.8.26" --evm-version "cancun" --private-key $PK --broadcast```

<!-- ETH Mainnet -->
```source .env && forge script src/script/Miscellany/DeployFraxFarmQuitCreditors_UniV3.s.sol:DeployFraxFarmQuitCreditors_UniV3 --chain-id 1 --with-gas-price 10000000000 --priority-gas-price 1000 --rpc-url $MAINNET_RPC_URL --verifier-url $ETHERSCAN_API_URL --etherscan-api-key $ETHERSCAN_API_KEY --optimize --optimizer-runs 100000 --use "0.8.26" --slow --evm-version "cancun" --private-key $PK --broadcast```


```source .env && forge script src/script/Miscellany/DeployAaveAMO_V3.s.sol:DeployAaveAMO_V3 --chain-id 1 --with-gas-price 7000000000 --priority-gas-price 1000 --rpc-url $MAINNET_RPC_URL --verifier-url $ETHERSCAN_API_URL --etherscan-api-key $ETHERSCAN_API_KEY --optimize --optimizer-runs 100000 --use "0.8.26" --slow --evm-version "cancun" --private-key $PK --broadcast```

## Upgrade Proxy Example
```source .env && forge script src/script/VestedFXS-and-Flox/UpgradeFPISLocker.s.sol:UpgradeFPISLocker --chain-id 252 --with-gas-price 15000 --priority-gas-price 1000 --rpc-url $FRAXTAL_RPC_URL --verifier-url $FRAXSCAN_API_URL --etherscan-api-key $FRAXTAL_API_KEY --optimize --optimizer-runs 200 --use "0.8.23" --evm-version "paris" --private-key $PK --broadcast```

```source .env && forge script src/script/VestedFXS-and-Flox/UpgradeVeFXSAggregator.s.sol:UpgradeVeFXSAggregator --chain-id 252 --with-gas-price 15000 --priority-gas-price 1000 --rpc-url $FRAXTAL_RPC_URL --verifier-url $FRAXSCAN_API_URL --etherscan-api-key $FRAXTAL_API_KEY --optimize --optimizer-runs 100000 --use "0.8.26" --evm-version "cancun" --private-key $PK --broadcast```

<!-- Fraxtal L1 Devnet (testing) -->
```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/UpgradeDevnetCGT.s.sol:UpgradeDevnetCGT --chain-id 1 --with-gas-price 15000 --priority-gas-price 1000 --rpc-url $L1_DEVNET_RPC_URL --optimize --optimizer-runs 100000 --evm-version "cancun" --broadcast```

```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/L1Misc.s.sol:L1Misc --chain-id 1 --with-gas-price 15000 --priority-gas-price 1000 --rpc-url $L1_DEVNET_RPC_URL --optimize --optimizer-runs 100000 --evm-version "cancun" --broadcast```

```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/L1TestTxs.s.sol:L1TestTxs --chain-id 1 --with-gas-price 15000 --priority-gas-price 1000 --rpc-url $L1_DEVNET_RPC_URL --optimize --optimizer-runs 100000 --evm-version "cancun" --private-key $PK --broadcast```

```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/L1L2SetupTestTokens.s.sol:L1L2SetupTestTokens --chain-id 1 --with-gas-price 15000 --priority-gas-price 1000 --rpc-url $L1_DEVNET_RPC_URL --optimize --optimizer-runs 100000 --evm-version "cancun" --private-key $PK --broadcast --slow```

<!-- North Star L1L2 (Dual, Devnet) -->
<!-- ================================================================== -->
<!-- NOTE: For a dry run, remove --broadcast. You can add -vvvv too -->
<!-- 00 (Phases 0 and 2, L1) -->
```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/L1L2/00_L1L2_SetupTestTokens.s.sol:L1L2_SetupTestTokens --chain-id 1 --with-gas-price 17500 --priority-gas-price 1500 --rpc-url $L1_DEVNET_RPC_URL --optimize --optimizer-runs 100000 --evm-version "cancun" --broadcast --slow --verify --verifier=blockscout --retries=3 --verifier-url='http://localhost:36103/api?'```
<!-- 00 (Phase 1, L2) -->
```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/L1L2/00_L1L2_SetupTestTokens.s.sol:L1L2_SetupTestTokens --chain-id 252 --with-gas-price 150000000 --priority-gas-price 15000000 --rpc-url $L2_DEVNET_RPC_URL --optimize --optimizer-runs 100000 --evm-version "cancun" --broadcast --slow --verify --verifier=blockscout --retries=3 --verifier-url='http://localhost:40006/api?'```
<!-- 01 (as L1) -->
```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/L1L2/01_L1L2_InitiateDepositsAndWithdrawals.s.sol:L1L2_InitiateDepositsAndWithdrawals --chain-id 1 --with-gas-price 17500 --priority-gas-price 1500 --rpc-url $L1_DEVNET_RPC_URL --optimize --optimizer-runs 100000 --evm-version "cancun" --broadcast --slow --verify --verifier=blockscout --retries=3 --verifier-url='http://localhost:36103/api?'```
<!-- 01 (as L2) -->
```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/L1L2/01_L1L2_InitiateDepositsAndWithdrawals.s.sol:L1L2_InitiateDepositsAndWithdrawals --chain-id 252 --with-gas-price 150000000 --priority-gas-price 15000000 --rpc-url $L2_DEVNET_RPC_URL --optimize --optimizer-runs 100000 --evm-version "cancun" --broadcast --slow --verify --verifier=blockscout --retries=3 --verifier-url='http://localhost:40006/api?'```

<!-- North Star L1L2 (Dual, Holesky / Fraxtal Testnet) -->
<!-- ================================================================== -->
<!-- NOTE: For a dry run, remove --broadcast. You can add -vvvv too -->
<!-- 00 (Phases 0 and 2, L1) -->
```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/L1L2/00_L1L2_SetupTestTokens.s.sol:L1L2_SetupTestTokens --chain-id 17000 --with-gas-price 4000000 --priority-gas-price 40000 --rpc-url $HOLESKY_RPC_URL --optimize --optimizer-runs 100000 --evm-version "cancun" --broadcast --slow --verify --verifier=etherscan --retries=3 --verifier-url=$HOLESKY_API_URL```
<!-- 00 (Phase 1, L2) -->
```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/L1L2/00_L1L2_SetupTestTokens.s.sol:L1L2_SetupTestTokens --chain-id 2522 --with-gas-price 150000000 --priority-gas-price 15000000 --rpc-url $FRAXTAL_TESTNET_RPC_URL --optimize --optimizer-runs 100000 --evm-version "cancun" --broadcast --slow --verify --verifier=etherscan --retries=3```
<!-- 01 (as L1) -->
```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/L1L2/01_L1L2_InitiateDepositsAndWithdrawals.s.sol:L1L2_InitiateDepositsAndWithdrawals --chain-id 17000 --with-gas-price 4000000 --priority-gas-price 40000 --rpc-url $HOLESKY_RPC_URL --optimize --optimizer-runs 100000 --evm-version "cancun" --broadcast --slow --verifier=etherscan --retries=3 --verifier-url=$HOLESKY_API_URL```
<!-- 01 (as L2) -->
```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/L1L2/01_L1L2_InitiateDepositsAndWithdrawals.s.sol:L1L2_InitiateDepositsAndWithdrawals --chain-id 2522 --with-gas-price 150000000 --priority-gas-price 15000000 --rpc-url $FRAXTAL_TESTNET_RPC_URL --optimize --optimizer-runs 100000 --evm-version "cancun" --broadcast --slow --verify --verifier=blockscout --retries=3 --verifier-url='http://localhost:40006/api?'```

<!-- North Star L1 (Devnet) -->
<!-- ================================================================== -->
<!-- NOTE: For a dry run, remove --broadcast. You can add -vvvv too -->
<!-- 00 -->
```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/L1/00_L1_DeployImplsAndSSs.s.sol:L1_DeployImplsAndSSs --chain-id 1 --with-gas-price 19500 --priority-gas-price 1700 --rpc-url $L1_DEVNET_RPC_URL --optimize --optimizer-runs 100000 --evm-version "cancun" --broadcast --slow --verify --verifier=blockscout --retries=3 --verifier-url='http://localhost:36103/api?'```
<!-- 01 -->
```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/L1/01_L1_GenerateSSSafeBatches.s.sol:L1_GenerateSSSafeBatches --chain-id 1 --with-gas-price 17500 --priority-gas-price 1500 --rpc-url $L1_DEVNET_RPC_URL --optimize --optimizer-runs 100000 --evm-version "cancun" --broadcast --slow --retries=3```
<!-- 02 -->
```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/L1/02_L1_GenerateImplUpgradeSafeBatches.s.sol:L1_GenerateImplUpgradeSafeBatches --chain-id 1 --with-gas-price 17500 --priority-gas-price 1500 --rpc-url $L1_DEVNET_RPC_URL --optimize --optimizer-runs 100000 --evm-version "cancun" --broadcast --slow --retries=3```

<!-- North Star L1 (Holesky) -->
<!-- ================================================================== -->
<!-- NOTE: For a dry run, remove --broadcast. You can add -vvvv too -->
<!-- 00 -->
```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/L1/00_L1_DeployImplsAndSSs.s.sol:L1_DeployImplsAndSSs --chain-id 17000 --with-gas-price 4000000 --priority-gas-price 40000 --rpc-url $HOLESKY_RPC_URL --optimize --optimizer-runs 100000 --evm-version "cancun" --broadcast --slow --verify --verifier=etherscan --retries=3 --verifier-url=$HOLESKY_API_URL```
<!-- 01 -->
```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/L1/01_L1_GenerateSSSafeBatches.s.sol:L1_GenerateSSSafeBatches --chain-id 17000 --with-gas-price 4000000 --priority-gas-price 40000 --rpc-url $HOLESKY_RPC_URL --optimize --optimizer-runs 100000 --evm-version "cancun" --broadcast --slow --retries=3 --verify --verifier=etherscan --verifier-url=$HOLESKY_API_URL```
<!-- 02 -->
```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/L1/02_L1_GenerateImplUpgradeSafeBatches.s.sol:L1_GenerateImplUpgradeSafeBatches --chain-id 17000 --with-gas-price 4000000 --priority-gas-price 40000 --rpc-url $HOLESKY_RPC_URL --optimize --optimizer-runs 100000 --evm-version "cancun" --broadcast --slow --retries=3 --verify --verifier=etherscan --verifier-url=$HOLESKY_API_URL```

<!-- North Star L1 (Tenderly Virtual Prod) -->
<!-- ================================================================== -->
<!-- NOTE: For a dry run, remove --broadcast. You can add -vvvv too -->
<!-- 00 -->
```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/L1/00_L1_DeployImplsAndSSs.s.sol:L1_DeployImplsAndSSs --chain-id 1 --with-gas-price 3500000000 --priority-gas-price 350000000 --rpc-url $MAINNET_RPC_URL --optimize --optimizer-runs 100000 --evm-version "cancun" --broadcast --slow```
<!-- 01 -->
```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/L1/01_L1_GenerateSSSafeBatches.s.sol:L1_GenerateSSSafeBatches --chain-id 1 --with-gas-price 3500000000 --priority-gas-price 350000000 --rpc-url $MAINNET_RPC_URL --optimize --optimizer-runs 100000 --evm-version "cancun" --broadcast --slow --retries=3```
<!-- 02 -->
```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/L1/02_L1_GenerateImplUpgradeSafeBatches.s.sol:L1_GenerateImplUpgradeSafeBatches --chain-id 1 --with-gas-price 3500000000 --priority-gas-price 350000000 --rpc-url $MAINNET_RPC_URL --optimize --optimizer-runs 100000 --evm-version "cancun" --broadcast --slow --retries=3```

<!-- North Star L1 (IRL Prod) -->
<!-- ================================================================== -->
<!-- NOTE: For a dry run, remove --broadcast. You can add -vvvv too -->
<!-- 00 -->
```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/L1/00_L1_DeployImplsAndSSs.s.sol:L1_DeployImplsAndSSs --chain-id 1 --with-gas-price 750000000 --priority-gas-price 75000000 --rpc-url $MAINNET_RPC_URL --optimize --optimizer-runs 100000 --evm-version "cancun" --broadcast --slow --verify --verifier=etherscan --retries=3 --verifier-url=$ETHERSCAN_API_URL --verifier-api-key $ETHERSCAN_API_KEY```
<!-- 01 -->
```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/L1/01_L1_GenerateSSSafeBatches.s.sol:L1_GenerateSSSafeBatches --chain-id 1 --with-gas-price 750000000 --priority-gas-price 75000000 --rpc-url $MAINNET_RPC_URL --optimize --optimizer-runs 100000 --evm-version "cancun" --broadcast --slow --verify --verifier=etherscan --retries=3 --verifier-url=$ETHERSCAN_API_URL --verifier-api-key $ETHERSCAN_API_KEY```
<!-- 02 -->
```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/L1/02_L1_GenerateImplUpgradeSafeBatches.s.sol:L1_GenerateImplUpgradeSafeBatches --chain-id 1 --with-gas-price 750000000 --priority-gas-price 75000000 --rpc-url $MAINNET_RPC_URL --optimize --optimizer-runs 100000 --evm-version "cancun" --broadcast --slow --verify --verifier=etherscan --retries=3 --verifier-url=$ETHERSCAN_API_URL --verifier-api-key $ETHERSCAN_API_KEY```


<!-- Fraxtal L2 Devnet (start on L1 for setup) -->
```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/L2Misc.s.sol:L2Misc --chain-id 1 --with-gas-price 17500 --priority-gas-price 1500 --rpc-url $L1_DEVNET_RPC_URL --optimize --optimizer-runs 100000 --evm-version "london" --broadcast```

<!-- North Star L2 (Devnet) -->
<!-- ================================================================== -->
<!-- NOTE: For a dry run, remove --broadcast. You can add -vvvv too -->
<!-- XX -->
```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/L2/XX_L2_DeployTestSafe.s.sol:L2_DeployTestSafe --chain-id 252 --with-gas-price 1500000 --priority-gas-price 150000 --rpc-url $L2_DEVNET_RPC_URL --optimize --optimizer-runs 999999 --evm-version "cancun" --broadcast --slow --verify --verifier=blockscout --retries=3 --verifier-url='http://localhost:40006/api?'```
<!-- XY -->
```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/L2/XY_L2_FixProxyAdmins.s.sol:L2_FixProxyAdmins --chain-id 252 --with-gas-price 1500000 --priority-gas-price 150000 --rpc-url $L2_DEVNET_RPC_URL --optimize --optimizer-runs 999999 --evm-version "cancun" --broadcast --slow --verify --verifier=blockscout --retries=3 --verifier-url='http://localhost:40006/api?'```
<!-- 00 -->
```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/L2/00_L2_Deploy2Tokens.s.sol:L2_Deploy2Tokens --chain-id 252 --with-gas-price 1500000 --priority-gas-price 150000 --rpc-url $L2_DEVNET_RPC_URL --optimize --optimizer-runs 999999 --evm-version "cancun" --broadcast --slow --verify --verifier=blockscout --retries=3 --verifier-url='http://localhost:40006/api?'```
<!-- 01 -->
```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/L2/01_L2_DeployImplsAndSSs.s.sol:L2_DeployImplsAndSSs --chain-id 252 --with-gas-price 1500000 --priority-gas-price 150000 --rpc-url $L2_DEVNET_RPC_URL --optimize --optimizer-runs 999999 --evm-version "cancun" --broadcast --slow --verify --verifier=blockscout --retries=3 --verifier-url='http://localhost:40006/api?'```
<!-- 02 -->
```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/L2/02_L2_UpgradeFeeVaults.s.sol:L2_UpgradeFeeVaults --chain-id 252 --with-gas-price 1500000 --priority-gas-price 150000 --rpc-url $L2_DEVNET_RPC_URL --optimize --optimizer-runs 999999 --evm-version "cancun" --broadcast --slow```
<!-- 03 -->
```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/L2/03_L2_UpgradePredeploys.s.sol:L2_UpgradePredeploys --chain-id 252 --with-gas-price 1500000 --priority-gas-price 150000 --rpc-url $L2_DEVNET_RPC_URL --optimize --optimizer-runs 999999 --evm-version "cancun" --broadcast --slow```
<!-- 04 -->
```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/L2/04_L2_Upgrade2Tokens.s.sol:L2_Upgrade2Tokens --chain-id 252 --with-gas-price 1500000 --priority-gas-price 150000 --rpc-url $L2_DEVNET_RPC_URL --optimize --optimizer-runs 999999 --evm-version "cancun" --broadcast --slow```

<!-- North Star L2 (Fraxtal Testnet) -->
<!-- ================================================================== -->
<!-- NOTE: For a dry run, remove --broadcast. You can add -vvvv too -->
<!-- Verification (Often doesn't work for Fraxtal Testnet):  --verify --verifier=etherscan --retries=3 --verifier-url $FRAXSCAN_API_URL --verifier-api-key $FRAXTAL_API_KEY -->
<!-- XX -->
```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/L2/XX_L2_DeployTestSafe.s.sol:L2_DeployTestSafe --chain-id 2522 --with-gas-price 1500000 --priority-gas-price 150000 --rpc-url $FRAXTAL_TESTNET_RPC_URL --optimize --optimizer-runs 1000000 --evm-version "london" --broadcast --slow```
<!-- XY -->
```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/L2/XY_L2_FixProxyAdmins.s.sol:L2_FixProxyAdmins --chain-id 2522 --with-gas-price 1500000 --priority-gas-price 150000 --rpc-url $FRAXTAL_TESTNET_RPC_URL --optimize --optimizer-runs 1000000 --evm-version "london" --broadcast --slow```
<!-- 00 -->
```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/L2/00_L2_Deploy2Tokens.s.sol:L2_Deploy2Tokens --chain-id 2522 --with-gas-price 1500000 --priority-gas-price 150000 --rpc-url $FRAXTAL_TESTNET_RPC_URL --optimize --optimizer-runs 1000000 --evm-version "cancun" --broadcast --slow```
<!-- 01 -->
```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/L2/01_L2_DeployImplsAndSSs.s.sol:L2_DeployImplsAndSSs --chain-id 2522 --with-gas-price 1500000 --priority-gas-price 150000 --rpc-url $FRAXTAL_TESTNET_RPC_URL --optimize --optimizer-runs 1000000 --evm-version "london" --broadcast --slow```
<!-- 02 -->
```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/L2/02_L2_UpgradeFeeVaults.s.sol:L2_UpgradeFeeVaults --chain-id 2522 --with-gas-price 1500000 --priority-gas-price 150000 --rpc-url $FRAXTAL_TESTNET_RPC_URL --optimize --optimizer-runs 1000000 --evm-version "london" --broadcast --slow```
<!-- 03 -->
```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/L2/03_L2_UpgradePredeploys.s.sol:L2_UpgradePredeploys --chain-id 2522 --with-gas-price 1500000 --priority-gas-price 150000 --rpc-url $FRAXTAL_TESTNET_RPC_URL --optimize --optimizer-runs 1000000 --evm-version "london" --broadcast --slow```
<!-- 04 -->
```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/L2/04_L2_Upgrade2Tokens.s.sol:L2_Upgrade2Tokens --chain-id 2522 --with-gas-price 1500000 --priority-gas-price 150000 --rpc-url $FRAXTAL_TESTNET_RPC_URL --optimize --optimizer-runs 1000000 --evm-version "london" --broadcast --slow```

<!-- North Star L2 (Tenderly Virtual Prod) -->
<!-- ================================================================== -->
<!-- NOTE: For a dry run, remove --broadcast. You can add -vvvv too -->
<!-- XX -->
```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/L2/XX_L2_DeployTestSafe.s.sol:L2_DeployTestSafe --chain-id 252 --with-gas-price 1500000 --priority-gas-price 150000 --rpc-url $FRAXTAL_RPC_URL --optimize --optimizer-runs 999999 --evm-version "cancun" --broadcast --slow```
<!-- XY -->
```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/L2/XY_L2_FixProxyAdmins.s.sol:L2_FixProxyAdmins --chain-id 252 --with-gas-price 1500000 --priority-gas-price 150000 --rpc-url $FRAXTAL_RPC_URL --optimize --optimizer-runs 999999 --evm-version "cancun" --broadcast --slow```
<!-- 00 -->
```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/L2/00_L2_Deploy2Tokens.s.sol:L2_Deploy2Tokens --chain-id 252 --with-gas-price 1500000 --priority-gas-price 150000 --rpc-url $FRAXTAL_RPC_URL --optimize --optimizer-runs 999999 --evm-version "cancun" --broadcast --slow```
<!-- 01 -->
```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/L2/01_L2_DeployImplsAndSSs.s.sol:L2_DeployImplsAndSSs --chain-id 252 --with-gas-price 1500000 --priority-gas-price 150000 --rpc-url $FRAXTAL_RPC_URL --optimize --optimizer-runs 999999 --evm-version "cancun" --broadcast --slow```
<!-- 02 -->
```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/L2/02_L2_UpgradeFeeVaults.s.sol:L2_UpgradeFeeVaults --chain-id 252 --with-gas-price 1500000 --priority-gas-price 150000 --rpc-url $FRAXTAL_RPC_URL --optimize --optimizer-runs 999999 --evm-version "cancun" --broadcast --slow```
<!-- 03 -->
```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/L2/03_L2_UpgradePredeploys.s.sol:L2_UpgradePredeploys --chain-id 252 --with-gas-price 1500000 --priority-gas-price 150000 --rpc-url $FRAXTAL_RPC_URL --optimize --optimizer-runs 999999 --evm-version "cancun" --broadcast --slow```
<!-- 04 -->
```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/L2/04_L2_Upgrade2Tokens.s.sol:L2_Upgrade2Tokens --chain-id 252 --with-gas-price 1500000 --priority-gas-price 150000 --rpc-url $FRAXTAL_RPC_URL --optimize --optimizer-runs 999999 --evm-version "cancun" --broadcast --slow```

<!-- North Star L2 (IRL Prod) -->
<!-- ================================================================== -->
<!-- NOTE: For a dry run, remove --broadcast. You can add -vvvv too -->
<!-- 00 -->
```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/L2/00_L2_Deploy2Tokens.s.sol:L2_Deploy2Tokens --chain-id 252 --with-gas-price 1500000 --priority-gas-price 150000 --rpc-url $FRAXTAL_RPC_URL --optimize --optimizer-runs 999999 --evm-version "cancun" --broadcast --slow --verify --verifier=etherscan --retries=3 --verifier-url=$FRAXSCAN_API_URL --verifier-api-key $FRAXTAL_API_KEY```
<!-- 01 -->
```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/L2/01_L2_DeployImplsAndSSs.s.sol:L2_DeployImplsAndSSs --chain-id 252 --with-gas-price 1500000 --priority-gas-price 150000 --rpc-url $FRAXTAL_RPC_URL --optimize --optimizer-runs 999999 --evm-version "cancun" --broadcast --slow --verify --verifier=etherscan --retries=3 --verifier-url=$FRAXSCAN_API_URL --verifier-api-key $FRAXTAL_API_KEY```
<!-- 02 -->
```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/L2/02_L2_UpgradeFeeVaults.s.sol:L2_UpgradeFeeVaults --chain-id 252 --with-gas-price 1500000 --priority-gas-price 150000 --rpc-url $FRAXTAL_RPC_URL --optimize --optimizer-runs 999999 --evm-version "cancun" --broadcast --slow --verify --verifier=etherscan --retries=3 --verifier-url=$FRAXSCAN_API_URL --verifier-api-key $FRAXTAL_API_KEY```
<!-- 03 -->
```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/L2/03_L2_UpgradePredeploys.s.sol:L2_UpgradePredeploys --chain-id 252 --with-gas-price 1500000 --priority-gas-price 150000 --rpc-url $FRAXTAL_RPC_URL --optimize --optimizer-runs 999999 --evm-version "cancun" --broadcast --slow --verify --verifier=etherscan --retries=3 --verifier-url=$FRAXSCAN_API_URL --verifier-api-key $FRAXTAL_API_KEY```
<!-- 04 -->
```source .env && forge script src/script/Fraxtal/North_Star_Hardfork/L2/04_L2_Upgrade2Tokens.s.sol:L2_Upgrade2Tokens --chain-id 252 --with-gas-price 1500000 --priority-gas-price 150000 --rpc-url $FRAXTAL_RPC_URL --optimize --optimizer-runs 999999 --evm-version "cancun" --broadcast --slow --verify --verifier=etherscan --retries=3 --verifier-url=$FRAXSCAN_API_URL --verifier-api-key $FRAXTAL_API_KEY```


## Checking Transactions
<!-- North Star L2 (Devnet) -->
<!-- ================================================================== -->
```source .env && cast tx 0x1ee802e7a541c6c83f67365c8c79a29cec10cba0a608a5d9616475292a814128 --rpc-url $L2_DEVNET_RPC_URL```

## Verification
### Regular contracts
Try using forge verify-contract first
```source .env && forge verify-contract --chain-id 252 --watch --num-of-optimizations 10000 --etherscan-api-key $FRAXTAL_API_KEY --constructor-args $(cast abi-encode "constructor(address)" "0x007FD070a7E1B0fA1364044a373Ac1339bAD89CF" true) 0xC540f05BF5a09336078634D65E46242DFBa55030 src/contracts/VestedFXS-and-Flox/VestedFXS/VestedFXSUtils.sol:VestedFXSUtils```
```source .env && forge verify-contract --chain-id 252 --watch --compiler-version "0.8.26" --evm-version "cancun" --num-of-optimizations 100000 --rpc-url $FRAXTAL_RPC_URL --etherscan-api-key $FRAXTAL_API_KEY --constructor-args 0x000000000000000000000000625e700125ff054f75e5348497cbfab1ee4b7a40 0xBFc4D34Db83553725eC6c768da71D2D9c1456B55 src/script/Miscellany/Proxy.sol:Proxy```
```source .env && forge verify-contract --chain-id 252 --watch --compiler-version "0.8.29" --evm-version "cancun" --num-of-optimizations 1000000 --rpc-url $FRAXTAL_RPC_URL --etherscan-api-key $FRAXTAL_API_KEY 0x9AF1c2aEcCD2c9f03F445F3397c112C24963ce26 src/contracts/Miscellany/frxUSD_Distribution/FrxUSDDistributor.sol:FrxUSDDistributor```
CHECK THE PROXY OUT FOLDER TO SEE THE OPTS/RUNS/EVM/COMP STUFF BECAUSE SOMETIMES IT IS OLDER AND IS DIFFERENT FROM THE IMPLEMENTATION!!!


If this fails, try `forge flatten`
1) `forge flatten --output src/flattened.sol src/contracts/VestedFXS-and-Flox/VestedFXS/VeFXSYieldDistributor.sol`
2) `sed -i '/SPDX-License-Identifier/d' ./src/flattened.sol && sed -i '/pragma solidity/d' ./src/flattened.sol && sed -i '1s/^/\/\/ SPDX-License-Identifier: GPL-2.0-or-later\npragma solidity >=0.8.0;\n\n/' ./src/flattened.sol`
3) Take the contents of your new flattened.sol file and do the Etherscan verification manually

### L1 Testnet Blockscout verification
<!-- Proxy (OptimismPortal) -->
```source .env && forge verify-contract --rpc-url $L1_DEVNET_RPC_URL --chain-id 1 --watch --compiler-version "0.8.15+commit.e14f2714" --evm-version "london" --num-of-optimizations 50000 --verifier=blockscout --retries=3 --verifier-url='http://localhost:36103/api?' --constructor-args 0x00000000000000000000000068b1d87f95878fe05b998f19b66f4baba5de1aed 0x09635F643e140090A9A8Dcd712eD6285858ceBef lib/optimism/packages/contracts-bedrock/src/universal/Proxy.sol:Proxy```
<!-- Proxy (SystemConfig)-->
```source .env && forge verify-contract --rpc-url $L1_DEVNET_RPC_URL --chain-id 1 --watch --compiler-version "0.8.15+commit.e14f2714" --evm-version "london" --num-of-optimizations 50000 --verifier=blockscout --retries=3 --verifier-url='http://localhost:36103/api?' --constructor-args 0x00000000000000000000000068b1d87f95878fe05b998f19b66f4baba5de1aed 0x67d269191c92Caf3cD7723F116c85e6E9bf55933 lib/optimism/packages/contracts-bedrock/src/universal/Proxy.sol:Proxy```
<!-- Proxy (L1CrossDomainMessenger)-->
```source .env && forge verify-contract --rpc-url $L1_DEVNET_RPC_URL --chain-id 1 --watch --compiler-version "0.8.15+commit.e14f2714" --evm-version "london" --num-of-optimizations 50000 --verifier=blockscout --retries=3 --verifier-url='http://localhost:36103/api?' --constructor-args 0x00000000000000000000000068b1d87f95878fe05b998f19b66f4baba5de1aed 0xc3e53F4d16Ae77Db1c982e75a937B9f60FE63690 lib/optimism/packages/contracts-bedrock/src/universal/Proxy.sol:Proxy```
<!-- ProxyAdmin -->
```source .env && forge verify-contract --rpc-url $L1_DEVNET_RPC_URL --chain-id 1 --watch --compiler-version "0.8.15+commit.e14f2714" --evm-version "london" --num-of-optimizations 50000 --verifier=blockscout --retries=3 --verifier-url='http://localhost:36103/api?' --constructor-args 0x00000000000000000000000068b1d87f95878fe05b998f19b66f4baba5de1aed 0x68B1D87F95878fE05B998F19b66F4baba5De1aed lib/optimism/packages/contracts-bedrock/src/universal/ProxyAdmin.sol:ProxyAdmin```
<!-- ProxyAdmin -->
```source .env && forge verify-contract --rpc-url $L1_DEVNET_RPC_URL --chain-id 1 --watch --compiler-version "0.8.15+commit.e14f2714" --evm-version "london" --num-of-optimizations 50000 --verifier=blockscout --retries=3 --verifier-url='http://localhost:36103/api?' --constructor-args 0x00000000000000000000000068b1d87f95878fe05b998f19b66f4baba5de1aed 0x68B1D87F95878fE05B998F19b66F4baba5De1aed lib/optimism/packages/contracts-bedrock/src/universal/ProxyAdmin.sol:ProxyAdmin```


### L2 Testnet Blockscout verification
<!-- Proxy (L1Block as an example) -->
```source .env && forge verify-contract --rpc-url $L2_DEVNET_RPC_URL --chain-id 252 --watch --compiler-version "0.8.15+commit.e14f2714" --evm-version "london" --num-of-optimizations 999999 --verifier=blockscout --retries=3 --verifier-url='http://localhost:40006/api?' --constructor-args 0000000000000000000000004200000000000000000000000000000000000018 0x4200000000000000000000000000000000000015 lib/optimism/packages/contracts-bedrock/src/universal/Proxy.sol:Proxy```
<!-- Proxy (FXS as an example) -->
```source .env && forge verify-contract --rpc-url $L2_DEVNET_RPC_URL --chain-id 252 --watch --compiler-version "0.8.15+commit.e14f2714" --evm-version "london" --num-of-optimizations 999999 --verifier=blockscout --retries=3 --verifier-url='http://localhost:40006/api?' --constructor-args 0000000000000000000000004200000000000000000000000000000000000018 0xfc00000000000000000000000000000000000002 lib/optimism/packages/contracts-bedrock/src/universal/Proxy.sol:Proxy```
<!-- Proxy (Sample Proxy (alternate method)). Constructor arg might actually be 000... -->
```source .env && forge verify-contract --rpc-url $L2_DEVNET_RPC_URL --chain-id 252 --watch --compiler-version "0.8.15+commit.e14f2714" --evm-version "london" --num-of-optimizations 999999 --verifier=blockscout --retries=3 --verifier-url='http://localhost:40006/api?' --constructor-args 0000000000000000000000004200000000000000000000000000000000000018 0x4200000000000000000000000000000000000000 lib/optimism/packages/contracts-bedrock/src/universal/Proxy.sol:Proxy```
<!-- ProxyAdmin -->
```source .env && forge verify-contract --rpc-url $L2_DEVNET_RPC_URL --chain-id 252 --watch --compiler-version "0.8.15+commit.e14f2714" --evm-version "london" --num-of-optimizations 999999 --verifier=blockscout --retries=3 --verifier-url='http://localhost:40006/api?' --constructor-args 0000000000000000000000001853d02e360e1f9384fd8dd0ebfe671701300204 0xc0d3c0d3c0d3c0d3c0d3c0d3c0d3c0d3c0d30018 lib/optimism/packages/contracts-bedrock/src/universal/ProxyAdmin.sol:ProxyAdmin```
<!-- Core8's Proxy's impl (OZ ProxyAdmin) -->
```source .env && forge verify-contract --rpc-url $L2_DEVNET_RPC_URL --chain-id 252 --watch --compiler-version "v0.8.23+commit.f704f362" --evm-version "london" --verifier=blockscout --retries=3 --verifier-url='http://localhost:40006/api?' --constructor-args 0000000000000000000000005a856F34BA62f32a68e98E9F78b26D62c6cB70fE 0xFCC0D3000000000000000000000000000000000A lib/optimism/packages/contracts-bedrock/src/universal/ProxyAdmin.sol:ProxyAdmin```
<!-- GnosisSafeL2 singleton -->
```source .env && forge verify-contract --rpc-url $L2_DEVNET_RPC_URL --chain-id 252 --watch --compiler-version "0.8.15+commit.e14f2714" --evm-version "london" --num-of-optimizations 999999 --verifier=blockscout --retries=3 --verifier-url='http://localhost:40006/api?' 0xfb1bffC9d739B8D520DaF37dF666da4C687191EA lib/optimism/packages/contracts-bedrock/lib/safe-contracts/contracts/GnosisSafeL2.sol:GnosisSafeL2```

### Verifying a proxy
1) https://fraxscan.com/proxycontractchecker?a=PROXY_ADDRESS_HERE
2) TRY ```source .env && forge verify-contract --chain-id 252 --watch --num-of-optimizations 100000 --evm-version "cancun" --etherscan-api-key $FRAXTAL_API_KEY --constructor-args $(cast abi-encode "constructor(address)" "0x625e700125FF054f75e5348497cBFab1ee4b7A40" true) 0x437E9F65cA234eCfed12149109587139d435AD35 src/script/VestedFXS-and-Flox/Proxy.sol:Proxy```
3) OR (2) but with ```--show-standard-json-input``` and paste that into the verifier
4) If you are still having problems, make sure the constructor args are padded properly, etc. Sometimes Etherscan guesses the wrong ones.


### Code Coverage
1) ```forge coverage --ir-minimum --report lcov && genhtml lcov.info -o report --branch-coverage --ignore-errors category```. 
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
