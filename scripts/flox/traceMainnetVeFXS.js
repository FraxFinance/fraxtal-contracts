const util = require("util");
const path = require("path");
const exec = util.promisify(require("child_process").exec);
const fs = require("fs");
const dotenv = require("dotenv");

dotenv.config();

// Define parameters
const startBlock = 12377613;
const endBlock = 19379573;
const contractAddress = "0xc8418af6358ffdda74e09ca9cc3fe03ca6adc5b0";
const eventSignature = "0x4566dfc29f6f11d13a418c26a02bef7c28bae749d4de47e4e6a7cddea6730d59"; // Deposit event signature
const apiKey = process.env.MAINNET_ETHERSCAN_API_KEY;
const outputFilename = path.join(__dirname, "mainnetVeFXS/holders.json");

// Main function to retrieve providers and store in JSON file
async function traceMainnetVeFXS() {
  const providers = await getProviders(startBlock, endBlock, contractAddress, eventSignature, apiKey);
  const uniqueProviders = removeDuplicates(providers);
  const truncatedProviders = removeZeroes(uniqueProviders);
  saveToFile(truncatedProviders, outputFilename);
}

// Function to make API call to etherscan.io
async function getProviders(startBlock, endBlock, address, eventSignature, apiKey) {
  const results = [];

  for (let block = startBlock; block <= endBlock; ) {
    let page = 1;
    let hasMorePages = true;

    while (hasMorePages) {
      const url = `https://api.etherscan.io/api?module=logs&action=getLogs&fromBlock=${block}&toBlock=${
        block + 10000
      }&address=${address}&topic0=${eventSignature}&page=${page}&offset=1000&apikey=${apiKey}`;

      try {
        const { stdout, stderr } = await exec(`curl -s "${url}"`);
        const data = JSON.parse(stdout);

        if (data.status === "1" && data.result.length > 0) {
          for (const result of data.result) {
            const provider = result.topics[1];
            results.push(provider);
          }

          // If the result has 1000 entries, fetch the next page
          if (data.result.length === 1000) {
            page++;
          } else {
            hasMorePages = false;
          }
        } else {
          hasMorePages = false;
        }
      } catch (error) {
        console.error(`Error fetching data for block ${block}, page ${page}:`, error.message);
        hasMorePages = false;
      }
    }

    // Output total retrieved number of addresses every 10 calls
    console.log(`Total retrieved number of addresses at block ${block}: ${results.length}`);

    block += 10000;

    if (block > endBlock && endBlock + 10000 != block) {
      block = endBlock;
    }
  }

  return results;
}

// Function to remove duplicate addresses
function removeDuplicates(array) {
  return [...new Set(array)];
}

// Function to save data to JSON file
function saveToFile(data, filename) {
  fs.writeFileSync(filename, JSON.stringify(data, null, 2));
  console.log(`Data saved to ${filename}`);
}

// Function to remove redundant zeros after '0x' in each address
function removeZeroes(addresses) {
  return addresses.map((address) => address.replace("000000000000000000000000", ""));
}

module.exports = traceMainnetVeFXS;
