// const rpcUrl = "https://rpc.testnet.frax.com/alt"; // Testnet
const rpcUrl = "https://rpc.staging.mainnet.frax.com/frax-team"; // Mainnet

const epochBlockDuration = 302400; // One week assuming 2s block time

const hourBlockDuration = 1800; // 1 hour assuming 2s block time

const totalEpochUserIncentives = 10 * 10 ** 18;

const totalEpochContractIncentives = 5 * 10 ** 18;

const minimumAllocationIncentive = 0.1 * 10 ** 18;

const minLockDuration = 86400 * 365 * 3.5; // 3.5 years

const userFxtlPointsMultiplierBpt = 1_000_000_000; // 1e9 == rank * 1 points

const contractFxtlPointsMultiplierBpt = 500_000_000; // 1e9 == rank * 1 points

const fxtlPointsBptBase = 1_000_000_000;

const veFXSUtilsAddress = "0x7c7b4eA76002Db99BE42B5d6e565A2E37e266E64";

const floxIncentivesDistributorAddress = "0x8EBE305CE2C72E5D8b9191258aa8a22A3d242a45";

// const fxtlPoints = "0x2d895a0d5ec661028edeea8beef0dee09cb1b11f"; // Testnet
const fxtlPoints = "0x7f444B035E55C2956653f69F0366A7045a9bE846"; // Mainnet

// const delegationRegistryAddress = "0x7267152C923789712f4518bC2A84b902D6a65A2C"; // Testnet
const delegationRegistryAddress = "0xF5cA906f05cafa944c27c6881bed3DFd3a785b6A"; // Mainnet

// const balanceCheckerAddress = "0x99d9d9cA1469dB75Ef55f1EF42c07f4f012bE674"; // Testnet
//const balanceCheckerAddress = "0xFb43334dd0f498095882109406Dd0433Ea955BcB"; // Mainnet old
const balanceCheckerAddress = "0x219356ef2f11a314Dd0D8bfd7f4B0B951Cb16c3a"; // Mainnet

const nativeBalanceCheckerAddress = "0x219356ef2f11a314Dd0D8bfd7f4B0B951Cb16c3a"; // Mainnet

const excludedAddresses = [
  "0x4200000000000000000000000000000000000007",
  "0x4200000000000000000000000000000000000010",
  "0x4200000000000000000000000000000000000016",
];

// The boosted addresses are mapped to basis point reprexsentation of the boost
// The boost is applied to the fee spent on the contract using the following equation:
// boostedFee = feeSpentOnContract * (1 + boostBasisPoints / 10000)
// This means that boosted fee is 1% higher for 100 basis points or feeSpentOnContract * 1.01
const boostedAddresses = {
  "0x8ebe305ce2c72e5d8b9191258aa8a22a3d242a45": 25,
};

const weightedContractAddresses = [
  "0x7F5c764cBc14f9669B88837ca1490cCa17c31607",
  "0x4200000000000000000000000000000000000006",
  "0xd12836c37f8f83cb0374C75fb84a8E0497331470",
  "0x2d9799cd34FA193012F648ff027E32Df27a77Ab5",
];

const tokenWeightConsts = {
  "0x7F5c764cBc14f9669B88837ca1490cCa17c31607": 6.38e5, // USDC
  "0x4200000000000000000000000000000000000006": 1.0e-3, // WETH
  "0xd12836c37f8f83cb0374C75fb84a8E0497331470": 6.38e-7, //tFRAX
  "0x2d9799cd34FA193012F648ff027E32Df27a77Ab5": 1.0e-3, // Mock FXS
};

// const tokensToCheckForBalance = { // Testnet
//   "0xd12836c37f8f83cb0374C75fb84a8E0497331470": "tFRAX", //tFRAX
//   "0x2d9799cd34FA193012F648ff027E32Df27a77Ab5": "mFXS", // Mock FXS
// };

const tokensToCheckForBalance = {
  // Mainnet
  "0xfc00000000000000000000000000000000000006": "wfrxETH", // wfrxETH
  "0xfc00000000000000000000000000000000000005": "sfrxETH", // sfrxETH
  "0xfc00000000000000000000000000000000000002": "FXS", // FXS
  "0xfc00000000000000000000000000000000000001": "FRAX", // FRAX
  "0xfc00000000000000000000000000000000000008": "sFRAX", // sFRAX
  "0xfc00000000000000000000000000000000000007": "frxBTC", // frxBTC
  "0xfc00000000000000000000000000000000000003": "FPI", // FPI
  "0xfc00000000000000000000000000000000000004": "FPIS", // FPIS
};

const fxtlBoostMultiplier = 6.38e5;

module.exports = {
  rpcUrl,
  epochBlockDuration,
  hourBlockDuration,
  totalEpochUserIncentives,
  totalEpochContractIncentives,
  minLockDuration,
  veFXSUtilsAddress,
  floxIncentivesDistributorAddress,
  excludedAddresses,
  boostedAddresses,
  minimumAllocationIncentive,
  weightedContractAddresses,
  tokenWeightConsts,
  fxtlPoints,
  tokensToCheckForBalance,
  balanceCheckerAddress,
  nativeBalanceCheckerAddress,
  delegationRegistryAddress,
  userFxtlPointsMultiplierBpt,
  contractFxtlPointsMultiplierBpt,
  fxtlPointsBptBase,
  fxtlBoostMultiplier,
};
