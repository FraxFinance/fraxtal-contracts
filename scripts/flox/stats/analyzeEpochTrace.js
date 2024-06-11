const fs = require("fs");
const path = require("path");
const { epochBlockDuration } = require("../utils/floxConstants");
const getTopSpenders = require("./getTopSpenders");
const updateGlobalSpenderRankings = require("./updateGlobalSpenderRankings");
const getHighestEpochRank = require("./getHighestEpochRank");
const updateGlobalRankPlacements = require("./updateGlobalRankPlacements");

async function main() {
  try {
    const jsonFilePath = path.join(__dirname, "utils/statsUtils.json");
    const jsonData = fs.readFileSync(jsonFilePath, "utf-8");
    const data = JSON.parse(jsonData);

    const currentEpoch = data.currentEpoch;
    const epochStartingBlock = currentEpoch * epochBlockDuration;

    await getTopSpenders(currentEpoch, epochStartingBlock);
    await updateGlobalSpenderRankings(currentEpoch);
    await getHighestEpochRank(currentEpoch, epochStartingBlock);
    await updateGlobalRankPlacements(currentEpoch);
  } catch (error) {
    console.error("Error:", error.message);
  }
}

main();
