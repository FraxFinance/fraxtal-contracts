const fs = require("fs");
const ethers = require("ethers");
const dotenv = require("dotenv");
const path = require("path");

dotenv.config();

const rpcEndpoint = process.env.MAINNET_RPC_URL;
// const rpcEndpoint = 'https://rpc.testnet.frax.com/alt';
const provider = new ethers.providers.JsonRpcProvider(rpcEndpoint);
const privateKey = process.env.PK;
const wallet = new ethers.Wallet(privateKey, provider);

// Contract address and ABI
const fxtlPointsAddress = "0x667b09d0756ce783c27479daf0f16bc428e9bbca";
const fxtlPointsAbiPath = path.join(__dirname, "abis/FxtlPoints.json");
const fxtlPointsABI = fs.readFileSync(fxtlPointsAbiPath, "utf-8");

const batchSize = 500;

async function main() {
  // Read the JSON file
  const allocationsFilePath = path.join(__dirname, "mainnetVeFXS/pointsToAllocate.json");
  const jsonData = fs.readFileSync(allocationsFilePath, "utf-8");
  const pointsData = JSON.parse(jsonData);

  // Filter out entries with 0 points
  const filteredEntries = Object.entries(pointsData).filter(([, data]) => data.points > 0);

  // Split filtered entries into bulks of batchSize
  const bulks = [];
  for (let i = 0; i < filteredEntries.length; i += batchSize) {
    bulks.push(filteredEntries.slice(i, i + batchSize));
  }

  await allocatePoints(bulks);
}

// Allocate points in bulks
async function allocatePoints(bulks) {
  const fxtlPoints = new ethers.Contract(fxtlPointsAddress, fxtlPointsABI, wallet);

  for (const bulk of bulks) {
    const addresses = bulk.map(([address]) => address);
    const points = bulk.map(([, data]) => data.points);

    await fxtlPoints.bulkAddFxtlPoints(addresses, points, { gasLimit: 15000000 });

    console.log(`Allocated points to ${addresses.length} addresses.`);

    sleep(5000); // Sleep for 5 seconds to avoid rate limiting & nonce collisions
  }
}

function sleep(milliseconds) {
  const start = new Date().getTime();
  while (new Date().getTime() - start < milliseconds) {}
}

main()
  .then(() => {
    console.log("Allocation completed.");
  })
  .catch((error) => {
    console.error("Error:", error);
  });
