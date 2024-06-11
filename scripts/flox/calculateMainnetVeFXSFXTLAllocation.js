const fs = require("fs");
const path = require("path");

const pointsToAllocate = 1e10; // 10 billion points

async function calculateMainnetVeFXSFXTLAllocation() {
  // Read the JSON file
  const balancesFilePath = path.join(__dirname, "mainnetVeFXS/balances.json");
  const balancesData = fs.readFileSync(balancesFilePath, "utf8");
  const balances = JSON.parse(balancesData);

  // Calculate total balance
  let totalBalance = 0;
  for (const address in balances) {
    totalBalance += parseInt(balances[address].hex, 16);
  }

  console.log("Total unexpired balance:", totalBalance / 1e18, "veFXS");

  // Calculate percentage and points for each address
  const results = {};
  for (const address in balances) {
    const balanceHex = balances[address].hex;
    const balance = parseInt(balanceHex, 16);
    const percentage = (balance / totalBalance) * 100;
    const points = Math.round((percentage / 100) * pointsToAllocate); // Allocate the percentage of 1 billion points

    // Save results for each address
    results[address] = {
      balance: balance,
      percentage: percentage.toFixed(9), // Set decimal accuracy to one billionth
      points: points,
    };
  }

  let totalPointsAllocated = 0;
  for (const address in results) {
    totalPointsAllocated += results[address].points;
  }
  console.log("Total FXTL points allocated:", totalPointsAllocated);
  console.log("Percentage of FXTL points allocated:", (totalPointsAllocated / pointsToAllocate) * 100, "%");
  console.log(
    "Difference between total points and points to allocate:",
    pointsToAllocate - totalPointsAllocated,
    "FXTL points",
  );

  // Write results to a new JSON file
  const resultsFilePath = path.join(__dirname, "mainnetVeFXS/pointsToAllocate.json");
  fs.writeFileSync(resultsFilePath, JSON.stringify(results, null, 2));

  console.log(`Allocation results written to ${resultsFilePath}`);
}

module.exports = calculateMainnetVeFXSFXTLAllocation;
