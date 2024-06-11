const fs = require("fs");
const ethers = require("ethers");
const path = require("path");
const dotenv = require("dotenv");

dotenv.config();

const targetBlock = 19379573;

// Function to retrieve balances and write to file
async function retrieveMainnetVeFXSBalances() {
  // Ethereum JSON-RPC endpoint
  const rpcEndpoint = process.env.MAINNET_RPC_URL;

  // ABI of the smart veFXS
  const veFXSABIPath = path.join(__dirname, "abis/MainnetVeFXS.json");
  const veFXSABI = fs.readFileSync(veFXSABIPath, "utf-8");

  // Address of the smart veFXS
  const veFXSAddress = "0xc8418af6358ffdda74e09ca9cc3fe03ca6adc5b0";

  // Ethereum provider
  const provider = new ethers.providers.JsonRpcProvider(rpcEndpoint);

  // Get timestamp of the target block
  const blockInfo = await provider.getBlock(targetBlock);
  const targetTimestamp = blockInfo.timestamp;

  // Ethereum veFXS instance
  const veFXS = new ethers.Contract(veFXSAddress, veFXSABI, provider);

  const holderFilePath = path.join(__dirname, "mainnetVeFXS/holders.json");
  const holdersData = fs.readFileSync(holderFilePath, "utf-8");
  const holders = JSON.parse(holdersData);

  // Path to the output JSON file
  const outputFile = path.join(__dirname, "mainnetVeFXS/balances.json");

  // Load existing balances from the output file if it exists
  let balances = {};
  if (fs.existsSync(outputFile)) {
    balances = JSON.parse(fs.readFileSync(outputFile));
  }

  let count = 0;

  for (const address of holders) {
    // Check if the balance for the address is already retrieved
    if (!(address in balances)) {
      // Retrieve balance
      let balance = await veFXS.balanceOf(address, { blockTag: targetBlock });
      const lockEndTimestamp = await veFXS.locked__end(address, { blockTag: targetBlock });

      // If the lock end timestamp is in the past compared to the target block timestamp, set the balance to 0
      if (lockEndTimestamp.toNumber() < targetTimestamp) {
        balance = ethers.BigNumber.from(0);
      }

      balances[address] = balance;

      count++;

      // Write balances to file every 100 times
      if (count % 100 === 0) {
        writeBalancesToFile(balances, outputFile);
        console.log("Retrieved balances for", count, "addresses");
      }
    }
  }

  // Write balances to file at the end
  writeBalancesToFile(balances, outputFile);
}

// Function to write balances to file
function writeBalancesToFile(balances, outputFile) {
  fs.writeFileSync(outputFile, JSON.stringify(balances, null, 2));
  console.log("Balances written to file:", outputFile);
}

module.exports = retrieveMainnetVeFXSBalances;
