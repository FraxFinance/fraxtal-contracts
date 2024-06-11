const fs = require("fs");
const path = require("path");
const crypto = require("crypto");
const {
  excludedAddresses,
  boostedAddresses,
  minimumAllocationIncentive,
  totalEpochUserIncentives,
  totalEpochContractIncentives,
} = require("./utils/floxConstants");

function calculateBasisPoint(totalFee, cumulativeTotalFee) {
  return Math.round((totalFee / cumulativeTotalFee) * 1_000_000_000); // 1_000_000_000 == 100% && 1 == 0.0000001%
}

function processUsers(users) {
  const userResults = [];
  const includedFees = new Map();
  var totalUserIncludedFee = 0;
  var totalUserExcludedFee = 0;

  for (const [userAddress, userData] of Object.entries(users)) {
    const excludedFees = Object.keys(userData.contracts)
      .filter((contractAddress) => excludedAddresses.includes(contractAddress))
      .reduce((sum, contractAddress) => sum + userData.contracts[contractAddress].totalFee, 0);

    const boostedIncludedFees = Object.keys(userData.contracts)
      .filter((contractAddress) => boostedAddresses[contractAddress])
      .reduce((sum, contractAddress) => {
        const boostFactor = boostedAddresses[contractAddress] || 0;
        return sum + (userData.contracts[contractAddress].totalFee * boostFactor) / 10000;
      }, 0);

    includedFees.set(userAddress, userData.totalFee - excludedFees + boostedIncludedFees);

    totalUserIncludedFee += userData.totalFee - excludedFees + boostedIncludedFees;
    totalUserExcludedFee += excludedFees;
  }

  for (const [address] of Object.entries(users)) {
    const basisPoint = calculateBasisPoint(includedFees.get(address), totalUserIncludedFee);

    userResults.push({ address, basisPoint });
  }

  return userResults;
}

function processContracts(contracts) {
  const includedContractResults = [];
  const excludedContractResults = [];
  let nonExcludedContractGasFee = 0;

  for (const [address, contractData] of Object.entries(contracts)) {
    if (!excludedAddresses.includes(address)) {
      nonExcludedContractGasFee += contractData.totalFee;
    }
  }

  for (const [address, contractData] of Object.entries(contracts)) {
    const contractGasFee = contractData.totalFee;

    if (excludedAddresses.includes(address)) {
      excludedContractResults.push({ address, basisPoint: 0 });
    } else {
      const basisPoint = calculateBasisPoint(contractGasFee, nonExcludedContractGasFee);

      let incentiveAboveThreshold;
      const contractIncentive = (totalEpochContractIncentives * basisPoint) / 1_000_000_000;
      if (contractIncentive >= minimumAllocationIncentive) {
        incentiveAboveThreshold = true;
      } else {
        incentiveAboveThreshold = false;
      }

      if (incentiveAboveThreshold) {
        includedContractResults.push({ address, basisPoint });
      } else {
        excludedContractResults.push({ address, basisPoint });
      }
    }
  }

  return { includedContractResults, excludedContractResults };
}

function generateOutputJSON(users, contracts, blockStart, blockLastBlock, originalFileContent) {
  let totalUserGasFee = 0;
  let totalContractGasFee = 0;

  // Calculate cumulative totalFee for users and contracts
  for (const [, userData] of Object.entries(users)) {
    totalUserGasFee += userData.totalFee;
  }

  for (const [, contractData] of Object.entries(contracts)) {
    totalContractGasFee += contractData.totalFee;
  }

  const userResults = processUsers(users);
  const contractResults = processContracts(contracts);
  const totalGas = totalUserGasFee + totalContractGasFee;

  const traceProof = `0x${crypto.createHash("sha256").update(originalFileContent).digest("hex")}`;

  const userResultsWithFees = [];
  const usersWithZeroIncludedFees = [];

  userResults.forEach((user) => {
    const userAddress = user.address;
    const userData = users[userAddress];
    const excludedFees = Object.keys(userData.contracts)
      .filter((contractAddress) => excludedAddresses.includes(contractAddress))
      .reduce((sum, contractAddress) => sum + userData.contracts[contractAddress].totalFee, 0);

    const includedFees = userData.totalFee - excludedFees;

    const userWithFees = {
      ...user,
      excludedFee: excludedFees,
      includedFee: includedFees,
    };

    let incentiveAboveThreshold;
    const userIncentive = (totalEpochUserIncentives * user.basisPoint) / 1_000_000_000;
    if (userIncentive >= minimumAllocationIncentive) {
      incentiveAboveThreshold = true;
    } else {
      incentiveAboveThreshold = false;
    }

    if (includedFees !== 0 && incentiveAboveThreshold) {
      userResultsWithFees.push(userWithFees);
    } else {
      usersWithZeroIncludedFees.push(userWithFees);
    }
  });

  const outputJSON = {
    users: userResultsWithFees,
    excludedUsers: usersWithZeroIncludedFees,
    contracts: contractResults.includedContractResults,
    excludedContracts: contractResults.excludedContractResults,
    totalUserGasFee,
    totalContractGasFee,
    totalGas,
    blockStart,
    blockLastBlock,
    traceProof,
  };

  return outputJSON;
}

function processTrace(startingBlock) {
  const traceFilePath = path.join(__dirname, `allocations/traces_${startingBlock}.json`);
  const originalFileContent = fs.readFileSync(traceFilePath, "utf-8");
  const gasStats = JSON.parse(originalFileContent);

  const outputJSON = generateOutputJSON(
    gasStats.users,
    gasStats.contracts,
    gasStats.blockStart,
    gasStats.blockLastBlock,
    originalFileContent,
  );

  const outputFileName = `processed_${gasStats.blockStart}.json`;
  const outputFilePath = path.join(__dirname, `allocations/${outputFileName}`);

  const outputJsonString = JSON.stringify(outputJSON, null, 2);
  fs.writeFileSync(outputFilePath, outputJsonString, "utf-8");

  console.log("Output JSON file has been generated:", outputFileName);
}

module.exports = processTrace;
