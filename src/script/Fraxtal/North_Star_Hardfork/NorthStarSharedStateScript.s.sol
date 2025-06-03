// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.15;

import { BaseFeeVaultCGT } from "src/contracts/Fraxtal/L2/BaseFeeVaultCGT.sol";
import { CrossDomainMessenger } from "@eth-optimism/contracts-bedrock/src/universal/CrossDomainMessenger.sol";
import { DisputeGameFactory } from "@eth-optimism/contracts-bedrock/src/dispute/DisputeGameFactory.sol";
import { ERC20 } from "@openzeppelin-4/contracts/token/ERC20/ERC20.sol";
// import { ERC20ExPPOMWrapped } from "src/contracts/Fraxtal/universal/ERC20ExPPOMWrapped.sol";
import { IERC20ExPPOMWrapped } from "src/contracts/Fraxtal/universal/interfaces/IERC20ExPPOMWrapped.sol";
import { IERC20ExWrappedPPOM } from "src/contracts/Fraxtal/universal/interfaces/IERC20ExWrappedPPOM.sol";
import { Encoding } from "@eth-optimism/contracts-bedrock/src/libraries/Encoding.sol";
import { FFIInterface } from "@eth-optimism/contracts-bedrock/test/setup/FFIInterface.sol";
// import { FraxtalPortal2 } from "src/contracts/Fraxtal/L1/FraxtalPortal2.sol";
import {
    GameType,
    GameTypes,
    OutputRoot,
    Claim,
    GameStatus,
    Hash
} from "@eth-optimism/contracts-bedrock/src/dispute/lib/Types.sol";
import { GasToken } from "src/contracts/Fraxtal/interfaces/GasToken.sol";
import { Hashing } from "@eth-optimism/contracts-bedrock/src/libraries/Hashing.sol";
import {
    ICrossDomainMessenger
} from "@eth-optimism/contracts-bedrock/src/universal/interfaces/ICrossDomainMessenger.sol";
import { IDisputeGameFactory } from "@eth-optimism/contracts-bedrock/src/dispute/interfaces/IDisputeGameFactory.sol";
import { IERC20 } from "@openzeppelin-4/contracts/token/ERC20/IERC20.sol";
import { IFaultDisputeGame } from "@eth-optimism/contracts-bedrock/src/dispute/interfaces/IFaultDisputeGame.sol";
import { IGnosisSafe, Enum as SafeOps } from "src/contracts/Fraxtal/interfaces/IGnosisSafe.sol";
import { IL2OutputOracle } from "@eth-optimism/contracts-bedrock/src/L1/interfaces/IL2OutputOracle.sol";
import { IOptimismPortal } from "@eth-optimism/contracts-bedrock/src/L1/interfaces/IOptimismPortal.sol";
import { IProxyAdmin } from "@eth-optimism/contracts-bedrock/src/universal/interfaces/IProxyAdmin.sol";
import { IResourceMetering } from "@eth-optimism/contracts-bedrock/src/L1/interfaces/IResourceMetering.sol";
import {
    ITransparentUpgradeableProxy
} from "@openzeppelin-4/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { ISemver } from "@eth-optimism/contracts-bedrock/src/universal/interfaces/ISemver.sol";
import { ISuperchainConfig } from "@eth-optimism/contracts-bedrock/src/L1/interfaces/ISuperchainConfig.sol";
import { ISystemConfig } from "@eth-optimism/contracts-bedrock/src/L1/interfaces/ISystemConfig.sol";
import { L1Block } from "@eth-optimism/contracts-bedrock/src/L2/L1Block.sol";
import { L1BlockCGT } from "src/contracts/Fraxtal/L2/L1BlockCGT.sol";
import { L1CrossDomainMessenger } from "@eth-optimism/contracts-bedrock/src/L1/L1CrossDomainMessenger.sol";
import { L1CrossDomainMessengerCGT } from "src/contracts/Fraxtal/L1/L1CrossDomainMessengerCGT.sol";
import { LegacyMintableERC20 } from "@eth-optimism/contracts-bedrock/src/legacy/LegacyMintableERC20.sol";
import { L1ERC721Bridge } from "@eth-optimism/contracts-bedrock/src/L1/L1ERC721Bridge.sol";
import { L1FeeVaultCGT } from "src/contracts/Fraxtal/L2/L1FeeVaultCGT.sol";
import { L1StandardBridge } from "@eth-optimism/contracts-bedrock/src/L1/L1StandardBridge.sol";
import { L1StandardBridgeCGT } from "src/contracts/Fraxtal/L1/L1StandardBridgeCGT.sol";
import { L2CrossDomainMessenger } from "@eth-optimism/contracts-bedrock/src/L2/L2CrossDomainMessenger.sol";
import { L2CrossDomainMessengerCGT } from "src/contracts/Fraxtal/L2/L2CrossDomainMessengerCGT.sol";
import { L2OutputOracle } from "@eth-optimism/contracts-bedrock/src/L1/L2OutputOracle.sol";
import { L2StandardBridge } from "@eth-optimism/contracts-bedrock/src/L2/L2StandardBridge.sol";
import { L2StandardBridgeCGT } from "src/contracts/Fraxtal/L2/L2StandardBridgeCGT.sol";
import { L2ToL1MessagePasser } from "@eth-optimism/contracts-bedrock/src/L2/L2ToL1MessagePasser.sol";
import { L2ToL1MessagePasserCGT } from "src/contracts/Fraxtal/L2/L2ToL1MessagePasserCGT.sol";
import { LegacyMintableERC20 } from "@eth-optimism/contracts-bedrock/src/legacy/LegacyMintableERC20.sol";
import { MockERC20OwnedV2 } from "src/contracts/Fraxtal/universal/vanity/MockERC20OwnedV2.sol";
import { NSHelper } from "src/script/Fraxtal/North_Star_Hardfork/NSHelper.sol";
import { OptimismMintableERC20 } from "@eth-optimism/contracts-bedrock/src/universal/OptimismMintableERC20.sol";
import {
    OptimismMintableERC20Factory
} from "@eth-optimism/contracts-bedrock/src/universal/OptimismMintableERC20Factory.sol";
import { OptimismPortal } from "@eth-optimism/contracts-bedrock/src/L1/OptimismPortal.sol";
import { OptimismPortalCGT } from "src/contracts/Fraxtal/L1/OptimismPortalCGT.sol";
import { PermissionedDisputeGame } from "@eth-optimism/contracts-bedrock/src/dispute/PermissionedDisputeGame.sol";
import { Predeploys } from "@eth-optimism/contracts-bedrock/src/libraries/Predeploys.sol";
import { ProtocolVersions } from "@eth-optimism/contracts-bedrock/src/L1/ProtocolVersions.sol";
import { Proxy } from "@eth-optimism/contracts-bedrock/src/universal/Proxy.sol";
import { ProxyAdmin } from "@eth-optimism/contracts-bedrock/src/universal/ProxyAdmin.sol";
import { Script } from "forge-std/Script.sol";
// import { SignMessageLib } from "safe-contracts/examples/libraries/SignMessage.sol";
import { SequencerFeeVaultCGT } from "src/contracts/Fraxtal/L2/SequencerFeeVaultCGT.sol";
import { SigUtils } from "src/test/Fraxtal/utils/SigUtils.sol";
import { StandardBridge } from "@eth-optimism/contracts-bedrock/src/universal/StandardBridge.sol";
import { Storage } from "src/script/Fraxtal/testnet/Storage.sol";
import { StorageSetterRestricted } from "src/script/Fraxtal/testnet/StorageSetterRestricted.sol";
import { Strings } from "@openzeppelin-4/contracts/utils/Strings.sol";
import { SystemConfig } from "@eth-optimism/contracts-bedrock/src/L1/SystemConfig.sol";
import { SystemConfigCGT } from "src/contracts/Fraxtal/L1/SystemConfigCGT.sol";
import { Types } from "@eth-optimism/contracts-bedrock/src/libraries/Types.sol";
import { console } from "frax-std/FraxTest.sol";
import "src/Constants.sol" as Constants;

contract NorthStarSharedStateScript is Script, NSHelper {
    // Misc
    ERC20 public FRAX;
    ERC20 public frxUSD;
    GasToken public FXS;
    ERC20 public frxETH;
    address public frxETHL1Address;
    IGnosisSafe public l1Safe;
    address public l1SafeAddress;
    IGnosisSafe public l2Safe;
    address public l2SafeAddress;

    // Fork tracking
    uint256 public l1ForkID;
    uint256 public l2ForkID;

    // To prevent stack-too-deep
    // ------------------------------
    // SystemConfig related
    uint32 public basefeeScalar;
    uint32 public blobbasefeeScalar;
    bytes32 public batcherHash;
    uint64 public gasLimit;
    address public unsafeBlockSigner;
    address public batchInbox;
    address public gasTokenAddr;
    address public systemConfigImplementationAddr;
    uint256 public preEtchTotalSupply;
    IResourceMetering.ResourceConfig public sysCfgResourceConfig;
    SystemConfigCGT.Addresses public sysCfgAddresses;
    string _txJson;
    bytes _theCalldata;
    bytes _theEncodedCall;

    // Misc others
    uint256 public _safeThreshold;
    address[] public _safeOwners;
    bytes32 public _safeTxHash;

    // ------------------------------
    // L1 Contracts
    // ------------------------------

    // L1 Chain-related
    NSChainType public l1Chain;
    uint256 public l1ChainID;

    // L1 StorageSetterRestricted
    StorageSetterRestricted public storageSetterL1;

    // L1 ProxyAdmin
    ProxyAdmin public l1ProxyAdmin;

    // SystemConfig
    SystemConfigCGT public systemConfig_Impl;
    SystemConfigCGT public systemConfig;

    // SuperchainConfig
    ISuperchainConfig public superchainConfig;

    // Superchain ProxyAdmin
    IProxyAdmin public superchainProxyAdmin;

    // OptimismPortalCGT
    OptimismPortalCGT public optimismPortalCGT;
    OptimismPortalCGT public opPortalCGT_Impl;
    Proxy public optimismPortalPxy;
    address payable public optimismPortalPxyAddress;

    // OptimismMintableERC20Factory
    OptimismMintableERC20Factory public optimismMintableERC20Factory_Impl_L1;
    OptimismMintableERC20Factory public l1OptimismMintableERC20Factory;
    OptimismMintableERC20Factory public l2OptimismMintableERC20Factory;

    // L1CrossDomainMessengerCGT
    L1CrossDomainMessengerCGT public l1CrossDomainMessengerCGT_Impl;
    Proxy public l1CrossDomainMessenger;
    address payable public l1CrossDomainMessengerAddress;

    // L1StandardBridgeCGT
    L1StandardBridgeCGT public l1StandardBridgeCGT_Impl;
    Proxy public l1StdBridgePxy;
    address payable public l1StdBridgePxyAddress;
    L1StandardBridgeCGT public l1StandardBridgeCGT;

    // L1ERC721Bridge
    L1ERC721Bridge public l1ERC721Bridge_Impl;
    L1ERC721Bridge public l1Erc721Bridge;

    // L2OutputOracle
    L2OutputOracle public l2OutputOracle;

    // ProtocolVersions
    ProtocolVersions public protocolVersions;

    // Test L1 ERC20s
    MockERC20OwnedV2 public l1Token;
    OptimismMintableERC20 public badL1Token;
    OptimismMintableERC20 public remoteL1Token;
    string public l1TknName;
    string public l1TknSymbol;
    address public l1TknAddr;
    string public remoteL1TknName;
    string public remoteL1TknSymbol;
    address public remoteL1TknAddr;

    // ------------------------------
    // L2 Contracts
    // ------------------------------

    // L2 Chain-related
    NSChainType public l2Chain;
    uint256 public l2ChainID;

    // SigUtils
    SigUtils public sigUtils_FXS;
    SigUtils public sigUtils_wFRAX;
    SigUtils public sigUtils_wfrxETH;
    SigUtils public sigUtils_frxETH;

    // L2 StorageSetterRestricted
    StorageSetterRestricted public storageSetterL2;

    // Tokens
    IERC20ExPPOMWrapped public wFRAX;
    IERC20ExPPOMWrapped public wFRAX_Impl;
    address public wFRAXAddress;
    IERC20ExWrappedPPOM public frxETHL2;
    IERC20ExWrappedPPOM public frxETHL2_Impl;

    // L2 ProxyAdmins
    ProxyAdmin public l2ProxyAdminOpSys;
    ProxyAdmin public l2ProxyAdminCore8;
    ProxyAdmin public l2ProxyAdminRsvd10K;

    // L2toL1MessagePasser (proxy)
    L2ToL1MessagePasser public l2ToL1MessagePasser;
    L2ToL1MessagePasserCGT public l2ToL1MessagePasserCGT_Impl;

    // L2StandardBridge
    L2StandardBridgeCGT public l2StandardBridge;
    L2StandardBridgeCGT public l2StandardBridgeCGT_Impl;
    address public l2StandardBridgeAddress;

    // L2CrossDomainMessenger
    L2CrossDomainMessengerCGT public l2CrossDomainMessenger;
    L2CrossDomainMessengerCGT public l2CrossDomainMessengerCGT_Impl;

    // L1Block
    L1BlockCGT public l1Block;
    L1BlockCGT public l1BlockCGT_Impl;

    // BaseFeeVaultCGT
    BaseFeeVaultCGT public baseFeeVaultCGT;
    BaseFeeVaultCGT public baseFeeVaultCGT_Impl;

    // L1FeeVaultCGT
    L1FeeVaultCGT public l1FeeVaultCGT;
    L1FeeVaultCGT public l1FeeVaultCGT_Impl;

    // SequencerFeeVaultCGT
    SequencerFeeVaultCGT public sequencerFeeVaultCGT;
    SequencerFeeVaultCGT public sequencerFeeVaultCGT_Impl;

    // Test L2 ERC20s
    OptimismMintableERC20 public l2Token;
    LegacyMintableERC20 public legacyL2Token;
    MockERC20OwnedV2 public nativeL2Token;
    OptimismMintableERC20 public badL2Token;
    address public nativeL2TknAddr;
    string public nativeL2TknName;
    string public nativeL2TknSymbol;

    // Important owners
    address public gameProposer;
    address public l1ProxyAdminOwner;
    address public l2ProxyAdminOpSysOwner;
    address public l2ProxyAdminCore8Owner;
    address public l2ProxyAdminRsvd10KOwner;
    address public systemConfigOwner;
    address public systemConfigUpgradeCaller;

    // Check https://github.com/ethereum-optimism/optimism/blob/6a871c54512ebdb749f46ccb7d27b1b60510eba1/op-deployer/pkg/deployer/init.go#L112 for logic
    // For tests
    string public mnemonic;
    uint256 public junkDeployerPk;
    address public junkDeployerAddress;
    uint256 public junkDeployerHelperPk;
    address public junkDeployerHelperAddress;
    uint256 public gameProposerPk;
    uint256 public l1ProxyAdminOwnerPk;
    uint256 public l2ProxyAdminOpSysOwnerPk;
    uint256 public systemConfigOwnerPk;
    address public testerAddress;

    function defaultSetup() internal virtual {
        // L1
        // =====================================
        l1Chain = getNSChainType(vm.envString("NS_L1_CHAIN_CHOICE"));
        l1ChainID = getNSChainID(l1Chain);
        l1ForkID = getNSForkId(vm.envString("NS_L1_CHAIN_CHOICE"));
        console.log("Chain: %s", vm.envString("NS_L1_CHAIN_CHOICE"));
        console.log("Chain ID: %s", l1ChainID);
        console.log("Fork ID: %s", l1ForkID);

        // Mnemonics and keys
        mnemonic = getDeployerMnemonic(l1Chain);
        junkDeployerPk = vm.deriveKey(mnemonic, 0);
        junkDeployerAddress = vm.addr(vm.deriveKey(mnemonic, 0));
        junkDeployerHelperPk = vm.deriveKey(mnemonic, 1);
        junkDeployerHelperAddress = vm.addr(vm.deriveKey(mnemonic, 1));
        gameProposerPk = vm.deriveKey(mnemonic, "m/44'/60'/2'/2151908/", 1);
        l1ProxyAdminOwnerPk = vm.deriveKey(mnemonic, "m/44'/60'/2'/2151908/", 6);
        l2ProxyAdminOpSysOwnerPk = vm.deriveKey(mnemonic, "m/44'/60'/2'/2151908/", 5);
        systemConfigOwnerPk = vm.deriveKey(mnemonic, "m/44'/60'/2'/2151908/", 10);
        testerAddress = vm.envAddress("PK_ADDRESS");

        // Instantiate FRAX
        FRAX = ERC20(fetchNSAddress(l1Chain, NSAddressType.FRAX_ERC20));

        // Instantiate frxUSD
        frxUSD = ERC20(fetchNSAddress(l1Chain, NSAddressType.FRXUSD_ERC20));

        // Instantiate FXS
        FXS = GasToken(fetchNSAddress(l1Chain, NSAddressType.FXS_ERC20));

        // Instantiate frxETH
        frxETH = ERC20(fetchNSAddress(l1Chain, NSAddressType.FRXETH_ERC20));
        frxETHL1Address = address(frxETH);

        // Instantiate the L1 owner safe
        l1SafeAddress = fetchNSAddress(l1Chain, NSAddressType.L1_OWNER_SAFE);
        l1Safe = IGnosisSafe(payable(l1SafeAddress));

        // Instantiate the L1 storage setter
        storageSetterL1 = StorageSetterRestricted(fetchNSAddress(l1Chain, NSAddressType.L1_STORAGE_SETTER));

        // Instantiate the SystemConfig
        systemConfig_Impl = SystemConfigCGT(fetchNSAddress(l1Chain, NSAddressType.SYSTEM_CONFIG_IMPL));
        systemConfig = SystemConfigCGT(fetchNSAddress(l1Chain, NSAddressType.SYSTEM_CONFIG_PROXY));
        systemConfigOwner = fetchNSAddress(l1Chain, NSAddressType.SYSTEM_CONFIG_OWNER);
        systemConfigUpgradeCaller = fetchNSAddress(l1Chain, NSAddressType.SYSTEM_CONFIG_UPGRADE_CALLER);

        // Instantiate the SuperchainConfig
        superchainConfig = ISuperchainConfig(fetchNSAddress(l1Chain, NSAddressType.SUPERCHAIN_CONFIG_PROXY));

        // Instantiate the Superchain ProxyAdmin
        superchainProxyAdmin = IProxyAdmin(fetchNSAddress(l1Chain, NSAddressType.SUPERCHAIN_CONFIG_PROXY_ADMIN));

        // Instantiate the L1 ProxyAdmin
        l1ProxyAdmin = ProxyAdmin(fetchNSAddress(l1Chain, NSAddressType.L1_PROXY_ADMIN));
        l1ProxyAdminOwner = l1ProxyAdmin.owner();

        // Instantiate the OptimismPortal
        opPortalCGT_Impl = OptimismPortalCGT(payable(fetchNSAddress(l1Chain, NSAddressType.OPTIMISM_PORTAL_IMPL)));
        optimismPortalPxyAddress = payable(fetchNSAddress(l1Chain, NSAddressType.OPTIMISM_PORTAL_PROXY));
        optimismPortalCGT = OptimismPortalCGT(optimismPortalPxyAddress);
        optimismPortalPxy = Proxy(optimismPortalPxyAddress);

        // Instantiate the L1CrossDomainMessenger
        l1CrossDomainMessengerCGT_Impl = L1CrossDomainMessengerCGT(
            fetchNSAddress(l1Chain, NSAddressType.L1_CROSS_DOMAIN_MESSENGER_IMPL)
        );
        l1CrossDomainMessengerAddress = payable(fetchNSAddress(l1Chain, NSAddressType.L1_CROSS_DOMAIN_MESSENGER_PROXY));
        l1CrossDomainMessenger = Proxy(l1CrossDomainMessengerAddress);

        // Instantiate the L1StandardBridge
        l1StandardBridgeCGT_Impl = L1StandardBridgeCGT(
            payable(fetchNSAddress(l1Chain, NSAddressType.L1_STANDARD_BRIDGE_IMPL))
        );
        l1StdBridgePxyAddress = payable(fetchNSAddress(l1Chain, NSAddressType.L1_STANDARD_BRIDGE_PROXY));
        l1StdBridgePxy = Proxy(l1StdBridgePxyAddress);
        l1StandardBridgeCGT = l1StandardBridgeCGT = L1StandardBridgeCGT(payable(l1StdBridgePxy));

        // Instantiate the L1ERC721Bridge
        l1ERC721Bridge_Impl = L1ERC721Bridge(fetchNSAddress(l1Chain, NSAddressType.L1_ERC721_BRIDGE_IMPL));
        l1Erc721Bridge = L1ERC721Bridge(fetchNSAddress(l1Chain, NSAddressType.L1_ERC721_BRIDGE_PROXY));

        // Instantiate the L2OutputOracle
        l2OutputOracle = L2OutputOracle(fetchNSAddress(l1Chain, NSAddressType.L2_OUTPUT_ORACLE_PROXY));

        // Instantiate the OptimismMintableERC20Factory
        optimismMintableERC20Factory_Impl_L1 = OptimismMintableERC20Factory(
            fetchNSAddress(l1Chain, NSAddressType.OPTIMISM_MINTABLE_ERC20_FACTORY_IMPL)
        );
        l1OptimismMintableERC20Factory = OptimismMintableERC20Factory(
            fetchNSAddress(l1Chain, NSAddressType.OPTIMISM_MINTABLE_ERC20_FACTORY_PROXY)
        );

        // Instantiate the ProtocolVersions
        protocolVersions = ProtocolVersions(fetchNSAddress(l1Chain, NSAddressType.PROTOCOL_VERSIONS_PROXY));

        // L1 test tokens
        l1Token = MockERC20OwnedV2(fetchNSAddress(l1Chain, NSAddressType.L1TOKEN));
        badL1Token = OptimismMintableERC20(fetchNSAddress(l1Chain, NSAddressType.BADL1TOKEN));
        remoteL1Token = OptimismMintableERC20(fetchNSAddress(l1Chain, NSAddressType.REMOTEL1TOKEN));

        // Store token info
        if (address(l1Token) != address(0)) {
            l1TknName = l1Token.name();
            l1TknSymbol = l1Token.symbol();
            l1TknAddr = address(l1Token);
        }
        if (address(remoteL1Token) != address(0)) {
            remoteL1TknName = remoteL1Token.name();
            remoteL1TknSymbol = remoteL1Token.symbol();
            remoteL1TknAddr = address(remoteL1Token);
        }

        // SystemConfig data
        // ----------------------------------------------
        // Fetch
        (
            SystemConfigCGT.Addresses memory _sysAddresses,
            IResourceMetering.ResourceConfig memory _sysResourceConfig,
            SystemConfigMisc memory _sysMisc
        ) = fetchSystemConfigInfo(l1Chain);

        // Fill in
        basefeeScalar = _sysMisc.baseFeeScalar;
        blobbasefeeScalar = _sysMisc.blobBaseFeeScalar;
        batcherHash = _sysMisc.batcherHash;
        gasLimit = _sysMisc.gasLimit;
        unsafeBlockSigner = _sysMisc.unsafeBlockSigner;
        sysCfgResourceConfig = _sysResourceConfig;
        batchInbox = _sysMisc.batchInbox;
        gasTokenAddr = _sysMisc.gasTokenAddress;
        sysCfgAddresses = _sysAddresses;

        // Make L1 contracts persistent
        vm.makePersistent(address(l1Token));
        vm.makePersistent(address(badL1Token));
        vm.makePersistent(address(remoteL1Token));
        vm.makePersistent(address(l1Safe));
        vm.makePersistent(address(storageSetterL1));
        vm.makePersistent(address(systemConfig), address(superchainConfig));
        vm.makePersistent(optimismPortalPxyAddress, l1CrossDomainMessengerAddress, l1StdBridgePxyAddress);
        vm.makePersistent(address(l1Erc721Bridge), address(l2OutputOracle), address(l1OptimismMintableERC20Factory));

        // L1 Labels
        vm.label(address(l1Safe), "l1Safe");
        vm.label(address(storageSetterL1), "storageSetterL1");
        vm.label(address(FXS), "FXS");
        vm.label(address(systemConfig), "SystemConfigPxy");
        vm.label(address(superchainConfig), "SuperchainConfigPxy");
        vm.label(l1CrossDomainMessengerAddress, "L1CrossDomainMessengerCGTPxy");
        vm.label(l1ProxyAdmin.getProxyImplementation(l1CrossDomainMessengerAddress), "L1CrossDomainMessengerImpl");
        vm.label(l1StdBridgePxyAddress, "L1StandardBridgeCGTPxy");
        vm.label(l1ProxyAdmin.getProxyImplementation(l1StdBridgePxyAddress), "L1StandardBridgeImpl");
        vm.label(address(l1Token), "L1Token");
        vm.label(address(badL1Token), "BadL1Token");
        vm.label(address(remoteL1Token), "RemoteL1Token");

        // L2
        // =====================================
        l2Chain = getNSChainType(vm.envString("NS_L2_CHAIN_CHOICE"));
        l2ChainID = getNSChainID(l2Chain);
        l2ForkID = getNSForkId(vm.envString("NS_L2_CHAIN_CHOICE"));
        console.log("Chain: %s", vm.envString("NS_L2_CHAIN_CHOICE"));
        console.log("Chain ID: %s", l2ChainID);
        console.log("Fork ID: %s", l2ForkID);

        // Instantiate the L2 owner Safe
        l2SafeAddress = fetchNSAddress(l2Chain, NSAddressType.L2_ADMIN_SAFE);
        l2Safe = IGnosisSafe(payable(l2SafeAddress));

        // Instantiate the L2 StorageSetterRestricted
        storageSetterL2 = StorageSetterRestricted(fetchNSAddress(l2Chain, NSAddressType.L2_STORAGE_SETTER));

        // Instantiate wFRAX
        wFRAX = IERC20ExPPOMWrapped(payable(fetchNSAddress(l2Chain, NSAddressType.L2_FXS_ERC20)));
        wFRAX_Impl = IERC20ExPPOMWrapped(payable(fetchNSAddress(l2Chain, NSAddressType.WFRAX_IMPL)));
        wFRAXAddress = address(payable(wFRAX));

        // Instantiate frxETHL2
        frxETHL2 = IERC20ExWrappedPPOM(fetchNSAddress(l2Chain, NSAddressType.WFRXETH_ERC20));
        frxETHL2_Impl = IERC20ExWrappedPPOM(fetchNSAddress(l2Chain, NSAddressType.FRXETHL2_IMPL));

        // Instantiate the L2 ProxyAdmins
        l2ProxyAdminOpSys = ProxyAdmin(Predeploys.PROXY_ADMIN);
        l2ProxyAdminOpSysOwner = fetchNSAddress(l2Chain, NSAddressType.L2_PROXY_ADMIN_OP_SYS_OWNER);
        l2ProxyAdminCore8 = ProxyAdmin(fetchNSAddress(l2Chain, NSAddressType.L2_PROXY_ADMIN_CORE8));
        l2ProxyAdminCore8Owner = fetchNSAddress(l2Chain, NSAddressType.L2_PROXY_ADMIN_CORE8_OWNER);
        l2ProxyAdminRsvd10K = ProxyAdmin(fetchNSAddress(l2Chain, NSAddressType.L2_PROXY_ADMIN_RSVD_10K));
        l2ProxyAdminRsvd10KOwner = fetchNSAddress(l2Chain, NSAddressType.L2_PROXY_ADMIN_RSVD_10K_OWNER);

        // Instantiate the L2ToL1MessagePasser
        l2ToL1MessagePasser = L2ToL1MessagePasser(payable(Predeploys.L2_TO_L1_MESSAGE_PASSER));
        l2ToL1MessagePasserCGT_Impl = L2ToL1MessagePasserCGT(
            payable(fetchNSAddress(l2Chain, NSAddressType.L2_TO_L1_MESSAGE_PASSER_CGT_IMPL))
        );

        // Instantiate the L2StandardBridgeCGT
        l2StandardBridge = L2StandardBridgeCGT(payable(Predeploys.L2_STANDARD_BRIDGE));
        l2StandardBridgeCGT_Impl = L2StandardBridgeCGT(
            payable(fetchNSAddress(l2Chain, NSAddressType.L2_STANDARD_BRIDGE_CGT_IMPL))
        );
        l2StandardBridgeAddress = address(l2StandardBridge);

        // Instantiate the OptimismMintableERC20Factory
        l2OptimismMintableERC20Factory = OptimismMintableERC20Factory(
            payable(Predeploys.OPTIMISM_MINTABLE_ERC20_FACTORY)
        );

        // Instantiate the L2CrossDomainMessengerCGT
        l2CrossDomainMessenger = L2CrossDomainMessengerCGT(Predeploys.L2_CROSS_DOMAIN_MESSENGER);
        l2CrossDomainMessengerCGT_Impl = L2CrossDomainMessengerCGT(
            fetchNSAddress(l2Chain, NSAddressType.L2_CROSS_DOMAIN_MESSENGER_CGT_IMPL)
        );

        // Instantiate the L1BlockCGT
        l1Block = L1BlockCGT(Predeploys.L1_BLOCK_ATTRIBUTES);
        l1BlockCGT_Impl = L1BlockCGT(fetchNSAddress(l2Chain, NSAddressType.L1_BLOCK_CGT_IMPL));

        // Instantiate the BaseFeeVaultCGT
        baseFeeVaultCGT = BaseFeeVaultCGT(payable(Predeploys.BASE_FEE_VAULT));
        baseFeeVaultCGT_Impl = BaseFeeVaultCGT(payable(fetchNSAddress(l2Chain, NSAddressType.BASE_FEE_VAULT_CGT_IMPL)));

        // Instantiate the L1FeeVaultCGT
        l1FeeVaultCGT = L1FeeVaultCGT(payable(Predeploys.L1_FEE_VAULT));
        l1FeeVaultCGT_Impl = L1FeeVaultCGT(payable(fetchNSAddress(l2Chain, NSAddressType.L1_FEE_VAULT_CGT_IMPL)));

        // Instantiate the SequencerFeeVaultCGT
        sequencerFeeVaultCGT = SequencerFeeVaultCGT(payable(Predeploys.SEQUENCER_FEE_WALLET));
        sequencerFeeVaultCGT_Impl = SequencerFeeVaultCGT(
            payable(fetchNSAddress(l2Chain, NSAddressType.SEQUENCER_FEE_VAULT_CGT_IMPL))
        );

        // L2 test tokens
        l2Token = OptimismMintableERC20(fetchNSAddress(l2Chain, NSAddressType.L2TOKEN));
        badL2Token = OptimismMintableERC20(fetchNSAddress(l2Chain, NSAddressType.BADL2TOKEN));
        legacyL2Token = LegacyMintableERC20(fetchNSAddress(l2Chain, NSAddressType.LEGACYL2TOKEN));
        nativeL2Token = MockERC20OwnedV2(fetchNSAddress(l2Chain, NSAddressType.NATIVEL2TOKEN));

        if (address(nativeL2Token) != address(0)) {
            nativeL2TknAddr = address(nativeL2Token);
            nativeL2TknName = nativeL2Token.name();
            nativeL2TknSymbol = nativeL2Token.symbol();
        }

        // Make L2 contracts persistent
        vm.makePersistent(address(legacyL2Token));
        vm.makePersistent(address(l2Token));
        vm.makePersistent(address(badL2Token));
        vm.makePersistent(address(nativeL2Token));
        vm.makePersistent(address(l2Safe));
        vm.makePersistent(address(storageSetterL2));
        vm.makePersistent(address(wFRAX), address(frxETHL2));
        vm.makePersistent(address(wFRAX_Impl), address(frxETHL2_Impl));
        vm.makePersistent(address(l2ProxyAdminOpSys), address(l2ProxyAdminCore8), address(l2ProxyAdminRsvd10K));
        vm.makePersistent(
            address(l2ToL1MessagePasser),
            address(l2StandardBridge),
            address(l2OptimismMintableERC20Factory)
        );
        vm.makePersistent(address(l2ToL1MessagePasserCGT_Impl));
        vm.makePersistent(
            address(l2StandardBridgeCGT_Impl),
            address(l2CrossDomainMessengerCGT_Impl),
            address(l1BlockCGT_Impl)
        );
        vm.makePersistent(address(baseFeeVaultCGT), address(l1FeeVaultCGT), address(sequencerFeeVaultCGT));
        vm.makePersistent(
            address(baseFeeVaultCGT_Impl),
            address(l1FeeVaultCGT_Impl),
            address(sequencerFeeVaultCGT_Impl)
        );
        vm.makePersistent(address(l2CrossDomainMessenger), address(l1Block));

        // L2 labels
        vm.label(address(l2Safe), "l2Safe");
        vm.label(address(storageSetterL2), "storageSetterL2");
        vm.label(address(wFRAX), "wFRAX");
        vm.label(address(wFRAX_Impl), "wFRAX_Impl");
        vm.label(address(frxETHL2), "frxETHL2");
        vm.label(address(frxETHL2_Impl), "frxETHL2_Impl");
        vm.label(address(l2ProxyAdminOpSys), "l2ProxyAdminOpSys");
        vm.label(address(l2ProxyAdminCore8), "l2ProxyAdminCore8");
        vm.label(address(l2ProxyAdminRsvd10K), "l2ProxyAdminRsvd10K");
        vm.label(address(l2ToL1MessagePasser), "L2ToL1MessagePasser");
        vm.label(address(l2ToL1MessagePasserCGT_Impl), "L2ToL1MessagePasserCGT_Impl");
        vm.label(address(l2StandardBridge), "L2StandardBridgeCGT");
        vm.label(address(l2StandardBridgeCGT_Impl), "L2StandardBridgeCGT_Impl");
        vm.label(address(l2OptimismMintableERC20Factory), "OptimismMintableERC20Factory");
        vm.label(address(l2CrossDomainMessenger), "L2CrossDomainMessengerCGT");
        vm.label(address(l2CrossDomainMessengerCGT_Impl), "L2CrossDomainMessengerGGT_Impl");
        vm.label(address(l1Block), "L1BlockCGT");
        vm.label(address(l1BlockCGT_Impl), "L1BlockCGT_Impl");
        vm.label(address(baseFeeVaultCGT), "BaseFeeVaultCGT");
        vm.label(address(baseFeeVaultCGT_Impl), "BaseFeeVaultCGT_Impl");
        vm.label(address(l1FeeVaultCGT), "L1FeeVaultCGT");
        vm.label(address(l1FeeVaultCGT_Impl), "L1FeeVaultCGT_Impl");
        vm.label(address(sequencerFeeVaultCGT), "SequencerFeeVaultCGT");
        vm.label(address(sequencerFeeVaultCGT_Impl), "SequencerFeeVaultCGT_Impl");
        vm.label(address(legacyL2Token), "LegacyL2Token");
        vm.label(address(l2Token), "L2Token");
        vm.label(address(badL2Token), "BadL2Token");
        vm.label(address(nativeL2Token), "NativeL2Token");
    }

    function generateTxJson(address _to, bytes memory _data) public returns (string memory _txString) {
        _txString = "{";
        _txString = string.concat(_txString, '"to": "', Strings.toHexString(_to), '", ');
        _txString = string.concat(_txString, '"value": "0", ');
        _txString = string.concat(_txString, '"data": "', iToHex(_data, true), '", ');
        _txString = string.concat(_txString, '"contractMethod": null, ');
        _txString = string.concat(_txString, '"contractInputsValues": null');
        _txString = string.concat(_txString, "}");
    }

    function iToHex(bytes memory buffer, bool _addPrefix) public pure returns (string memory) {
        // Fixed buffer size for hexadecimal convertion
        bytes memory converted = new bytes(buffer.length * 2);

        bytes memory _base = "0123456789abcdef";

        for (uint256 i = 0; i < buffer.length; i++) {
            converted[i * 2] = _base[uint8(buffer[i]) / _base.length];
            converted[i * 2 + 1] = _base[uint8(buffer[i]) % _base.length];
        }

        if (_addPrefix) return string(abi.encodePacked("0x", converted));
        else return string(abi.encodePacked(converted));
    }

    function execSafeTx_L1_00(address _to, bytes memory _calldata, bool _approveToo) public {
        _execL1SafeTx(_to, _calldata, _approveToo);
    }

    function execSafeTx_L1_01(address _to, bytes memory _calldata, bool _approveToo, address _proxyAddress) public {
        // Skip if StorageSetterRestricted is already there and initialization was cleared
        try StorageSetterRestricted(_proxyAddress).getUint(0) returns (uint256 _result) {
            console.log("   -- _result: ", _result);
            if (_result == 0) {
                console.log("   -- StorageSetterRestricted already present and initialization is cleared. Skipping");
                return;
            } else {
                console.log(
                    "   -- StorageSetterRestricted already present, but initialization is not cleared. Re-upgrading."
                );
            }
        } catch {
            console.log("   -- StorageSetterRestricted not present. Will upgrade.");
        }

        // Execute
        _execL1SafeTx(_to, _calldata, _approveToo);
    }

    function execSafeTx_L1_02(
        address _to,
        bytes memory _calldata,
        bool _approveToo,
        address _proxyAddress,
        string memory _expectedVersion
    ) public {
        // Skip if upgrade already happened
        try ISemver(_proxyAddress).version() returns (string memory _result) {
            console.log("   -- _result: ", _result);
            if (compareStrings(_expectedVersion, _result)) {
                console.log("   -- version() matches expected. Upgrade already happened, so will skip");
                return;
            } else {
                console.log("   -- version() mismatch. Upgrade did not happen yet, so will proceed.");
            }
        } catch {
            console.log("   -- version() not present. Will upgrade.");
        }

        // Execute
        _execL1SafeTx(_to, _calldata, _approveToo);
    }

    function execSafeTx_L2_02_VCheck(
        address _to,
        bytes memory _calldata,
        bool _approveToo,
        address _proxyAddress,
        string memory _expectedVersion
    ) public {
        // Skip if upgrade already happened
        try ISemver(_proxyAddress).version() returns (string memory _result) {
            console.log("   -- _result: ", _result);
            if (compareStrings(_expectedVersion, _result)) {
                console.log("   -- version() matches expected. Upgrade already happened, so will skip");
                return;
            } else {
                console.log("   -- version() mismatch. Upgrade did not happen yet, so will proceed.");
            }
        } catch {
            console.log("   -- version() not present. Will upgrade.");
        }
        _execL2SafeTx(_to, _calldata, _approveToo);
    }

    function execSafeTx_L2_03_SSCheck(
        address _to,
        bytes memory _calldata,
        bool _approveToo,
        address _proxyAddress
    ) public {
        // Skip if StorageSetterRestricted is already there and initialization was cleared
        try StorageSetterRestricted(_proxyAddress).getUint(0) returns (uint256 _result) {
            console.log("   -- _result: ", _result);
            if (_result == 0) {
                console.log("   -- StorageSetterRestricted already present and initialization is cleared. Skipping");
                return;
            } else {
                console.log(
                    "   -- StorageSetterRestricted already present, but initialization is not cleared. Re-upgrading."
                );
            }
        } catch {
            console.log("   -- StorageSetterRestricted not present. Will upgrade.");
        }

        // Execute
        _execL2SafeTx(_to, _calldata, _approveToo);
    }

    function execSafeTx_L2_03_VCheck(
        address _to,
        bytes memory _calldata,
        bool _approveToo,
        address _proxyAddress,
        string memory _expectedVersion
    ) public {
        // Skip if upgrade already happened
        try ISemver(_proxyAddress).version() returns (string memory _result) {
            console.log("   -- _result: ", _result);
            if (compareStrings(_expectedVersion, _result)) {
                console.log("   -- version() matches expected. Upgrade already happened, so will skip");
                return;
            } else {
                console.log("   -- version() mismatch. Upgrade did not happen yet, so will proceed.");
            }
        } catch {
            console.log("   -- version() not present. Will upgrade.");
        }

        _execL2SafeTx(_to, _calldata, _approveToo);
    }

    function _execL1SafeTx(address _to, bytes memory _calldata, bool _approveToo) internal {
        _execSafeTx(_to, _calldata, _approveToo, l1Safe, 0);
    }

    function _execL2SafeTx(address _to, bytes memory _calldata, bool _approveToo) internal {
        _execSafeTx(_to, _calldata, _approveToo, l2Safe, 0);
    }

    function execL2SafeTestTx(IGnosisSafe _safe) public {
        // Sent gas to a test address
        address _to = address(0);
        bytes memory _calldata = "";

        _execSafeTx(_to, _calldata, false, _safe, 100 gwei);
    }

    function execL2SafeSpecifiedSafeTx(
        address _to,
        bytes memory _calldata,
        bool _approveToo,
        IGnosisSafe _safe
    ) public {
        _execSafeTx(_to, _calldata, false, _safe, 0);
    }

    function _execSafeTx(
        address _to,
        bytes memory _calldata,
        bool _approveToo,
        IGnosisSafe _safe,
        uint256 _value
    ) internal {
        // See
        // https://user-images.githubusercontent.com/33375223/211921017-b57ae2f3-0d33-4265-a87d-945a69a77ba6.png

        // Get the nonce
        uint256 _nonce = _safe.nonce();

        // Encode the tx
        bytes memory _encodedTxData = _safe.encodeTransactionData(
            _to,
            _value,
            _calldata,
            SafeOps.Operation.Call,
            0,
            0,
            0,
            address(0),
            payable(address(0)),
            _nonce
        );

        // Sign the encoded tx
        bytes memory signature;
        if (msg.sender == junkDeployerAddress) {
            // If the caller is not a signer
            console.log("   -- Caller is not a signer");
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(junkDeployerPk, keccak256(_encodedTxData));
            signature = abi.encodePacked(r, s, v); // Note order is reversed here
            console.log("-------- Signature --------");
            console.logBytes(signature);
        } else {
            // This is the signature format used if the caller is also the signer.
            console.log("   -- Caller is a signer");
            signature = abi.encodePacked(uint256(uint160(junkDeployerAddress)), bytes32(0), uint8(1));
        }

        // (Optional) Approve the tx hash
        if (_approveToo) {
            // Have to static call here due to compiler issues
            (bool _success, bytes memory _returnData) = address(_safe).staticcall(
                abi.encodeWithSelector(
                    _safe.getTransactionHash.selector,
                    _to,
                    0,
                    _calldata,
                    SafeOps.Operation.Call,
                    0,
                    0,
                    0,
                    address(0),
                    payable(address(0)),
                    _nonce
                )
            );
            require(_success, "approveAndExecSafeTx failed");
            _safeTxHash = abi.decode(_returnData, (bytes32));
            console.logBytes(_returnData);

            // Approve the hash
            _safe.approveHash(_safeTxHash);
        }

        // Execute the transaction
        _safe.execTransaction({
            to: _to,
            value: _value,
            data: _calldata,
            operation: SafeOps.Operation.Call,
            safeTxGas: 0,
            baseGas: 0,
            gasPrice: 0,
            gasToken: address(0),
            refundReceiver: payable(address(0)),
            signatures: signature
        });
    }

    function compareStrings(string memory _a, string memory _b) public pure returns (bool) {
        return keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked(_b));
    }

    function printSystemConfigInfo() public {
        console.log("===================== SystemConfig Important Info =====================");
        console.log("// SystemConfig misc");
        console.log("uint32 internal constant SYSCFG_MISC__BASE_FEE_SCALAR = 0;");
        console.log("uint32 internal constant SYSCFG_MISC__BLOB_BASE_FEE_SCALAR = 0;");
        console.log("bytes32 internal constant SYSCFG_MISC__BATCHER_HASH = <PASTE BELOW HERE>;");
        console.logBytes32(systemConfig.batcherHash());
        console.log("uint64 internal constant SYSCFG_MISC__GAS_LIMIT = %s;", systemConfig.gasLimit());
        console.log(
            "address internal constant SYSCFG_MISC__UNSAFE_BLOCK_SIGNER = %s;",
            systemConfig.unsafeBlockSigner()
        );
        console.log("address internal constant SYSCFG_MISC__BATCH_INBOX = %s;", systemConfig.batchInbox());
        console.log("address internal constant SYSCFG_MISC__GAS_TOKEN_ADDRESS = %s;", address(FXS));

        console.log("\n// SystemConfig Addresses");
        console.log(
            "address internal constant SYSCFG_ADDRS__CDM = %s;",
            address(uint160(uint256(vm.load(address(systemConfig), systemConfig.L1_CROSS_DOMAIN_MESSENGER_SLOT()))))
        );
        console.log(
            "address internal constant SYSCFG_ADDRS__ERC721BRG = %s;",
            address(uint160(uint256(vm.load(address(systemConfig), systemConfig.L1_ERC_721_BRIDGE_SLOT()))))
        );
        console.log(
            "address internal constant SYSCFG_ADDRS__STDBRG = %s;",
            address(uint160(uint256(vm.load(address(systemConfig), systemConfig.L1_STANDARD_BRIDGE_SLOT()))))
        );
        console.log(
            "address internal constant SYSCFG_ADDRS__L2OO = %s;",
            address(uint160(uint256(vm.load(address(systemConfig), systemConfig.L2_OUTPUT_ORACLE_SLOT()))))
        );
        console.log("address internal constant SYSCFG_ADDRS__DSPGMFCTY = %s;", address(0));
        console.log(
            "address internal constant SYSCFG_ADDRS__OPPTL = %s;",
            address(uint160(uint256(vm.load(address(systemConfig), systemConfig.OPTIMISM_PORTAL_SLOT()))))
        );
        console.log(
            "address internal constant SYSCFG_ADDRS__OPMNTERC20FCTY = %s;",
            address(
                uint160(uint256(vm.load(address(systemConfig), systemConfig.OPTIMISM_MINTABLE_ERC20_FACTORY_SLOT())))
            )
        );
        console.log("address internal constant SYSCFG_ADDRS__GASPAYTKN = %s;", address(FXS));

        console.log("\n// SystemConfig ResourceConfig");
        IResourceMetering.ResourceConfig memory _resourceConfig = systemConfig.resourceConfig();
        console.log("uint32 internal constant SYSCFG_RESCFG__MAX_RES_LIMIT = %s;", _resourceConfig.maxResourceLimit);
        console.log("uint8 internal constant SYSCFG_RESCFG__ELAST_MULT = %s;", _resourceConfig.elasticityMultiplier);
        console.log(
            "uint8 internal constant SYSCFG_RESCFG__BASE_FEE_MAX_CHNG_DENOM = %s;",
            _resourceConfig.baseFeeMaxChangeDenominator
        );
        console.log("uint32 internal constant SYSCFG_RESCFG__MIN_BASE_FEE = %s;", _resourceConfig.minimumBaseFee);
        console.log("uint32 internal constant SYSCFG_RESCFG__SYS_TX_MAX_GAS = %s;", _resourceConfig.systemTxMaxGas);
        console.log("uint128 internal constant SYSCFG_RESCFG__MAX_BASE_FEE = %s;", _resourceConfig.maximumBaseFee);
    }

    function ffiGetProveWithdrawalTransactionInputs(
        Types.WithdrawalTransaction memory _tx
    ) public returns (bytes32, bytes32, bytes32, bytes32, bytes[] memory) {
        string[] memory cmds = new string[](8);
        cmds[0] = "./scripts/go/bin/differential-testing";
        cmds[1] = "getProveWithdrawalTransactionInputs";
        cmds[2] = vm.toString(_tx.nonce);
        cmds[3] = vm.toString(_tx.sender);
        cmds[4] = vm.toString(_tx.target);
        cmds[5] = vm.toString(_tx.value);
        cmds[6] = vm.toString(_tx.gasLimit);
        cmds[7] = vm.toString(_tx.data);

        // Example
        // go ./scripts/go/differential-testing.go 0 0xe05fcC23807536bEe418f142D19fa0d21BB0cfF7 0x0376AAc07Ad725E01357B1725B5ceC61aE10473c 100 100000 0x

        bytes memory result = vm.ffi(cmds);
        (
            bytes32 stateRoot,
            bytes32 storageRoot,
            bytes32 outputRoot,
            bytes32 withdrawalHash,
            bytes[] memory withdrawalProof
        ) = abi.decode(result, (bytes32, bytes32, bytes32, bytes32, bytes[]));

        return (stateRoot, storageRoot, outputRoot, withdrawalHash, withdrawalProof);
    }

    function ffiProveWithdrawalTx(bytes32 _txHash) public returns (bytes32 _resultHash) {
        string[] memory cmds = new string[](5);
        cmds[0] = "node";
        cmds[1] = "./scripts/CCMWithdrawalHelper/CCMWithdrawalHelper.js";
        cmds[2] = vm.toString(_txHash);
        cmds[3] = "0";
        cmds[4] = "0";

        bytes memory _resultBytes = vm.ffi(cmds);
        (_resultHash) = abi.decode(_resultBytes, (bytes32));
        // console.log("------- ffiProveWithdrawalTx full result -------");
        // console.logBytes(_resultBytes);
        console.log("------- ffiProveWithdrawalTx _resultHash -------");
        console.logBytes32(_resultHash);
    }

    function ffiFinalizeWithdrawalTx(bytes32 _txHash) public returns (bytes32 _resultHash) {
        string[] memory cmds = new string[](5);
        cmds[0] = "node";
        cmds[1] = "./scripts/CCMWithdrawalHelper/CCMWithdrawalHelper.js";
        cmds[2] = vm.toString(_txHash);
        cmds[3] = "1";
        cmds[4] = "0";

        bytes memory _resultBytes = vm.ffi(cmds);
        (_resultHash) = abi.decode(_resultBytes, (bytes32));
        // console.log("------- ffiFinalizeWithdrawalTx full result -------");
        // console.logBytes(_resultBytes);
        console.log("------- ffiFinalizeWithdrawalTx _resultHash -------");
        console.logBytes32(_resultHash);
    }
}
