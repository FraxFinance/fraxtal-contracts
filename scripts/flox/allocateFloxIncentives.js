require("dotenv").config();

const fs = require("fs");
const ethers = require("ethers");
const distributor = require("../../out/FloxIncentivesDistributor.sol/FloxIncentivesDistributor.json");
const { rpcUrl, floxIncentivesDistributorAddress } = require("./utils/floxConstants");
const path = require("path");

// Read lastStartBlock from the JSON file
const jsonFilePath = path.join(__dirname, "utils/floxUtils.json");
const jsonData = fs.readFileSync(jsonFilePath, "utf-8");
const utilsData = JSON.parse(jsonData);

// Load the JSON file
const filePath = path.join(__dirname, `allocations/incentives_${utilsData.previousStartingBlock}.json`);
const jsonContent = fs.readFileSync(filePath, "utf8");
const incentivesData = JSON.parse(jsonContent);

// Ethereum provider and contract initialization
const provider = new ethers.providers.JsonRpcProvider(rpcUrl);
const privateKey = process.env.PK;
const wallet = new ethers.Wallet(privateKey, provider);
const contractAddress = floxIncentivesDistributorAddress;
const contractABI = distributor.abi;

const contract = new ethers.Contract(contractAddress, contractABI, wallet);

// Function to batch array into groups
function batchArray(array, batchSize) {
  const batches = [];
  for (let i = 0; i < array.length; i += batchSize) {
    batches.push(array.slice(i, i + batchSize));
  }
  return batches;
}

// Function to allocate incentives to existing locks
async function allocateToExistingLocks(allocateExisting) {
  const batches = batchArray(allocateExisting, 25);

  for (const batch of batches) {
    const incentivesInput = batch.map((item) => ({
      recipient: item.recipient,
      lockIndex: item.lockIndex,
      amount: ethers.BigNumber.from(item.amount.toString()),
    }));

    const tx = await contract.allocateIncentivesToExistingLocks(incentivesInput, { gasLimit: 15000000 });
    await tx.wait();
  }
}

// Function to allocate incentives to new locks
async function allocateToNewLocks(allocateNew) {
  const batches = batchArray(allocateNew, 25);

  for (const batch of batches) {
    const incentivesInput = batch.map((item) => ({
      recipient: item.recipient,
      lockIndex: item.lockIndex,
      amount: ethers.BigNumber.from(item.amount.toString()),
    }));

    const tx = await contract.allocateIncentivesToNewLocks(incentivesInput, { gasLimit: 15000000 });
    await tx.wait();
  }
}

// Function to provide epoch stats
async function provideEpochStats() {
  const { blockStart, blockLastBlock, traceProof } = incentivesData;

  const tx = await contract.provideEpochStats(blockStart, blockLastBlock, traceProof, { gasLimit: 150000 });
  await tx.wait();
}

// Main function to execute the script
async function main() {
  try {
    const { allocateExisting, allocateNew } = incentivesData;

    // Allocate incentives to existing locks
    await allocateToExistingLocks(allocateExisting);

    // Allocate incentives to new locks
    await allocateToNewLocks(allocateNew);

    // Provide epoch stats
    await provideEpochStats();

    console.log("Incentives allocated and epoch stats provided successfully.");
  } catch (error) {
    console.error("Error:", error);
  }
}

// Run the script
main();
