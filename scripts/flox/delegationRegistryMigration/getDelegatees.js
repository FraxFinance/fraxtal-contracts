const { ethers } = require("ethers");
const fs = require("fs");
const delegationRegistryAbi = require("../abis/DelegationRegistry.json");
const { rpcUrl } = require("../utils/floxConstants");
const delegators = require("./data/delegators.json");
const path = require("path");

// Function to retrieve delegatees of delegators
async function getDelegatees() {
  try {
    const provider = new ethers.providers.JsonRpcProvider(rpcUrl);
    const contractAddress = "0xF5cA906f05cafa944c27c6881bed3DFd3a785b6A";
    const contract = new ethers.Contract(contractAddress, delegationRegistryAbi, provider);
    // Call the smart contract function to get delegatees of delegators
    const delegatees = await contract.bulkDelegationsOf(delegators);

    // Map delegators to delegatees
    const delegations = {};
    for (let i = 0; i < delegators.length; i++) {
      const delegator = delegators[i];
      const delegatee = delegatees[i];

      if (!(delegator in delegations)) {
        delegations[delegator] = [];
      }
      delegations[delegator].push(delegatee);
    }

    // Write delegations to a JSON file
    const delegationsFilePath = path.join(__dirname, "data/delegations.json");
    fs.writeFileSync(delegationsFilePath, JSON.stringify(delegations, null, 2));

    console.log("Delegations stored successfully.");
  } catch (error) {
    console.error("Error retrieving and storing delegations:", error);
  }
}

module.exports = getDelegatees;
