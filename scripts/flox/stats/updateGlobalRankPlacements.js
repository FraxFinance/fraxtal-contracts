const { readFileSync, writeFileSync, existsSync } = require("fs");
const path = require("path");

// Function to update global rankings for users
async function updateGlobalUserRankPlacements(currentEpoch) {
  const userRankPlacementsPath = path.join(__dirname, `epoch_${currentEpoch}/userRankPlacements_${currentEpoch}.json`);

  const userRankPlacements = JSON.parse(readFileSync(userRankPlacementsPath, "utf-8"));

  const globalUserRankPlacementsPath = path.join(__dirname, "global/globalUserRankPlacements.json");
  let globalUserRankPlacements = existsSync(globalUserRankPlacementsPath)
    ? JSON.parse(readFileSync(globalUserRankPlacementsPath, "utf-8"))
    : { lastEpoch: -1 };

  if (!Array.isArray(globalUserRankPlacements)) {
    globalUserRankPlacements.users = [];
    globalUserRankPlacements.lastEpoch = -1;
  }

  if (globalUserRankPlacements.lastEpoch < currentEpoch) {
    // Update the global rankings with the per-epoch rankings
    // Assuming userRankPlacements is an array of user objects with address, rank, and placement
    for (const user of userRankPlacements) {
      const existingUser = globalUserRankPlacements.users.find((u) => u.address === user.address);
      if (existingUser) {
        existingUser.rank += user.rank;
      } else {
        globalUserRankPlacements.users.push({ ...user });
      }
    }

    globalUserRankPlacements.users = globalUserRankPlacements.users
      .sort((a, b) => a.placement - b.placement)
      .map((user, index) => ({ ...user, placement: index + 1 }));

    globalUserRankPlacements.lastEpoch = currentEpoch;
    writeFileSync(globalUserRankPlacementsPath, JSON.stringify(globalUserRankPlacements, null, 2));
  }

  console.log(`Epoch ${currentEpoch} added to the global user rankings.`);
}

// Function to update global rankings for contracts
async function updateGlobalContractRankPlacements(currentEpoch) {
  const contractRankPlacementsPath = path.join(
    __dirname,
    `epoch_${currentEpoch}/contractRankPlacements_${currentEpoch}.json`,
  );

  const contractRankPlacements = JSON.parse(readFileSync(contractRankPlacementsPath, "utf-8"));

  const globalContractRankPlacementsPath = path.join(__dirname, "global/globalContractRankPlacements.json");
  let globalContractRankPlacements = existsSync(globalContractRankPlacementsPath)
    ? JSON.parse(readFileSync(globalContractRankPlacementsPath, "utf-8"))
    : { lastEpoch: -1 };

  if (!Array.isArray(globalContractRankPlacements)) {
    globalContractRankPlacements.contracts = [];
    globalContractRankPlacements.lastEpoch = -1;
  }

  if (globalContractRankPlacements.lastEpoch < currentEpoch) {
    // Update the global rankings with the per-epoch rankings
    // Assuming contractRankPlacements is an array of contract objects with address, rank, and placement
    for (const contract of contractRankPlacements) {
      const existingContract = globalContractRankPlacements.contracts.find((c) => c.address === contract.address);
      if (existingContract) {
        existingContract.rank += contract.rank;
      } else {
        globalContractRankPlacements.contracts.push({ ...contract });
      }
    }

    globalContractRankPlacements.contracts = globalContractRankPlacements.contracts
      .sort((a, b) => a.placement - b.placement)
      .map((contract, index) => ({ ...contract, placement: index + 1 }));

    globalContractRankPlacements.lastEpoch = currentEpoch;
    writeFileSync(globalContractRankPlacementsPath, JSON.stringify(globalContractRankPlacements, null, 2));
  }

  console.log(`Epoch ${currentEpoch} added to the global contract rankings.`);
}

async function updateGlobalRankPlacements(currentEpoch) {
  await updateGlobalUserRankPlacements(currentEpoch);
  await updateGlobalContractRankPlacements(currentEpoch);
}

module.exports = updateGlobalRankPlacements;
