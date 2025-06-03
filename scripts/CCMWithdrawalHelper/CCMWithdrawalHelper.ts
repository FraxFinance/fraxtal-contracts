import { createPublicClient, defineChain, http, Address, createWalletClient, toBytes } from "viem";
import { mnemonicToAccount } from "viem/accounts";
import { getTransactionReceipt } from "viem/actions";
import {
  base,
  chainConfig,
  getWithdrawals,
  publicActionsL1,
  publicActionsL2,
  walletActionsL1,
  walletActionsL2,
} from "viem/op-stack";

const l1Contracts = {
  AddressManager: "0x9A9f2CCfdE556A7E9Ff0848998Aa4a0CFD8863AE",
  L1CrossDomainMessenger: "0x77eaF314EFDA0541286197bCA2d48fef6D762F90",
  L1CrossDomainMessengerProxy: "0xc3e53F4d16Ae77Db1c982e75a937B9f60FE63690",
  L1ERC721Bridge: "0x8A6c3A077AA3E825CEE6678f649d9280AF2A102C",
  L1ERC721BridgeProxy: "0x9E545E3C0baAB3E08CdfD552C960A1050f373042",
  L1StandardBridge: "0xcC6E2Cea5f0238A38c186303A28062DEdAE22c85",
  L1StandardBridgeProxy: "0xE6E340D132b5f46d1e472DebcD681B2aBc16e57E",
  L2OutputOracle: "0x5Be3C0817F561dd52c2Df5C696a4833F7ed20F17",
  L2OutputOracleProxy: "0xc5a5C42992dECbae36851359345FE25997F5C42d",
  OptimismMintableERC20Factory: "0xFaD0b5a44445575Ff338b9eDFF00B713D2Bd2c88",
  OptimismMintableERC20FactoryProxy: "0x84eA74d481Ee0A5332c457a4d796187F6Ba67fEB",
  OptimismPortal: "0xb56E0aC6E2ed5Bf47fA286D8b6eac42aF38Ba996",
  OptimismPortalProxy: "0x09635F643e140090A9A8Dcd712eD6285858ceBef",
  ProtocolVersions: "0x70831EB4E9203A9Bd3E0BF4cc19784B51B4D8554",
  ProtocolVersionsProxy: "0xa85233C63b9Ee964Add6F2cffe00Fd84eb32338f",
  ProxyAdmin: "0x68B1D87F95878fE05B998F19b66F4baba5De1aed",
  SafeProxyFactory: "0x9A676e781A523b5d0C0e43731313A708CB607508",
  SafeSingleton: "0x0B306BF915C4d645ff596e518fAf3F9669b97016",
  SuperchainConfig: "0xCb6aF447D652684d09381f39d13D1e028318bbB5",
  SuperchainConfigProxy: "0x59b670e9fA9D0A427751Af201D676719a970857b",
  SystemConfig: "0x998abeb3E57409262aE5b751f60747921B33613E",
  SystemConfigProxy: "0x67d269191c92Caf3cD7723F116c85e6E9bf55933",
  SystemOwnerSafe: "0x3734C0E8b5415aD476a2c36Da99fDDE86053f75B",
};

const sourceId = 3151908;
const mainnetChain = defineChain({
  ...chainConfig,
  id: sourceId,
  name: "Fraxtal L1 devnet",
  nativeCurrency: { name: "Ethereum", symbol: "ETH", decimals: 18 },
  rpcUrls: {
    default: {
      http: ["http://127.0.0.1:36002"],
    },
  },
  contracts: {
    multicall3: {
      address: "0xca11bde05977b3631167028862be2a173976ca11",
    },
  },
});

const chain = defineChain({
  ...chainConfig,
  id: 252,
  name: "Fraxtal devnet",
  nativeCurrency: { name: "Frax", symbol: "FRAX", decimals: 18 },
  rpcUrls: {
    default: {
      http: ["http://127.0.0.1:40000"],
    },
  },
  contracts: {
    ...chainConfig.contracts,
    l2OutputOracle: {
      [sourceId]: {
        address: l1Contracts.L2OutputOracleProxy as Address,
      },
    },
    portal: {
      [sourceId]: {
        address: l1Contracts.OptimismPortalProxy as Address,
      },
    },
    l1StandardBridge: {
      [sourceId]: {
        address: l1Contracts.L1StandardBridgeProxy as Address,
      },
    },
    multicall3: {
      address: "0xca11bde05977b3631167028862be2a173976ca11",
    },
  },
  sourceId,
});

const account = mnemonicToAccount("test test test test test test test test test test test junk", {
  addressIndex: 1,
});

// console.log(`Using account ${account.address}`);
const l1Client = createPublicClient({
  chain: mainnetChain,
  transport: http(),
})
  .extend(publicActionsL1())
  .extend(walletActionsL1());

const l1WalletClient = createWalletClient({
  chain: mainnetChain,
  transport: http(),
  account,
}).extend(walletActionsL1());

const l2Client = createPublicClient({
  chain,
  transport: http(),
})
  .extend(publicActionsL2())
  .extend(walletActionsL2());

(async () => {
  const __args = process.argv.slice(2);
  const _l2TxHash = __args[0];
  const _route = parseInt(__args[1]);
  const _printLogs = parseInt(__args[2]); // leave off for ffi calls
  if (_printLogs) console.log(__args);

  const l2Receipt = await getTransactionReceipt(l2Client, {
    hash: _l2TxHash,
  });

  // console.log("0x12b0bfb1e79b1c6b1d423bfefd3f4559ba7f7cc2b949292f09bf6802947fe7c9");
  // return;

  // PROVE WITHDRAWAL
  // ================================
  if (_route == 0) {
    if (_printLogs) console.log("========= PROVE WITHDRAWAL =========");
    const [withdrawal] = getWithdrawals(l2Receipt);
    const output = await l1Client.getL2Output({
      l2BlockNumber: l2Receipt.blockNumber,
      targetChain: l2Client.chain,
    });
    const args = await l2Client.buildProveWithdrawal({
      account,
      output,
      withdrawal,
    });

    const hash = await l1WalletClient.proveWithdrawal(args);
    if (_printLogs) console.log("Prove tx hash", hash);
    console.log(hash);
  } else if (_route == 1) {
    // FINALIZE WITHDRAWAL
    // ================================
    if (_printLogs) console.log("========= FINALIZE WITHDRAWAL =========");
    const [withdrawal] = getWithdrawals(l2Receipt);
    const hash = await l1WalletClient.finalizeWithdrawal({
      account,
      targetChain: l2Client.chain,
      withdrawal,
    });
    if (_printLogs) console.log("Finalize tx hash", hash);
    console.log(hash);
    // return hash;
  }
})();
