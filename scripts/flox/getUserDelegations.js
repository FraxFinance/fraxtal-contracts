const fs = require("fs");
const ethers = require("ethers");
const path = require("path");
const { rpcUrl, delegationRegistryAddress } = require("./utils/floxConstants");
const delegations = require("../../out/DelegationRegistry.sol/DelegationRegistry.json");

// Function to batch array into groups
function batchArray(array, batchSize) {
  const batches = [];
  for (let i = 0; i < array.length; i += batchSize) {
    batches.push(array.slice(i, i + batchSize));
  }
  return batches;
}

// Function to retrieve delegations for a batch of addresses
async function getDelegations(contract, batchAddresses) {
  try {
    const delegations = await contract.bulkDelegationsOf(batchAddresses);
    return delegations;
  } catch (error) {
    console.error("Error fetching delegations:", error);
    return [];
  }
}

// Main function to retrieve delegations for all addresses
async function getUserDelegations(blockStart, rankFilePath) {
  try {
    // Load the JSON file
    const jsonData = JSON.parse(fs.readFileSync(rankFilePath, "utf-8"));

    // Ethereum provider and contract initialization
    const provider = new ethers.providers.JsonRpcProvider(rpcUrl);
    const contract = new ethers.Contract(delegationRegistryAddress, delegations.abi, provider);

    const allAddresses = [...Object.keys(jsonData.users), ...Object.keys(jsonData.contracts)];
    const batches = batchArray(allAddresses, 25);
    const allDelegations = {};

    for (const batch of batches) {
      // Filter out 'oxtransfer' and 'undefined' from the batch array
      let filteredBatch = batch.filter((item) => item !== "oxtransfer");
      filteredBatch = filteredBatch.filter((item) => item !== "undefined");

      const delegations = await getDelegations(contract, filteredBatch);
      for (let i = 0; i < filteredBatch.length; i++) {
        const address = filteredBatch[i];
        const delegatee = delegations[i];
        allDelegations[address] = delegatee;
      }
    }

    // Write delegations to a JSON file
    const outputPath = path.join(__dirname, `allocations/traces_delegations_${blockStart}.json`);
    fs.writeFileSync(outputPath, JSON.stringify(allDelegations, null, 2));
    console.log(`Delegations written to ${outputPath}`);
  } catch (error) {
    console.error("Error retrieving delegations:", error);
  }
}

// Execute the main function
module.exports = getUserDelegations;
