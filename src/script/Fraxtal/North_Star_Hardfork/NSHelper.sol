// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "src/Constants.sol" as Constants;

import { IResourceMetering } from "@eth-optimism/contracts-bedrock/src/L1/interfaces/IResourceMetering.sol";
import { SystemConfigCGT } from "src/contracts/Fraxtal/L1/SystemConfigCGT.sol";
import { FraxTest } from "frax-std/FraxTest.sol";

contract NSHelper is FraxTest {
    enum NSChainType {
        InternalDevnetL1,
        InternalDevnetL2,
        TestnetL1_Holesky,
        TestnetL2_Fraxtal,
        ProdL1_Ethereum,
        ProdL2_Fraxtal
    }

    enum NSAddressType {
        // L1
        // =================================

        // L1 ERC20s
        // ------------
        FRAX_ERC20,
        FRXUSD_ERC20,
        FXS_ERC20,
        FRXETH_ERC20,
        // L1 SYSTEM
        // ------------
        L1_OWNER_SAFE,
        L1_STORAGE_SETTER,
        SYSTEM_CONFIG_PROXY,
        SYSTEM_CONFIG_IMPL,
        SYSTEM_CONFIG_OWNER,
        SYSTEM_CONFIG_UPGRADE_CALLER,
        SUPERCHAIN_CONFIG_PROXY,
        SUPERCHAIN_CONFIG_PROXY_ADMIN,
        L1_PROXY_ADMIN,
        L1_PROXY_ADMIN_OWNER,
        OPTIMISM_PORTAL_PROXY,
        OPTIMISM_PORTAL_IMPL,
        L1_CROSS_DOMAIN_MESSENGER_PROXY,
        L1_CROSS_DOMAIN_MESSENGER_IMPL,
        L1_STANDARD_BRIDGE_PROXY,
        L1_STANDARD_BRIDGE_IMPL,
        L1_ERC721_BRIDGE_PROXY,
        L1_ERC721_BRIDGE_IMPL,
        L2_OUTPUT_ORACLE_PROXY,
        OPTIMISM_MINTABLE_ERC20_FACTORY_PROXY,
        OPTIMISM_MINTABLE_ERC20_FACTORY_IMPL,
        PROTOCOL_VERSIONS_PROXY,
        // L1 TEST TOKENS
        // ------------
        L1TOKEN,
        BADL1TOKEN,
        REMOTEL1TOKEN,
        // L1 SYSTEMCONFIG DATA
        // ------------
        SYSCFG_MISC__BASE_FEE_SCALAR,
        SYSCFG_MISC__BLOB_BASE_FEE_SCALAR,
        SYSCFG_MISC__BATCHER_HASH,
        SYSCFG_MISC__GAS_LIMIT,
        SYSCFG_MISC__UNSAFE_BLOCK_SIGNER,
        SYSCFG_RESCFG__MAX_RES_LIMIT,
        SYSCFG_RESCFG__ELAST_MULT,
        SYSCFG_RESCFG__BASE_FEE_MAX_CHNG_DENOM,
        SYSCFG_RESCFG__MIN_BASE_FEE,
        SYSCFG_RESCFG__SYS_TX_MAX_GAS,
        SYSCFG_RESCFG__MAX_BASE_FEE,
        SYSCFG_MISC__BATCH_INBOX,
        SYSCFG_MISC__GAS_TOKEN_ADDRESS,
        SYSCFG_ADDRS__CDM,
        SYSCFG_ADDRS__ERC721BRG,
        SYSCFG_ADDRS__STDBRG,
        SYSCFG_ADDRS__L2OO,
        SYSCFG_ADDRS__DSPGMFCTY,
        SYSCFG_ADDRS__OPPTL,
        SYSCFG_ADDRS__OPMNTERC20FCTY,
        SYSCFG_ADDRS__GASPAYTKN,
        // L2
        // =================================
        // L2 ERC20s
        // ------------
        WFRAX_IMPL,
        L2_FXS_ERC20,
        WFRXETH_ERC20,
        FRXETHL2_IMPL,
        // L2 SYSTEM
        // ------------
        L2_ADMIN_SAFE,
        L2_STORAGE_SETTER,
        L2_PROXY_ADMIN_OP_SYS_OWNER,
        L2_PROXY_ADMIN_CORE8,
        L2_PROXY_ADMIN_CORE8_OWNER,
        L2_PROXY_ADMIN_RSVD_10K,
        L2_PROXY_ADMIN_RSVD_10K_OWNER,
        L2_TO_L1_MESSAGE_PASSER_CGT_IMPL,
        L2_STANDARD_BRIDGE_CGT_IMPL,
        L2_CROSS_DOMAIN_MESSENGER_CGT_IMPL,
        L1_BLOCK_CGT_IMPL,
        BASE_FEE_VAULT_CGT_IMPL,
        L1_FEE_VAULT_CGT_IMPL,
        SEQUENCER_FEE_VAULT_CGT_IMPL,
        // L2 TEST TOKENS
        // ------------
        L2TOKEN,
        BADL2TOKEN,
        LEGACYL2TOKEN,
        NATIVEL2TOKEN
    }

    struct SystemConfigMisc {
        uint32 baseFeeScalar;
        uint32 blobBaseFeeScalar;
        bytes32 batcherHash;
        uint64 gasLimit;
        address unsafeBlockSigner;
        address batchInbox;
        address gasTokenAddress;
    }

    function compareStringsNS(string memory _a, string memory _b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked(_b));
    }

    function getDeployerMnemonic(NSChainType _chainType) public returns (string memory _mnemonic) {
        if (_chainType == NSChainType.InternalDevnetL1 || _chainType == NSChainType.InternalDevnetL2) {
            return vm.envString("DEVNET_JUNK_MNEMONIC");
        }
        if (_chainType == NSChainType.TestnetL1_Holesky || _chainType == NSChainType.TestnetL2_Fraxtal) {
            return vm.envString("HOLESKY_FRAXTAL_TESTNET_DEPLOYER_MNEMONIC");
        }
        if (_chainType == NSChainType.ProdL1_Ethereum || _chainType == NSChainType.ProdL2_Fraxtal) {
            return vm.envString("ETH_FRAXTAL_NORTH_STAR_DEPLOYER_MNEMONIC");
        }
    }

    function getNSChainID(NSChainType _chainType) public returns (uint256 _chainId) {
        if (_chainType == NSChainType.InternalDevnetL1) {
            return 1;
        }
        if (_chainType == NSChainType.InternalDevnetL2) {
            return 252;
        }
        if (_chainType == NSChainType.TestnetL1_Holesky) {
            return 17_000;
        }
        if (_chainType == NSChainType.TestnetL2_Fraxtal) {
            return 2522;
        }
        if (_chainType == NSChainType.ProdL1_Ethereum) {
            return 1;
        }
        if (_chainType == NSChainType.ProdL2_Fraxtal) {
            return 252;
        }
    }

    function getNSChainType(string memory _chainString) public returns (NSChainType _chainType) {
        if (compareStringsNS(_chainString, "internal-devnet-l1")) return NSChainType.InternalDevnetL1;
        if (compareStringsNS(_chainString, "internal-devnet-l2")) return NSChainType.InternalDevnetL2;
        if (compareStringsNS(_chainString, "testnet-l1-holesky")) return NSChainType.TestnetL1_Holesky;
        if (compareStringsNS(_chainString, "testnet-l2-fraxtal")) return NSChainType.TestnetL2_Fraxtal;
        if (compareStringsNS(_chainString, "prod-l1-ethereum")) return NSChainType.ProdL1_Ethereum;
        if (compareStringsNS(_chainString, "prod-l2-fraxtal")) return NSChainType.ProdL2_Fraxtal;
    }

    function getNSForkId(string memory _chainString) public returns (uint256 _forkID) {
        if (compareStringsNS(_chainString, "internal-devnet-l1")) {
            return vm.createSelectFork(vm.envString("L1_DEVNET_RPC_URL"));
        }
        if (compareStringsNS(_chainString, "internal-devnet-l2")) {
            return vm.createSelectFork(vm.envString("L2_DEVNET_RPC_URL"));
        }
        if (compareStringsNS(_chainString, "testnet-l1-holesky")) {
            return vm.createSelectFork(vm.envString("HOLESKY_RPC_URL"));
        }
        if (compareStringsNS(_chainString, "testnet-l2-fraxtal")) {
            return vm.createSelectFork(vm.envString("FRAXTAL_TESTNET_RPC_URL"));
        }
        if (compareStringsNS(_chainString, "prod-l1-ethereum")) {
            return vm.createSelectFork(vm.envString("MAINNET_RPC_URL"));
        }
        if (compareStringsNS(_chainString, "prod-l2-fraxtal")) {
            return vm.createSelectFork(vm.envString("FRAXTAL_RPC_URL"));
        }
    }

    function fetchSystemConfigInfo(
        NSChainType _chainType
    )
        public
        returns (
            SystemConfigCGT.Addresses memory _sysAddresses,
            IResourceMetering.ResourceConfig memory _sysResourceConfig,
            SystemConfigMisc memory _sysMisc
        )
    {
        // Addresses
        // ---------------------
        if (_chainType == NSChainType.InternalDevnetL1) {
            _sysAddresses = SystemConfigCGT.Addresses({
                l1CrossDomainMessenger: Constants.FraxtalL1Devnet.SYSCFG_ADDRS__CDM,
                l1ERC721Bridge: Constants.FraxtalL1Devnet.SYSCFG_ADDRS__ERC721BRG,
                l1StandardBridge: Constants.FraxtalL1Devnet.SYSCFG_ADDRS__STDBRG,
                l2OutputOracle: Constants.FraxtalL1Devnet.SYSCFG_ADDRS__L2OO,
                disputeGameFactory: Constants.FraxtalL1Devnet.SYSCFG_ADDRS__DSPGMFCTY, // Leave 0 for now?
                optimismPortal: Constants.FraxtalL1Devnet.SYSCFG_ADDRS__OPPTL,
                optimismMintableERC20Factory: Constants.FraxtalL1Devnet.SYSCFG_ADDRS__OPMNTERC20FCTY,
                gasPayingToken: Constants.FraxtalL1Devnet.SYSCFG_ADDRS__GASPAYTKN
            });
        }
        if (_chainType == NSChainType.TestnetL1_Holesky) {
            _sysAddresses = SystemConfigCGT.Addresses({
                l1CrossDomainMessenger: Constants.Holesky.SYSCFG_ADDRS__CDM,
                l1ERC721Bridge: Constants.Holesky.SYSCFG_ADDRS__ERC721BRG,
                l1StandardBridge: Constants.Holesky.SYSCFG_ADDRS__STDBRG,
                l2OutputOracle: Constants.Holesky.SYSCFG_ADDRS__L2OO,
                disputeGameFactory: Constants.Holesky.SYSCFG_ADDRS__DSPGMFCTY, // Leave 0 for now?
                optimismPortal: Constants.Holesky.SYSCFG_ADDRS__OPPTL,
                optimismMintableERC20Factory: Constants.Holesky.SYSCFG_ADDRS__OPMNTERC20FCTY,
                gasPayingToken: Constants.Holesky.SYSCFG_ADDRS__GASPAYTKN
            });
        }
        if (_chainType == NSChainType.ProdL1_Ethereum) {
            _sysAddresses = SystemConfigCGT.Addresses({
                l1CrossDomainMessenger: Constants.FraxtalL1Ethereum.SYSCFG_ADDRS__CDM,
                l1ERC721Bridge: Constants.FraxtalL1Ethereum.SYSCFG_ADDRS__ERC721BRG,
                l1StandardBridge: Constants.FraxtalL1Ethereum.SYSCFG_ADDRS__STDBRG,
                l2OutputOracle: Constants.FraxtalL1Ethereum.SYSCFG_ADDRS__L2OO,
                disputeGameFactory: Constants.FraxtalL1Ethereum.SYSCFG_ADDRS__DSPGMFCTY, // Leave 0 for now?
                optimismPortal: Constants.FraxtalL1Ethereum.SYSCFG_ADDRS__OPPTL,
                optimismMintableERC20Factory: Constants.FraxtalL1Ethereum.SYSCFG_ADDRS__OPMNTERC20FCTY,
                gasPayingToken: Constants.FraxtalL1Ethereum.SYSCFG_ADDRS__GASPAYTKN
            });
        }

        // ResourceConfig
        // ---------------------
        if (_chainType == NSChainType.InternalDevnetL1) {
            _sysResourceConfig = IResourceMetering.ResourceConfig({
                maxResourceLimit: Constants.FraxtalL1Devnet.SYSCFG_RESCFG__MAX_RES_LIMIT,
                elasticityMultiplier: Constants.FraxtalL1Devnet.SYSCFG_RESCFG__ELAST_MULT,
                baseFeeMaxChangeDenominator: Constants.FraxtalL1Devnet.SYSCFG_RESCFG__BASE_FEE_MAX_CHNG_DENOM,
                minimumBaseFee: Constants.FraxtalL1Devnet.SYSCFG_RESCFG__MIN_BASE_FEE,
                systemTxMaxGas: Constants.FraxtalL1Devnet.SYSCFG_RESCFG__SYS_TX_MAX_GAS,
                maximumBaseFee: Constants.FraxtalL1Devnet.SYSCFG_RESCFG__MAX_BASE_FEE
            });
        }
        if (_chainType == NSChainType.TestnetL1_Holesky) {
            _sysResourceConfig = IResourceMetering.ResourceConfig({
                maxResourceLimit: Constants.Holesky.SYSCFG_RESCFG__MAX_RES_LIMIT,
                elasticityMultiplier: Constants.Holesky.SYSCFG_RESCFG__ELAST_MULT,
                baseFeeMaxChangeDenominator: Constants.Holesky.SYSCFG_RESCFG__BASE_FEE_MAX_CHNG_DENOM,
                minimumBaseFee: Constants.Holesky.SYSCFG_RESCFG__MIN_BASE_FEE,
                systemTxMaxGas: Constants.Holesky.SYSCFG_RESCFG__SYS_TX_MAX_GAS,
                maximumBaseFee: Constants.Holesky.SYSCFG_RESCFG__MAX_BASE_FEE
            });
        }
        if (_chainType == NSChainType.ProdL1_Ethereum) {
            _sysResourceConfig = IResourceMetering.ResourceConfig({
                maxResourceLimit: Constants.FraxtalL1Ethereum.SYSCFG_RESCFG__MAX_RES_LIMIT,
                elasticityMultiplier: Constants.FraxtalL1Ethereum.SYSCFG_RESCFG__ELAST_MULT,
                baseFeeMaxChangeDenominator: Constants.FraxtalL1Ethereum.SYSCFG_RESCFG__BASE_FEE_MAX_CHNG_DENOM,
                minimumBaseFee: Constants.FraxtalL1Ethereum.SYSCFG_RESCFG__MIN_BASE_FEE,
                systemTxMaxGas: Constants.FraxtalL1Ethereum.SYSCFG_RESCFG__SYS_TX_MAX_GAS,
                maximumBaseFee: Constants.FraxtalL1Ethereum.SYSCFG_RESCFG__MAX_BASE_FEE
            });
        }

        // Misc
        // ---------------------
        if (_chainType == NSChainType.InternalDevnetL1) {
            _sysMisc = SystemConfigMisc({
                baseFeeScalar: Constants.FraxtalL1Devnet.SYSCFG_MISC__BASE_FEE_SCALAR,
                blobBaseFeeScalar: Constants.FraxtalL1Devnet.SYSCFG_MISC__BLOB_BASE_FEE_SCALAR,
                batcherHash: Constants.FraxtalL1Devnet.SYSCFG_MISC__BATCHER_HASH,
                gasLimit: Constants.FraxtalL1Devnet.SYSCFG_MISC__GAS_LIMIT,
                unsafeBlockSigner: Constants.FraxtalL1Devnet.SYSCFG_MISC__UNSAFE_BLOCK_SIGNER,
                batchInbox: Constants.FraxtalL1Devnet.SYSCFG_MISC__BATCH_INBOX,
                gasTokenAddress: Constants.FraxtalL1Devnet.SYSCFG_MISC__GAS_TOKEN_ADDRESS
            });
        }
        if (_chainType == NSChainType.TestnetL1_Holesky) {
            _sysMisc = SystemConfigMisc({
                baseFeeScalar: Constants.Holesky.SYSCFG_MISC__BASE_FEE_SCALAR,
                blobBaseFeeScalar: Constants.Holesky.SYSCFG_MISC__BLOB_BASE_FEE_SCALAR,
                batcherHash: Constants.Holesky.SYSCFG_MISC__BATCHER_HASH,
                gasLimit: Constants.Holesky.SYSCFG_MISC__GAS_LIMIT,
                unsafeBlockSigner: Constants.Holesky.SYSCFG_MISC__UNSAFE_BLOCK_SIGNER,
                batchInbox: Constants.Holesky.SYSCFG_MISC__BATCH_INBOX,
                gasTokenAddress: Constants.Holesky.SYSCFG_MISC__GAS_TOKEN_ADDRESS
            });
        }
        if (_chainType == NSChainType.ProdL1_Ethereum) {
            _sysMisc = SystemConfigMisc({
                baseFeeScalar: Constants.FraxtalL1Ethereum.SYSCFG_MISC__BASE_FEE_SCALAR,
                blobBaseFeeScalar: Constants.FraxtalL1Ethereum.SYSCFG_MISC__BLOB_BASE_FEE_SCALAR,
                batcherHash: Constants.FraxtalL1Ethereum.SYSCFG_MISC__BATCHER_HASH,
                gasLimit: Constants.FraxtalL1Ethereum.SYSCFG_MISC__GAS_LIMIT,
                unsafeBlockSigner: Constants.FraxtalL1Ethereum.SYSCFG_MISC__UNSAFE_BLOCK_SIGNER,
                batchInbox: Constants.FraxtalL1Ethereum.SYSCFG_MISC__BATCH_INBOX,
                gasTokenAddress: Constants.FraxtalL1Ethereum.SYSCFG_MISC__GAS_TOKEN_ADDRESS
            });
        }
    }

    function fetchNSAddress(NSChainType _chainType, NSAddressType _addrType) public returns (address _retAddr) {
        // L1
        // =================================

        // L1 ERC20s
        // ----------------------

        // FRAX_ERC20
        if (_addrType == NSAddressType.FRAX_ERC20) {
            if (_chainType == NSChainType.InternalDevnetL1) return Constants.FraxtalL1Devnet.FRAX_ERC20;
            if (_chainType == NSChainType.TestnetL1_Holesky) return Constants.Holesky.FRAX_ERC20;
            if (_chainType == NSChainType.ProdL1_Ethereum) return Constants.Mainnet.FRAX_ERC20;
        }

        // FRXUSD_ERC20
        if (_addrType == NSAddressType.FRXUSD_ERC20) {
            if (_chainType == NSChainType.InternalDevnetL1) return Constants.FraxtalL1Devnet.FRXUSD_ERC20;
            // if (_chainType == NSChainType.TestnetL1_Holesky) return Constants.Holesky.XXXXXXXX;
            if (_chainType == NSChainType.ProdL1_Ethereum) return Constants.Mainnet.FRXUSD_ERC20;
        }

        // FXS_ERC20
        if (_addrType == NSAddressType.FXS_ERC20) {
            if (_chainType == NSChainType.InternalDevnetL1) return Constants.FraxtalL1Devnet.FXS_ERC20;
            if (_chainType == NSChainType.TestnetL1_Holesky) return Constants.Holesky.FXS_ERC20;
            if (_chainType == NSChainType.ProdL1_Ethereum) return Constants.Mainnet.FXS_ERC20;
        }

        // FRXETH_ERC20
        if (_addrType == NSAddressType.FRXETH_ERC20) {
            if (_chainType == NSChainType.InternalDevnetL1) return Constants.FraxtalL1Devnet.FRXETH_ERC20;
            if (_chainType == NSChainType.TestnetL1_Holesky) return Constants.Holesky.FRXETH_ERC20;
            if (_chainType == NSChainType.ProdL1_Ethereum) return Constants.Mainnet.FRXETH_ERC20;
        }

        // L1 SYSTEM
        // ----------------------

        // L1_OWNER_SAFE
        if (_addrType == NSAddressType.L1_OWNER_SAFE) {
            if (_chainType == NSChainType.InternalDevnetL1) return Constants.FraxtalL1Devnet.SYSTEM_OWNER_SAFE;
            if (_chainType == NSChainType.TestnetL1_Holesky) return Constants.Holesky.L1_OWNER_SAFE;
            // if (_chainType == NSChainType.ProdL1_Ethereum) return Constants.Mainnet.MAIN_MAINNET_COMPTROLLER;
            if (_chainType == NSChainType.ProdL1_Ethereum) return Constants.FraxtalL1Ethereum.FRAXTAL_COMPTROLLER;
        }

        // L1_STORAGE_SETTER
        if (_addrType == NSAddressType.L1_STORAGE_SETTER) {
            if (_chainType == NSChainType.InternalDevnetL1) return Constants.FraxtalL1Devnet.L1_STORAGE_SETTER;
            if (_chainType == NSChainType.TestnetL1_Holesky) return Constants.Holesky.L1_STORAGE_SETTER;
            if (_chainType == NSChainType.ProdL1_Ethereum) return Constants.FraxtalL1Ethereum.L1_STORAGE_SETTER;
        }

        // SYSTEM_CONFIG_PROXY
        if (_addrType == NSAddressType.SYSTEM_CONFIG_PROXY) {
            if (_chainType == NSChainType.InternalDevnetL1) return Constants.FraxtalL1Devnet.SYSTEM_CONFIG_PROXY;
            if (_chainType == NSChainType.TestnetL1_Holesky) return Constants.Holesky.SYSTEM_CONFIG_PROXY;
            if (_chainType == NSChainType.ProdL1_Ethereum) return Constants.FraxtalL1Ethereum.SYSTEM_CONFIG_PROXY;
        }

        // SYSTEM_CONFIG_IMPL
        if (_addrType == NSAddressType.SYSTEM_CONFIG_IMPL) {
            if (_chainType == NSChainType.InternalDevnetL1) return Constants.FraxtalL1Devnet.SYSTEM_CONFIG_IMPL;
            if (_chainType == NSChainType.TestnetL1_Holesky) return Constants.Holesky.SYSTEM_CONFIG_IMPL;
            if (_chainType == NSChainType.ProdL1_Ethereum) {
                return Constants.FraxtalL1Ethereum.SYSTEM_CONFIG_IMPL;
            }
        }

        // SYSTEM_CONFIG_OWNER
        if (_addrType == NSAddressType.SYSTEM_CONFIG_OWNER) {
            if (_chainType == NSChainType.InternalDevnetL1) return Constants.FraxtalL1Devnet.SYSTEM_OWNER_SAFE;
            if (_chainType == NSChainType.TestnetL1_Holesky) return Constants.Holesky.SYSTEM_CONFIG_OWNER;
            if (_chainType == NSChainType.ProdL1_Ethereum) return Constants.FraxtalL1Ethereum.SYSTEM_OWNER_SAFE;
        }

        // SYSTEM_CONFIG_UPGRADE_CALLER
        if (_addrType == NSAddressType.SYSTEM_CONFIG_UPGRADE_CALLER) {
            if (_chainType == NSChainType.InternalDevnetL1) return Constants.FraxtalL1Devnet.SYSTEM_OWNER_SAFE;
            if (_chainType == NSChainType.TestnetL1_Holesky) return Constants.Holesky.SYSTEM_CONFIG_OWNER;
            if (_chainType == NSChainType.ProdL1_Ethereum) return Constants.FraxtalL1Ethereum.SYSTEM_OWNER_SAFE;
        }

        // SUPERCHAIN_CONFIG_PROXY
        if (_addrType == NSAddressType.SUPERCHAIN_CONFIG_PROXY) {
            if (_chainType == NSChainType.InternalDevnetL1) return Constants.FraxtalL1Devnet.SUPERCHAIN_CONFIG_PROXY;
            if (_chainType == NSChainType.TestnetL1_Holesky) return Constants.Holesky.SUPERCHAIN_CONFIG_PROXY;
            if (_chainType == NSChainType.ProdL1_Ethereum) return Constants.FraxtalL1Ethereum.SUPERCHAIN_CONFIG_PROXY;
        }

        // SUPERCHAIN_CONFIG_PROXY_ADMIN
        if (_addrType == NSAddressType.SUPERCHAIN_CONFIG_PROXY_ADMIN) {
            if (_chainType == NSChainType.InternalDevnetL1) return Constants.FraxtalL1Devnet.PROXY_ADMIN;
            if (_chainType == NSChainType.TestnetL1_Holesky) return Constants.Holesky.L1_PROXY_ADMIN;
            if (_chainType == NSChainType.ProdL1_Ethereum) return Constants.FraxtalL1Ethereum.PROXY_ADMIN;
        }

        // L1_PROXY_ADMIN
        if (_addrType == NSAddressType.L1_PROXY_ADMIN) {
            if (_chainType == NSChainType.InternalDevnetL1) return Constants.FraxtalL1Devnet.PROXY_ADMIN;
            if (_chainType == NSChainType.TestnetL1_Holesky) return Constants.Holesky.L1_PROXY_ADMIN;
            if (_chainType == NSChainType.ProdL1_Ethereum) return Constants.FraxtalL1Ethereum.PROXY_ADMIN;
        }

        // L1_PROXY_ADMIN_OWNER
        if (_addrType == NSAddressType.L1_PROXY_ADMIN_OWNER) {
            if (_chainType == NSChainType.InternalDevnetL1) return Constants.FraxtalL1Devnet.PROXY_ADMIN_OWNER;
            if (_chainType == NSChainType.TestnetL1_Holesky) return Constants.Holesky.L1_PROXY_ADMIN_OWNER;
            if (_chainType == NSChainType.ProdL1_Ethereum) return Constants.FraxtalL1Ethereum.PROXY_ADMIN_OWNER;
        }

        // OPTIMISM_PORTAL_PROXY
        if (_addrType == NSAddressType.OPTIMISM_PORTAL_PROXY) {
            if (_chainType == NSChainType.InternalDevnetL1) return Constants.FraxtalL1Devnet.OPTIMISM_PORTAL_PROXY;
            if (_chainType == NSChainType.TestnetL1_Holesky) return Constants.Holesky.OPTIMISM_PORTAL_PROXY;
            if (_chainType == NSChainType.ProdL1_Ethereum) return Constants.FraxtalL1Ethereum.OPTIMISM_PORTAL_PROXY;
        }

        // OPTIMISM_PORTAL_IMPL
        if (_addrType == NSAddressType.OPTIMISM_PORTAL_IMPL) {
            if (_chainType == NSChainType.InternalDevnetL1) return Constants.FraxtalL1Devnet.OPTIMISM_PORTAL_IMPL;
            if (_chainType == NSChainType.TestnetL1_Holesky) return Constants.Holesky.OPTIMISM_PORTAL_IMPL;
            if (_chainType == NSChainType.ProdL1_Ethereum) {
                return Constants.FraxtalL1Ethereum.OPTIMISM_PORTAL_IMPL;
            }
        }

        // L1_CROSS_DOMAIN_MESSENGER_PROXY
        if (_addrType == NSAddressType.L1_CROSS_DOMAIN_MESSENGER_PROXY) {
            if (_chainType == NSChainType.InternalDevnetL1) {
                return Constants.FraxtalL1Devnet.L1_CROSS_DOMAIN_MESSENGER_PROXY;
            }
            if (_chainType == NSChainType.TestnetL1_Holesky) return Constants.Holesky.L1_CROSS_DOMAIN_MESSENGER_PROXY;
            if (_chainType == NSChainType.ProdL1_Ethereum) {
                return Constants.FraxtalL1Ethereum.L1_CROSS_DOMAIN_MESSENGER_PROXY;
            }
        }

        // L1_CROSS_DOMAIN_MESSENGER_IMPL
        if (_addrType == NSAddressType.L1_CROSS_DOMAIN_MESSENGER_IMPL) {
            if (_chainType == NSChainType.InternalDevnetL1) {
                return Constants.FraxtalL1Devnet.L1_CROSS_DOMAIN_MESSENGER_IMPL;
            }
            if (_chainType == NSChainType.TestnetL1_Holesky) return Constants.Holesky.L1_CROSS_DOMAIN_MESSENGER_IMPL;
            if (_chainType == NSChainType.ProdL1_Ethereum) {
                return Constants.FraxtalL1Ethereum.L1_CROSS_DOMAIN_MESSENGER_IMPL;
            }
        }

        // L1_STANDARD_BRIDGE_PROXY
        if (_addrType == NSAddressType.L1_STANDARD_BRIDGE_PROXY) {
            if (_chainType == NSChainType.InternalDevnetL1) return Constants.FraxtalL1Devnet.L1_STANDARD_BRIDGE_PROXY;
            if (_chainType == NSChainType.TestnetL1_Holesky) return Constants.Holesky.L1_STANDARD_BRIDGE_PROXY;
            if (_chainType == NSChainType.ProdL1_Ethereum) return Constants.FraxtalL1Ethereum.L1_STANDARD_BRIDGE_PROXY;
        }

        // L1_STANDARD_BRIDGE_IMPL
        if (_addrType == NSAddressType.L1_STANDARD_BRIDGE_IMPL) {
            if (_chainType == NSChainType.InternalDevnetL1) return Constants.FraxtalL1Devnet.L1_STANDARD_BRIDGE_IMPL;
            if (_chainType == NSChainType.TestnetL1_Holesky) return Constants.Holesky.L1_STANDARD_BRIDGE_IMPL;
            if (_chainType == NSChainType.ProdL1_Ethereum) {
                return Constants.FraxtalL1Ethereum.L1_STANDARD_BRIDGE_IMPL;
            }
        }

        // L1_ERC721_BRIDGE_PROXY
        if (_addrType == NSAddressType.L1_ERC721_BRIDGE_PROXY) {
            if (_chainType == NSChainType.InternalDevnetL1) return Constants.FraxtalL1Devnet.L1_ERC721_BRIDGE_PROXY;
            if (_chainType == NSChainType.TestnetL1_Holesky) return Constants.Holesky.L1_ERC721_BRIDGE_PROXY;
            if (_chainType == NSChainType.ProdL1_Ethereum) return Constants.FraxtalL1Ethereum.L1_ERC721_BRIDGE_PROXY;
        }

        // L1_ERC721_BRIDGE_IMPL
        if (_addrType == NSAddressType.L1_ERC721_BRIDGE_IMPL) {
            if (_chainType == NSChainType.InternalDevnetL1) return Constants.FraxtalL1Devnet.L1_ERC721_BRIDGE_IMPL;
            if (_chainType == NSChainType.TestnetL1_Holesky) return Constants.Holesky.L1_ERC721_BRIDGE_IMPL;
            if (_chainType == NSChainType.ProdL1_Ethereum) return Constants.FraxtalL1Ethereum.L1_ERC721_BRIDGE_IMPL;
        }

        // L2_OUTPUT_ORACLE_PROXY
        if (_addrType == NSAddressType.L2_OUTPUT_ORACLE_PROXY) {
            if (_chainType == NSChainType.InternalDevnetL1) return Constants.FraxtalL1Devnet.L2_OUTPUT_ORACLE_PROXY;
            if (_chainType == NSChainType.TestnetL1_Holesky) return Constants.Holesky.L2_OUTPUT_ORACLE_PROXY;
            if (_chainType == NSChainType.ProdL1_Ethereum) return Constants.FraxtalL1Ethereum.L2_OUTPUT_ORACLE_PROXY;
        }

        // OPTIMISM_MINTABLE_ERC20_FACTORY_PROXY
        if (_addrType == NSAddressType.OPTIMISM_MINTABLE_ERC20_FACTORY_PROXY) {
            if (_chainType == NSChainType.InternalDevnetL1) {
                return Constants.FraxtalL1Devnet.OPTIMISM_MINTABLE_ERC20_FACTORY_PROXY;
            }
            if (_chainType == NSChainType.TestnetL1_Holesky) {
                return Constants.Holesky.OPTIMISM_MINTABLE_ERC20_FACTORY_PROXY;
            }
            if (_chainType == NSChainType.ProdL1_Ethereum) {
                return Constants.FraxtalL1Ethereum.OPTIMISM_MINTABLE_ERC20_FACTORY_PROXY;
            }
        }

        // OPTIMISM_MINTABLE_ERC20_FACTORY_IMPL
        if (_addrType == NSAddressType.OPTIMISM_MINTABLE_ERC20_FACTORY_IMPL) {
            if (_chainType == NSChainType.InternalDevnetL1) {
                return Constants.FraxtalL1Devnet.OPTIMISM_MINTABLE_ERC20_FACTORY_IMPL;
            }
            if (_chainType == NSChainType.TestnetL1_Holesky) {
                return Constants.Holesky.OPTIMISM_MINTABLE_ERC20_FACTORY_IMPL;
            }
            if (_chainType == NSChainType.ProdL1_Ethereum) {
                return Constants.FraxtalL1Ethereum.OPTIMISM_MINTABLE_ERC20_FACTORY_IMPL;
            }
        }

        // PROTOCOL_VERSIONS_PROXY
        if (_addrType == NSAddressType.PROTOCOL_VERSIONS_PROXY) {
            if (_chainType == NSChainType.InternalDevnetL1) return Constants.FraxtalL1Devnet.PROTOCOL_VERSIONS_PROXY;
            if (_chainType == NSChainType.TestnetL1_Holesky) return Constants.Holesky.PROTOCOL_VERSIONS_PROXY;
            if (_chainType == NSChainType.ProdL1_Ethereum) return Constants.FraxtalL1Ethereum.PROTOCOL_VERSIONS_PROXY;
        }

        // L1 TEST TOKENS
        // ----------------------

        // L1TOKEN
        if (_addrType == NSAddressType.L1TOKEN) {
            if (_chainType == NSChainType.InternalDevnetL1) return Constants.FraxtalL1Devnet.L1TOKEN;
            if (_chainType == NSChainType.TestnetL1_Holesky) return Constants.Holesky.L1TOKEN;
            if (_chainType == NSChainType.ProdL1_Ethereum) return Constants.FraxtalL1Ethereum.L1TOKEN;
        }

        // BADL1TOKEN
        if (_addrType == NSAddressType.BADL1TOKEN) {
            if (_chainType == NSChainType.InternalDevnetL1) return Constants.FraxtalL1Devnet.BADL1TOKEN;
            if (_chainType == NSChainType.TestnetL1_Holesky) return Constants.Holesky.BADL1TOKEN;
            if (_chainType == NSChainType.ProdL1_Ethereum) return Constants.FraxtalL1Ethereum.BADL1TOKEN;
        }

        // REMOTEL1TOKEN
        if (_addrType == NSAddressType.REMOTEL1TOKEN) {
            if (_chainType == NSChainType.InternalDevnetL1) return Constants.FraxtalL1Devnet.REMOTEL1TOKEN;
            if (_chainType == NSChainType.TestnetL1_Holesky) return Constants.Holesky.REMOTEL1TOKEN;
            if (_chainType == NSChainType.ProdL1_Ethereum) return Constants.FraxtalL1Ethereum.REMOTEL1TOKEN;
        }

        // L2
        // =================================
        // L2 ERC20s
        // ----------------------

        // WFRAX_IMPL
        if (_addrType == NSAddressType.WFRAX_IMPL) {
            if (_chainType == NSChainType.InternalDevnetL2) return Constants.FraxtalL2Devnet.WFRAX_IMPL;
            if (_chainType == NSChainType.TestnetL2_Fraxtal) return Constants.FraxtalTestnet.WFRAX_IMPL;
            if (_chainType == NSChainType.ProdL2_Fraxtal) return Constants.FraxtalMainnet.WFRAX_IMPL;
        }

        // L2_FXS_ERC20
        if (_addrType == NSAddressType.L2_FXS_ERC20) {
            if (_chainType == NSChainType.InternalDevnetL2) return Constants.FraxtalL2Devnet.FXS_ERC20;
            if (_chainType == NSChainType.TestnetL2_Fraxtal) return Constants.FraxtalTestnet.FXS_ERC20;
            if (_chainType == NSChainType.ProdL2_Fraxtal) return Constants.FraxtalMainnet.FXS_ERC20;
        }

        // WFRXETH_ERC20
        if (_addrType == NSAddressType.WFRXETH_ERC20) {
            if (_chainType == NSChainType.InternalDevnetL2) return Constants.FraxtalL2Devnet.WFRXETH_ERC20;
            if (_chainType == NSChainType.TestnetL2_Fraxtal) return Constants.FraxtalTestnet.WFRXETH_ERC20;
            if (_chainType == NSChainType.ProdL2_Fraxtal) return Constants.FraxtalMainnet.WFRXETH_ERC20;
        }

        // FRXETHL2_IMPL
        if (_addrType == NSAddressType.FRXETHL2_IMPL) {
            if (_chainType == NSChainType.InternalDevnetL2) return Constants.FraxtalL2Devnet.FRXETHL2_IMPL;
            if (_chainType == NSChainType.TestnetL2_Fraxtal) return Constants.FraxtalTestnet.FRXETHL2_IMPL;
            if (_chainType == NSChainType.ProdL2_Fraxtal) return Constants.FraxtalMainnet.FRXETHL2_IMPL;
        }

        // L2 SYSTEM
        // ----------------------

        // L2_ADMIN_SAFE
        if (_addrType == NSAddressType.L2_ADMIN_SAFE) {
            if (_chainType == NSChainType.InternalDevnetL2) return Constants.FraxtalL2Devnet.FRAXTAL_ADMIN_SAFE;
            if (_chainType == NSChainType.TestnetL2_Fraxtal) return Constants.FraxtalTestnet.FRAXTAL_ADMIN_SAFE;
            if (_chainType == NSChainType.ProdL2_Fraxtal) return Constants.FraxtalMainnet.FRAXTAL_ADMIN_SAFE;
        }

        // L2_STORAGE_SETTER
        if (_addrType == NSAddressType.L2_STORAGE_SETTER) {
            if (_chainType == NSChainType.InternalDevnetL2) return Constants.FraxtalL2Devnet.L2_STORAGE_SETTER;
            if (_chainType == NSChainType.TestnetL2_Fraxtal) return Constants.FraxtalTestnet.L2_STORAGE_SETTER;
            if (_chainType == NSChainType.ProdL2_Fraxtal) return Constants.FraxtalMainnet.L2_STORAGE_SETTER;
        }

        // L2_PROXY_ADMIN_OP_SYS_OWNER
        if (_addrType == NSAddressType.L2_PROXY_ADMIN_OP_SYS_OWNER) {
            if (_chainType == NSChainType.InternalDevnetL2) return Constants.FraxtalL2Devnet.FRAXTAL_ADMIN_SAFE;
            if (_chainType == NSChainType.TestnetL2_Fraxtal) return Constants.FraxtalTestnet.PROXY_ADMIN_OP_SYS_OWNER;
            if (_chainType == NSChainType.ProdL2_Fraxtal) return Constants.FraxtalMainnet.FRAXCHAIN_MAIN_MULTISIG;
        }

        // L2_PROXY_ADMIN_CORE8
        if (_addrType == NSAddressType.L2_PROXY_ADMIN_CORE8) {
            if (_chainType == NSChainType.InternalDevnetL2) return Constants.FraxtalL2Devnet.PROXY_ADMIN_CORE8_FC01FC08;
            if (_chainType == NSChainType.TestnetL2_Fraxtal) return Constants.FraxtalTestnet.PROXY_ADMIN_CORE8_FC01FC08;
            if (_chainType == NSChainType.ProdL2_Fraxtal) return Constants.FraxtalMainnet.PROXY_ADMIN_CORE8_FC01FC08;
        }

        // L2_PROXY_ADMIN_CORE8_OWNER
        if (_addrType == NSAddressType.L2_PROXY_ADMIN_CORE8_OWNER) {
            if (_chainType == NSChainType.InternalDevnetL2) return Constants.FraxtalL2Devnet.FRAXTAL_ADMIN_SAFE;
            if (_chainType == NSChainType.TestnetL2_Fraxtal) return Constants.FraxtalTestnet.PROXY_ADMIN_CORE8_OWNER; // Fix to FRAXTAL_ADMIN_SAFE
            if (_chainType == NSChainType.ProdL2_Fraxtal) return Constants.FraxtalMainnet.FRAXCHAIN_MAIN_MULTISIG;
        }

        // L2_PROXY_ADMIN_RSVD_10K
        if (_addrType == NSAddressType.L2_PROXY_ADMIN_RSVD_10K) {
            if (_chainType == NSChainType.InternalDevnetL2) {
                return Constants.FraxtalL2Devnet.PROXY_ADMIN_RSVD10K_FC0AFC65_FF01FF2711;
            }
            if (_chainType == NSChainType.TestnetL2_Fraxtal) {
                return Constants.FraxtalTestnet.PROXY_ADMIN_RSVD10K_FC0AFC65_FF01FF2711;
            }
            if (_chainType == NSChainType.ProdL2_Fraxtal) {
                return Constants.FraxtalMainnet.PROXY_ADMIN_RSVD10K_FC0AFC65_FF01FF2711;
            }
        }

        // L2_PROXY_ADMIN_RSVD_10K_OWNER
        if (_addrType == NSAddressType.L2_PROXY_ADMIN_RSVD_10K_OWNER) {
            if (_chainType == NSChainType.InternalDevnetL2) {
                return Constants.FraxtalL2Devnet.FRAXTAL_ADMIN_SAFE;
            }
            if (_chainType == NSChainType.TestnetL2_Fraxtal) {
                return Constants.FraxtalTestnet.PROXY_ADMIN_RSVD10K_OWNER; // Fix to FRAXTAL_ADMIN_SAFE
            }
            if (_chainType == NSChainType.ProdL2_Fraxtal) {
                return Constants.FraxtalMainnet.FRAXCHAIN_MAIN_MULTISIG;
            }
        }

        // L2_TO_L1_MESSAGE_PASSER_CGT_IMPL
        if (_addrType == NSAddressType.L2_TO_L1_MESSAGE_PASSER_CGT_IMPL) {
            if (_chainType == NSChainType.InternalDevnetL2) {
                return Constants.FraxtalL2Devnet.L2_TO_L1_MESSAGE_PASSER_CGT_IMPL;
            }
            if (_chainType == NSChainType.TestnetL2_Fraxtal) {
                return Constants.FraxtalTestnet.L2_TO_L1_MESSAGE_PASSER_CGT_IMPL;
            }
            if (_chainType == NSChainType.ProdL2_Fraxtal) {
                return Constants.FraxtalMainnet.L2_TO_L1_MESSAGE_PASSER_CGT_IMPL;
            }
        }

        // L2_STANDARD_BRIDGE_CGT_IMPL
        if (_addrType == NSAddressType.L2_STANDARD_BRIDGE_CGT_IMPL) {
            if (_chainType == NSChainType.InternalDevnetL2) {
                return Constants.FraxtalL2Devnet.L2_STANDARD_BRIDGE_CGT_IMPL;
            }
            if (_chainType == NSChainType.TestnetL2_Fraxtal) {
                return Constants.FraxtalTestnet.L2_STANDARD_BRIDGE_CGT_IMPL;
            }
            if (_chainType == NSChainType.ProdL2_Fraxtal) return Constants.FraxtalMainnet.L2_STANDARD_BRIDGE_CGT_IMPL;
        }

        // L2_CROSS_DOMAIN_MESSENGER_CGT_IMPL
        if (_addrType == NSAddressType.L2_CROSS_DOMAIN_MESSENGER_CGT_IMPL) {
            if (_chainType == NSChainType.InternalDevnetL2) {
                return Constants.FraxtalL2Devnet.L2_CROSS_DOMAIN_MESSENGER_CGT_IMPL;
            }
            if (_chainType == NSChainType.TestnetL2_Fraxtal) {
                return Constants.FraxtalTestnet.L2_CROSS_DOMAIN_MESSENGER_CGT_IMPL;
            }
            if (_chainType == NSChainType.ProdL2_Fraxtal) {
                return Constants.FraxtalMainnet.L2_CROSS_DOMAIN_MESSENGER_CGT_IMPL;
            }
        }

        // L1_BLOCK_CGT_IMPL
        if (_addrType == NSAddressType.L1_BLOCK_CGT_IMPL) {
            if (_chainType == NSChainType.InternalDevnetL2) return Constants.FraxtalL2Devnet.L1_BLOCK_CGT_IMPL;
            if (_chainType == NSChainType.TestnetL2_Fraxtal) return Constants.FraxtalTestnet.L1_BLOCK_CGT_IMPL;
            if (_chainType == NSChainType.ProdL2_Fraxtal) return Constants.FraxtalMainnet.L1_BLOCK_CGT_IMPL;
        }

        // BASE_FEE_VAULT_CGT_IMPL
        if (_addrType == NSAddressType.BASE_FEE_VAULT_CGT_IMPL) {
            if (_chainType == NSChainType.InternalDevnetL2) return Constants.FraxtalL2Devnet.BASE_FEE_VAULT_CGT_IMPL;
            if (_chainType == NSChainType.TestnetL2_Fraxtal) return Constants.FraxtalTestnet.BASE_FEE_VAULT_CGT_IMPL;
            if (_chainType == NSChainType.ProdL2_Fraxtal) return Constants.FraxtalMainnet.BASE_FEE_VAULT_CGT_IMPL;
        }

        // L1_FEE_VAULT_CGT_IMPL
        if (_addrType == NSAddressType.L1_FEE_VAULT_CGT_IMPL) {
            if (_chainType == NSChainType.InternalDevnetL2) return Constants.FraxtalL2Devnet.L1_FEE_VAULT_CGT_IMPL;
            if (_chainType == NSChainType.TestnetL2_Fraxtal) return Constants.FraxtalTestnet.L1_FEE_VAULT_CGT_IMPL;
            if (_chainType == NSChainType.ProdL2_Fraxtal) return Constants.FraxtalMainnet.L1_FEE_VAULT_CGT_IMPL;
        }

        // SEQUENCER_FEE_VAULT_CGT_IMPL
        if (_addrType == NSAddressType.SEQUENCER_FEE_VAULT_CGT_IMPL) {
            if (_chainType == NSChainType.InternalDevnetL2) {
                return Constants.FraxtalL2Devnet.SEQUENCER_FEE_VAULT_CGT_IMPL;
            }
            if (_chainType == NSChainType.TestnetL2_Fraxtal) {
                return Constants.FraxtalTestnet.SEQUENCER_FEE_VAULT_CGT_IMPL;
            }
            if (_chainType == NSChainType.ProdL2_Fraxtal) return Constants.FraxtalMainnet.SEQUENCER_FEE_VAULT_CGT_IMPL;
        }

        // L2 TEST TOKENS
        // ----------------------

        // L2TOKEN
        if (_addrType == NSAddressType.L2TOKEN) {
            if (_chainType == NSChainType.InternalDevnetL2) return Constants.FraxtalL2Devnet.L2TOKEN;
            if (_chainType == NSChainType.TestnetL2_Fraxtal) return Constants.FraxtalTestnet.L2TOKEN;
            if (_chainType == NSChainType.ProdL2_Fraxtal) return Constants.FraxtalMainnet.L2TOKEN;
        }

        // BADL2TOKEN
        if (_addrType == NSAddressType.BADL2TOKEN) {
            if (_chainType == NSChainType.InternalDevnetL2) return Constants.FraxtalL2Devnet.BADL2TOKEN;
            if (_chainType == NSChainType.TestnetL2_Fraxtal) return Constants.FraxtalTestnet.BADL2TOKEN;
            if (_chainType == NSChainType.ProdL2_Fraxtal) return Constants.FraxtalMainnet.BADL2TOKEN;
        }

        // LEGACYL2TOKEN
        if (_addrType == NSAddressType.LEGACYL2TOKEN) {
            if (_chainType == NSChainType.InternalDevnetL2) return Constants.FraxtalL2Devnet.LEGACYL2TOKEN;
            if (_chainType == NSChainType.TestnetL2_Fraxtal) return Constants.FraxtalTestnet.LEGACYL2TOKEN;
            if (_chainType == NSChainType.ProdL2_Fraxtal) return Constants.FraxtalMainnet.LEGACYL2TOKEN;
        }

        // NATIVEL2TOKEN
        if (_addrType == NSAddressType.NATIVEL2TOKEN) {
            if (_chainType == NSChainType.InternalDevnetL2) return Constants.FraxtalL2Devnet.NATIVEL2TOKEN;
            if (_chainType == NSChainType.TestnetL2_Fraxtal) return Constants.FraxtalTestnet.NATIVEL2TOKEN;
            if (_chainType == NSChainType.ProdL2_Fraxtal) return Constants.FraxtalMainnet.NATIVEL2TOKEN;
        }
    }
}
