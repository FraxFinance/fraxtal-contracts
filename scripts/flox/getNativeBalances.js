const fs = require("fs");
const ethers = require("ethers");
const { rpcUrl, nativeBalanceCheckerAddress, epochBlockDuration } = require("./utils/floxConstants");
const path = require("path");

async function getNativeBalances(startingBlockNumber) {
  try {
    // Read user data from the JSON file
    const dataFilePath = path.join(__dirname, `allocations/traces_${startingBlockNumber}.json`);
    const data = JSON.parse(fs.readFileSync(dataFilePath, "utf-8"));

    // Connect to the Ethereum provider
    const provider = new ethers.providers.JsonRpcProvider(rpcUrl);

    // Load the BalanceChecker contract
    const balanceCheckerAbiFilePath = path.join(__dirname, "abis/NativeBalanceChecker.json");
    const balanceCheckerAbi = fs.readFileSync(balanceCheckerAbiFilePath, "utf-8");
    const balanceCheckerContract = new ethers.Contract(nativeBalanceCheckerAddress, balanceCheckerAbi, provider);

    var randomBlockNumber = Math.floor(Math.random() * (epochBlockDuration - 1)) + startingBlockNumber;
    if (randomBlockNumber < 288931) randomBlockNumber = 288931;

    const userBalances = {};
    const contractBalances = {};
    const tokenSymbol = "frxETH";

    // Batch processing: Process 25 users at a time
    const batchSize = 25;
    const userAddresses = Object.keys(data.users);
    const contractAddresses = Object.keys(data.contracts);

    for (let i = 0; i < userAddresses.length; i += batchSize) {
      const batchUserAddresses = userAddresses.slice(i, i + batchSize);

      let tokenBalances = [];

      try {
        tokenBalances = await balanceCheckerContract.tokenBalances(ethers.constants.AddressZero, batchUserAddresses, {
          blockTag: randomBlockNumber,
        });
      } catch (error) {
        console.log("Error fetching token user balances:", error);
      }

      for (let j = 0; j < batchUserAddresses.length; j++) {
        const userAddress = batchUserAddresses[j];
        if (tokenBalances && tokenBalances[j] !== undefined && tokenBalances[j]._hex != "0x00") {
          userBalances[userAddress] = tokenBalances[j];
        }
      }
    }

    for (let i = 0; i < contractAddresses.length; i += batchSize) {
      const batchContractAddresses = contractAddresses.slice(i, i + batchSize);

      let tokenBalances = [];

      try {
        tokenBalances = await balanceCheckerContract.tokenBalances(
          ethers.constants.AddressZero,
          batchContractAddresses,
          {
            blockTag: randomBlockNumber,
          },
        );
      } catch (error) {
        console.log("Error fetching token contract balances:", error);
      }

      for (let j = 0; j < batchContractAddresses.length; j++) {
        const userAddress = batchContractAddresses[j];
        if (tokenBalances && tokenBalances[j] !== undefined && tokenBalances[j]._hex != "0x00") {
          contractBalances[userAddress] = tokenBalances[j];
        }
      }
    }

    let retrievedUserBalances = {};
    retrievedUserBalances.userBalances = userBalances;
    retrievedUserBalances.blockNumber = randomBlockNumber;
    let retrievedContractBalances = {};
    retrievedContractBalances.contractBalances = contractBalances;
    retrievedContractBalances.blockNumber = randomBlockNumber;

    // Write userBalances to token-specific JSON files
    console.log("userBalances", userBalances);
    console.log("contractBalances", contractBalances);
    writeBalancesToFile(retrievedUserBalances, retrievedContractBalances, tokenSymbol, startingBlockNumber);

    console.log("Balances retrieval and file writing completed.");
  } catch (error) {
    console.error("Error:", error);
  }
}

function writeBalancesToFile(userBalances, contractBalances, tokenSymbol, blockStart) {
  const userFileName = `traces_tokens_users_${tokenSymbol}_${blockStart}.json`;
  const userFilePath = path.join(__dirname, `allocations/${userFileName}`);
  fs.writeFileSync(userFilePath, JSON.stringify(userBalances, null, 2));
  const contractFileName = `traces_tokens_contracts_${tokenSymbol}_${blockStart}.json`;
  const contractFilePath = path.join(__dirname, `allocations/${contractFileName}`);
  fs.writeFileSync(contractFilePath, JSON.stringify(contractBalances, null, 2));
}

// Run the script
module.exports = getNativeBalances;
