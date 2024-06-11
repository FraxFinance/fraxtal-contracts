const fs = require("fs");
const path = require("path");

async function getHighestEpochRank(currentEpoch, epochStartingBlock) {
  // Read the JSON ranking file
  let rankingTracePath = path.join(__dirname, `allocations/traces_rank_${epochStartingBlock}.json`);
  rankingTracePath = rankingTracePath.replace("/stats/", "/");
  const rankingData = JSON.parse(fs.readFileSync(rankingTracePath, "utf-8"));

  // Process users
  const users = Object.entries(rankingData.users)
    .map(([address, rank]) => ({ address, rank }))
    .sort((a, b) => b.rank - a.rank)
    .map((user, index) => ({ ...user, placement: index + 1 }));

  // Process contracts
  const contracts = Object.entries(rankingData.contracts)
    .map(([address, rank]) => ({ address, rank }))
    .sort((a, b) => b.rank - a.rank)
    .map((contract, index) => ({ ...contract, placement: index + 1 }));

  // Write the processed data to the output files
  const processedUsersFilePath = path.join(__dirname, `epoch_${currentEpoch}/userRankPlacements_${currentEpoch}.json`);
  const processedContractsFilePath = path.join(
    __dirname,
    `epoch_${currentEpoch}/contractRankPlacements_${currentEpoch}.json`,
  );
  fs.writeFileSync(processedUsersFilePath, JSON.stringify(users, null, 2));
  fs.writeFileSync(processedContractsFilePath, JSON.stringify(contracts, null, 2));

  console.log("Epoch Flox rank rankings written to files.");
}

module.exports = getHighestEpochRank;
