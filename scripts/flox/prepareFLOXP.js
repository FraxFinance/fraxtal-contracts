const fs = require("fs");
const path = require("path");
const retrieveGasStats = require("./retrieveGasStats");
const { rpcUrl, epochBlockDuration } = require("./utils/floxConstants");
const calculateFLOXPRank = require("./calculateFLOXPRank");
const getUserBalances = require("./getUserBalances");
const getUserDelegations = require("./getUserDelegations");
const getNativeBalances = require("./getNativeBalances");
const allocateFLOXP = require("./allocateFLOXP");

async function main() {
  try {
    // Read lastBlock from the JSON file
    const jsonFilePath = path.join(__dirname, "utils/floxUtils.json");
    const jsonData = fs.readFileSync(jsonFilePath, "utf-8");
    const data = JSON.parse(jsonData);

    // Increment lastBlock by one to get startingBlock
    const startingBlock = data.lastBlock + 1;
    const endingBlock = startingBlock + epochBlockDuration - 1;

    // Call the functions from the imported scripts
    await retrieveGasStats(startingBlock, endingBlock, rpcUrl);
    await getUserBalances(startingBlock);
    await getNativeBalances(startingBlock);
    await calculateFLOXPRank(startingBlock);

    const rankFilePath = path.join(__dirname, `allocations/traces_rank_${startingBlock}.json`);
    await getUserDelegations(startingBlock, rankFilePath);
    await allocateFLOXP(startingBlock);
  } catch (error) {
    console.error("Error:", error.message);
  }
}

main();
