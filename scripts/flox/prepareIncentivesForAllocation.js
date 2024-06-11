const fs = require("fs");
const ethers = require("ethers");
const path = require("path");
const utils = require("../../out/VoteEscrowedFXSUtils.sol/VoteEscrowedFXSUtils.json");
const { veFXSUtilsAddress } = require("./utils/floxConstants");

async function calculateIncentives(
  users,
  contracts,
  minimumRequiredDuration,
  userIncentive,
  contractIncentive,
  veFXSUtils,
) {
  let incentives = {
    allocateExisting: [],
    allocateNew: [],
  };

  const currentBlock = await veFXSUtils.provider.getBlock("latest");
  const currentTimestamp = currentBlock.timestamp;

  // Batch users into groups of 25
  const userBatches = batchArray(users, 25);

  for (const userBatch of userBatches) {
    const longestLocks = await getLongestLock(userBatch, veFXSUtils);

    for (const user of userBatch) {
      const longestLock = longestLocks[user.address];
      const lockDuration = longestLock.lock.end - currentTimestamp;
      const incentive = calculateIncentiveAmount(userIncentive, user.basisPoint);

      if (lockDuration >= minimumRequiredDuration) {
        const incentiveInput = {
          recipient: user.address,
          lockIndex: longestLock.lockIndex, // Correct lock index for existing lock
          amount: incentive,
        };

        incentives.allocateExisting.push(incentiveInput);
      } else {
        // No existing locks, allocate incentive to new lock
        const incentiveInput = {
          recipient: user.address,
          lockIndex: 0,
          amount: incentive,
        };

        incentives.allocateNew.push(incentiveInput);
      }
    }
  }

  // Batch contracts into groups of 25
  const contractBatches = batchArray(contracts, 25);

  for (const contractBatch of contractBatches) {
    const longestLocks = await getLongestLock(contractBatch, veFXSUtils);

    for (const contract of contractBatch) {
      const longestLock = longestLocks[contract.address];
      const lockDuration = longestLock.lock.end - currentTimestamp;
      const incentive = calculateIncentiveAmount(contractIncentive, contract.basisPoint);

      if (lockDuration >= minimumRequiredDuration) {
        const incentiveInput = {
          recipient: contract.address,
          lockIndex: longestLock.lockIndex, // Correct lock index for existing lock
          amount: incentive,
        };

        incentives.allocateExisting.push(incentiveInput);
      } else {
        // No existing locks, allocate incentive to new lock
        const incentiveInput = {
          recipient: contract.address,
          lockIndex: 0,
          amount: incentive,
        };

        incentives.allocateNew.push(incentiveInput);
      }
    }
  }
  console.log(incentives);
  return incentives;
}

async function getLongestLock(users, veFXSUtils) {
  const userAddresses = users.map((user) => user.address);
  const lockPromises = userAddresses.map((address) => veFXSUtils.bulkGetLongestLock([address]));

  const longestLocks = await Promise.all(lockPromises);

  return longestLocks.reduce((acc, locks, index) => {
    const user = users[index];
    acc[user.address] = locks[0];
    return acc;
  }, {});
}

function calculateIncentiveAmount(totalIncentive, basisPoints) {
  return (totalIncentive / 1_000_000_000) * basisPoints;
}

// Function to batch array into groups
function batchArray(object, batchSize) {
  const array = Object.values(object);
  const batches = [];
  for (let i = 0; i < array.length; i += batchSize) {
    batches.push(array.slice(i, i + batchSize));
  }
  return batches;
}

async function prepareIncentivesForAllocation(
  startingBlockNumber,
  rpcUrl,
  minLockDuration,
  userIncentive,
  contractIncentive,
) {
  const processedTraceFilePath = path.join(__dirname, `allocations/processed_${startingBlockNumber}.json`);
  const jsonContent = fs.readFileSync(processedTraceFilePath);
  const data = JSON.parse(jsonContent);

  const provider = new ethers.providers.JsonRpcProvider(rpcUrl);

  const veFXSUtils = new ethers.Contract(veFXSUtilsAddress, utils.abi, provider);

  const minimumRequiredDuration = parseInt(minLockDuration);

  const incentives = await calculateIncentives(
    data.users,
    data.contracts,
    minimumRequiredDuration,
    userIncentive,
    contractIncentive,
    veFXSUtils,
  );

  const outputJson = {
    allocateExisting: incentives.allocateExisting,
    allocateNew: incentives.allocateNew,
    blockStart: data.blockStart, // Preserve blockStart
    blockLastBlock: data.blockLastBlock, // Preserve blockLastBlock
    traceProof: data.traceProof, // Preserve traceProof
  };

  const outputFileName = `incentives_${data.blockStart}.json`;
  const outputFilePath = path.join(__dirname, `allocations/${outputFileName}`);

  const outputJsonString = JSON.stringify(outputJson, null, 2);
  fs.writeFileSync(outputFilePath, outputJsonString, "utf-8");

  console.log("Incentives JSON file has been generated:", outputFileName);
}

module.exports = prepareIncentivesForAllocation;
