const { readFileSync, writeFileSync, existsSync } = require("fs");
const path = require("path");

async function updateGlobalSpenderRankings(currentEpoch) {
  // Read the JSON data of per-epoch rankings
  let epochTracePath = path.join(__dirname, `epoch_${currentEpoch}`);
  const userRankingsGasPath = path.join(epochTracePath, `userRankingsGas_${currentEpoch}.json`);
  const userRankingsFeesPath = path.join(epochTracePath, `userRankingsFees_${currentEpoch}.json`);
  const contractRankingsGasPath = path.join(epochTracePath, `contractRankingsGas_${currentEpoch}.json`);
  const contractRankingsFeesPath = path.join(epochTracePath, `contractRankingsFees_${currentEpoch}.json`);

  const userRankingsGas = JSON.parse(readFileSync(userRankingsGasPath, "utf-8"));
  const userRankingsFees = JSON.parse(readFileSync(userRankingsFeesPath, "utf-8"));
  const contractRankingsGas = JSON.parse(readFileSync(contractRankingsGasPath, "utf-8"));
  const contractRankingsFees = JSON.parse(readFileSync(contractRankingsFeesPath, "utf-8"));

  // Read the existing global ranking files if they exist
  const globalUserRankingsGasPath = path.join(__dirname, "global/globalUserRankingsGas.json");
  const globalUserRankingsFeesPath = path.join(__dirname, "global/globalUserRankingsFees.json");
  const globalContractRankingsGasPath = path.join(__dirname, "global/globalContractRankingsGas.json");
  const globalContractRankingsFeesPath = path.join(__dirname, "global/globalContractRankingsFees.json");

  let globalUserRankingsGas = existsSync(globalUserRankingsGasPath)
    ? JSON.parse(readFileSync(globalUserRankingsGasPath, "utf-8"))
    : { lastEpoch: -1 };
  if (!Array.isArray(globalUserRankingsGas)) {
    globalUserRankingsGas.users = [];
    globalUserRankingsGas.lastEpoch = -1;
  }
  let globalUserRankingsFees = existsSync(globalUserRankingsFeesPath)
    ? JSON.parse(readFileSync(globalUserRankingsFeesPath, "utf-8"))
    : { lastEpoch: -1 };
  if (!Array.isArray(globalUserRankingsFees)) {
    globalUserRankingsFees.users = [];
    globalUserRankingsFees.lastEpoch = -1;
  }
  let globalContractRankingsGas = existsSync(globalContractRankingsGasPath)
    ? JSON.parse(readFileSync(globalContractRankingsGasPath, "utf-8"))
    : { lastEpoch: -1 };
  if (!Array.isArray(globalContractRankingsGas)) {
    globalContractRankingsGas.users = [];
    globalContractRankingsGas.lastEpoch = -1;
  }
  let globalContractRankingsFees = existsSync(globalContractRankingsFeesPath)
    ? JSON.parse(readFileSync(globalContractRankingsFeesPath, "utf-8"))
    : { lastEpoch: -1 };
  if (!Array.isArray(globalContractRankingsFees)) {
    globalContractRankingsFees.users = [];
    globalContractRankingsFees.lastEpoch = -1;
  }

  // Update the global rankings with the per-epoch rankings
  if (globalUserRankingsGas.lastEpoch < currentEpoch) {
    for (const user of userRankingsGas) {
      const existingUser = globalUserRankingsGas.users.find((u) => u.address === user.address);
      if (existingUser) {
        existingUser.totalGas += user.totalGas;
      } else {
        globalUserRankingsGas.users.push({ ...user });
      }
    }
    globalUserRankingsGas.users = globalUserRankingsGas.users
      .sort((a, b) => b.totalGas - a.totalGas)
      .map((user, index) => ({ ...user, rank: index + 1 }));
    globalUserRankingsGas.lastEpoch = currentEpoch;
    writeFileSync(globalUserRankingsGasPath, JSON.stringify(globalUserRankingsGas, null, 2));
  }

  if (globalUserRankingsFees.lastEpoch < currentEpoch) {
    for (const user of userRankingsFees) {
      const existingUser = globalUserRankingsFees.users.find((u) => u.address === user.address);
      if (existingUser) {
        existingUser.totalFees += user.totalFees;
      } else {
        globalUserRankingsFees.users.push({ ...user });
      }
    }
    globalUserRankingsFees.users = globalUserRankingsFees.users
      .sort((a, b) => b.totalFees - a.totalFees)
      .map((user, index) => ({ ...user, rank: index + 1 }));
    globalUserRankingsFees.lastEpoch = currentEpoch;
    writeFileSync(globalUserRankingsFeesPath, JSON.stringify(globalUserRankingsFees, null, 2));
  }

  if (globalContractRankingsGas.lastEpoch < currentEpoch) {
    for (const contract of contractRankingsGas) {
      const existingContract = globalContractRankingsGas.users.find((c) => c.address === contract.address);
      if (existingContract) {
        existingContract.totalGas += contract.totalGas;
      } else {
        globalContractRankingsGas.users.push({ ...contract });
      }
    }
    globalContractRankingsGas.users = globalContractRankingsGas.users
      .sort((a, b) => b.totalGas - a.totalGas)
      .map((contract, index) => ({ ...contract, rank: index + 1 }));
    globalContractRankingsGas.lastEpoch = currentEpoch;
    writeFileSync(globalContractRankingsGasPath, JSON.stringify(globalContractRankingsGas, null, 2));
  }

  if (globalContractRankingsFees.lastEpoch < currentEpoch) {
    for (const contract of contractRankingsFees) {
      const existingContract = globalContractRankingsFees.users.find((c) => c.address === contract.address);
      if (existingContract) {
        existingContract.totalFees += contract.totalFees;
      } else {
        globalContractRankingsFees.users.push({ ...contract });
      }
    }
    globalContractRankingsFees.users = globalContractRankingsFees.users
      .sort((a, b) => b.totalFees - a.totalFees)
      .map((contract, index) => ({ ...contract, rank: index + 1 }));
    globalContractRankingsFees.lastEpoch = currentEpoch;
    writeFileSync(globalContractRankingsFeesPath, JSON.stringify(globalContractRankingsFees, null, 2));
  }

  console.log(`Epoch ${currentEpoch} added to the global rankings.`);
}

module.exports = updateGlobalSpenderRankings;
