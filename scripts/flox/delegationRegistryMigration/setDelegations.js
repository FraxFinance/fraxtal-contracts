const { ethers } = require("ethers");
const delegationRegistryAbi = require("../abis/DelegationRegistry.json");
const { rpcUrl } = require("../utils/floxConstants");
const delegations = require("./data/delegations.json");
const dotenv = require("dotenv");

dotenv.config();

// Function to set delegations
async function setDelegations() {
  try {
    const provider = new ethers.providers.JsonRpcProvider(rpcUrl);
    const privateKey = process.env.PK;
    const wallet = new ethers.Wallet(privateKey, provider);

    const delegationRegistryAddress = "0x098c837FeF2e146e96ceAF58A10F68Fc6326DC4C";
    const delegationRegistry = new ethers.Contract(delegationRegistryAddress, delegationRegistryAbi, wallet);

    const delegators = [];
    const delegatees = [];

    for (const delegator in delegations) {
      for (const delegatee of delegations[delegator]) {
        delegators.push(delegator);
        delegatees.push(delegatee);
      }
    }

    // Set delegations
    const tx = await delegationRegistry.bulkSetDelegationsAsFraxContributor(delegators, delegatees, {
      gasLimit: 29000000,
    });
    console.log("Transaction hash:", tx.hash);
  } catch (error) {
    console.error("Error setting delegations:", error);
  }
}

module.exports = setDelegations;
