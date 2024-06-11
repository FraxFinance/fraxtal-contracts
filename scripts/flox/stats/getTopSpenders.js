const { readFileSync, mkdirSync, writeFileSync } = require("fs");
const path = require("path");

async function getTopSpenders(currentEpoch, epochStartingBlock) {
  // Read the JSON data
  let epochTracePath = path.join(__dirname, `allocations/traces_${epochStartingBlock}.json`);
  epochTracePath = epochTracePath.replace("/stats/", "/");
  const rawData = readFileSync(epochTracePath, "utf-8");
  const data = JSON.parse(rawData);

  mkdirSync(path.join(__dirname, `epoch_${currentEpoch}`), { recursive: true });

  // Function to sort objects by value
  const sortByValue = (obj) => {
    const sortedEntries = Object.entries(obj).sort((a, b) => b[1] - a[1]);
    return sortedEntries;
  };

  // Rankings for users based on total gas and total fees spent
  const userRankingsGas = sortByValue(data.users).map(([address, info], index) => ({
    address,
    totalGas: info.totalGas,
    rank: index + 1,
  }));
  const userRankingsFees = sortByValue(data.users).map(([address, info], index) => ({
    address,
    totalFees: info.totalFee,
    rank: index + 1,
  }));

  // Rankings for contracts based on total gas and total fees spent
  const contractRankingsGas = sortByValue(data.contracts).map(([address, info], index) => ({
    address,
    totalGas: info.totalGas,
    rank: index + 1,
  }));
  const contractRankingsFees = sortByValue(data.contracts).map(([address, info], index) => ({
    address,
    totalFees: info.totalFee,
    rank: index + 1,
  }));

  // Prepare filepaths for the rankings
  const userRankingsGasPath = path.join(__dirname, `epoch_${currentEpoch}/userRankingsGas_${currentEpoch}.json`);
  const userRankingsFeesPath = path.join(__dirname, `epoch_${currentEpoch}/userRankingsFees_${currentEpoch}.json`);
  const contractRankingsGasPath = path.join(
    __dirname,
    `epoch_${currentEpoch}/contractRankingsGas_${currentEpoch}.json`,
  );
  const contractRankingsFeesPath = path.join(
    __dirname,
    `epoch_${currentEpoch}/contractRankingsFees_${currentEpoch}.json`,
  );

  // Write rankings to files
  writeFileSync(userRankingsGasPath, JSON.stringify(userRankingsGas, null, 2));
  writeFileSync(userRankingsFeesPath, JSON.stringify(userRankingsFees, null, 2));
  writeFileSync(contractRankingsGasPath, JSON.stringify(contractRankingsGas, null, 2));
  writeFileSync(contractRankingsFeesPath, JSON.stringify(contractRankingsFees, null, 2));

  console.log("Rankings generated and written to files.");
}

module.exports = getTopSpenders;
