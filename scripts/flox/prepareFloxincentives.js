const fs = require("fs");
const path = require("path");
const retrieveGasStats = require("./retrieveGasStats");
const processTrace = require("./processTrace");
const prepareIncentivesForAllocation = require("./prepareIncentivesForAllocation");
const {
  rpcUrl,
  epochBlockDuration,
  totalEpochUserIncentives,
  totalEpochContractIncentives,
  minLockDuration,
} = require("./utils/floxConstants");

async function main() {
  try {
    // Read lastBlock from the JSON file
    const jsonFilePath = path.join(__dirname, "utils/floxUtils.json");
    const jsonData = fs.readFileSync(jsonFilePath, "utf-8");
    const data = JSON.parse(jsonData);

    // Increment lastBlock by one to get startingBlock
    const startingBlock = data.lastBlock + 1;
    const endingBlock = startingBlock + epochBlockDuration;

    // Call the functions from the imported scripts
    await retrieveGasStats(startingBlock, endingBlock, rpcUrl);
    await processTrace(startingBlock);
    await prepareIncentivesForAllocation(
      startingBlock,
      rpcUrl,
      minLockDuration,
      totalEpochUserIncentives,
      totalEpochContractIncentives,
    );

    // Update lastBlock in the JSON file
    data.previousStartingBlock = startingBlock;
    data.lastBlock = startingBlock + epochBlockDuration;
    const updatedJsonData = JSON.stringify(data, null, 2);
    fs.writeFileSync(jsonFilePath, updatedJsonData, "utf-8");
  } catch (error) {
    console.error("Error:", error.message);
  }
}

main();
