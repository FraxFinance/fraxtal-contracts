const fs = require("fs");
const ethers = require("ethers");
const { rpcUrl, tokensToCheckForBalance, balanceCheckerAddress, epochBlockDuration } = require("./utils/floxConstants");
const path = require("path");

async function getUserBalances(startingBlockNumber) {
  try {
    // Read lastBlock from the JSON file
    const jsonFilePath = path.join(__dirname, "utils/floxUtils.json");
    const jsonData = fs.readFileSync(jsonFilePath, "utf-8");
    const data = JSON.parse(jsonData);

    // Read user data from the JSON file
    const userDataFilePath = path.join(__dirname, `allocations/traces_${startingBlockNumber}.json`);
    const userData = JSON.parse(fs.readFileSync(userDataFilePath, "utf-8"));

    // Connect to the Ethereum provider
    const provider = new ethers.providers.JsonRpcProvider(rpcUrl);

    // Load the BalanceChecker contract
    const balanceCheckerAbiFilePath = path.join(__dirname, "abis/BalanceChecker.json");
    const balanceCheckerAbi = fs.readFileSync(balanceCheckerAbiFilePath, "utf-8");
    const balanceCheckerContract = new ethers.Contract(balanceCheckerAddress, balanceCheckerAbi, provider);

    var randomBlockNumber = Math.floor(Math.random() * (epochBlockDuration - 1)) + startingBlockNumber;
    if (randomBlockNumber < 288931) randomBlockNumber = 288931;

    // Process each token contract individually
    for (const [tokenAddress, tokenSymbol] of Object.entries(tokensToCheckForBalance)) {
      const balances = {};

      // Batch processing: Process 25 users at a time
      const batchSize = 25;
      const userAddresses = Object.keys(userData.users);

      for (let i = 0; i < userAddresses.length; i += batchSize) {
        const batchUserAddresses = userAddresses.slice(i, i + batchSize);

        let tokenBalances = [];

        try {
          tokenBalances = await balanceCheckerContract.tokenBalances(tokenAddress, batchUserAddresses, {
            blockTag: randomBlockNumber,
          });
        } catch (error) {
          console.log("Error fetching token balances:", error);
        }

        for (let j = 0; j < batchUserAddresses.length; j++) {
          const userAddress = batchUserAddresses[j];
          if (tokenBalances && tokenBalances[j] !== undefined && tokenBalances[j]._hex != "0x00") {
            balances[userAddress] = tokenBalances[j];
          }
        }
      }

      let retrievedBalances = {};
      retrievedBalances.balances = balances;
      retrievedBalances.blockNumber = randomBlockNumber;

      // Write balances to token-specific JSON files
      writeBalancesToFile(retrievedBalances, tokenSymbol, startingBlockNumber);
    }

    console.log("Balances retrieval and file writing completed.");
  } catch (error) {
    console.error("Error:", error);
  }
}

function writeBalancesToFile(balances, tokenSymbol, blockStart) {
  const fileName = `traces_tokens_${tokenSymbol}_${blockStart}.json`;
  const filePath = path.join(__dirname, `allocations/${fileName}`);
  fs.writeFileSync(filePath, JSON.stringify(balances, null, 2));
}

// Run the script
module.exports = getUserBalances;
