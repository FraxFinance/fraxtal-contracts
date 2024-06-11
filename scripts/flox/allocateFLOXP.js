require("dotenv").config();

const fs = require("fs");
const ethers = require("ethers");
const points = require("../../out/FxtlPoints.sol/FxtlPoints.json");
const {
  rpcUrl,
  fxtlPoints,
  userFxtlPointsMultiplierBpt,
  contractFxtlPointsMultiplierBpt,
  fxtlPointsBptBase,
} = require("./utils/floxConstants");
const path = require("path");

// Ethereum provider and contract initialization
const provider = new ethers.providers.JsonRpcProvider(rpcUrl);
const privateKey = process.env.PK;
const wallet = new ethers.Wallet(privateKey, provider);
const contractAddress = fxtlPoints;
const contractABI = points.abi;

const contract = new ethers.Contract(contractAddress, contractABI, wallet);

// Function to compact point allocations to delegatees
function compactPoints(addresses, amounts, startingBlock) {
  const delegateeSums = {};

  const delegationsFilePath = path.join(__dirname, `allocations/traces_delegations_${startingBlock}.json`);
  const delegations = JSON.parse(fs.readFileSync(delegationsFilePath, "utf-8"));

  for (let i = 0; i < addresses.length; i++) {
    const address = addresses[i];
    const amount = amounts[i];
    const delegatee = delegations[address];

    if (delegateeSums[delegatee]) {
      delegateeSums[delegatee] += amount;
    } else {
      delegateeSums[delegatee] = amount;
    }
  }

  return delegateeSums;
}

// Function to batch array into groups
function batchArray(array, batchSize) {
  const entries = Object.entries(array);
  const batches = [];
  for (let i = 0; i < entries.length; i += batchSize) {
    const batch = entries.slice(i, i + batchSize);
    const batchObject = Object.fromEntries(batch);
    batches.push(batchObject);
  }
  return batches;
}

async function allocatePoints(allocations) {
  const batchSize = 25;
  const batches = batchArray(allocations, batchSize);

  for (const batch of batches) {
    const tx = await contract.bulkAddFxtlPoints(Object.keys(batch), Object.values(batch), { gasLimit: 15000000 });
    await tx.wait();
  }
}

// Main function to execute the script
async function allocateFLOXP(startBlockNumber) {
  try {
    // Load the JSON file
    const filePath = path.join(__dirname, `allocations/traces_rank_${startBlockNumber}.json`);
    const jsonContent = fs.readFileSync(filePath, "utf8");
    const pointsData = JSON.parse(jsonContent);

    const users = pointsData.users;
    const contracts = pointsData.contracts;
    const addresses = [...Object.keys(users), ...Object.keys(contracts)];

    let userAmounts = [...Object.values(users)];
    let contractAmounts = [...Object.values(contracts)];

    for (let i = 0; i < userAmounts.length; i++) {
      userAmounts[i] = (userAmounts[i] * userFxtlPointsMultiplierBpt) / fxtlPointsBptBase;
    }
    for (let i = 0; i < contractAmounts.length; i++) {
      contractAmounts[i] = (contractAmounts[i] * contractFxtlPointsMultiplierBpt) / fxtlPointsBptBase;
    }
    let amounts = userAmounts.concat(contractAmounts);

    for (let i = 0; i < amounts.length; i++) {
      amounts[i] = ethers.utils.parseUnits(amounts[i].toString());
    }

    const delegatedAllocations = compactPoints(addresses, amounts, startBlockNumber);
    await allocatePoints(delegatedAllocations);

    console.log("Points allocated successfully.");
  } catch (error) {
    console.error("Error:", error);
  }
}

// Run the script
module.exports = allocateFLOXP;
