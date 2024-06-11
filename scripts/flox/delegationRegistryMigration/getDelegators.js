const util = require("util");
const path = require("path");
const exec = util.promisify(require("child_process").exec);
const fs = require("fs");
const dotenv = require("dotenv");

dotenv.config();

// Define parameters
// const startBlock = 903419;
// const endBlock = 1795450;
// const startBlock = 1795451;
// const endBlock = 2213785;
const startBlock = 1783019;
const endBlock = 4441104;
const contractAddress = "0xF5cA906f05cafa944c27c6881bed3DFd3a785b6A";
const eventSignature = "0x5cbf8b4dd601c76e8851d991825e8d0d29d914f78f40fcc8ebddd97d913f149c"; // DelegationUpdated event signature
const apiKey = process.env.ETHERSCAN_API_KEY;
const outputFilename = path.join(__dirname, "data/delegators.json");

// Main function to retrieve delegators and store in JSON file
async function getDelegators() {
  const delegators = await retireveDelegators(startBlock, endBlock, contractAddress, eventSignature, apiKey);
  const uniqueDelegators = removeDuplicates(delegators);
  const truncatedDelegators = removeZeroes(uniqueDelegators);
  saveToFile(truncatedDelegators, outputFilename);
}

// Function to make API call to fraxscan.io
async function retireveDelegators(startBlock, endBlock, address, eventSignature, apiKey) {
  const results = [];

  for (let block = startBlock; block <= endBlock; ) {
    let page = 1;
    let hasMorePages = true;

    while (hasMorePages) {
      const url = `https://api.fraxscan.com/api?module=logs&action=getLogs&fromBlock=${block}&toBlock=${
        block + 10000
      }&address=${address}&topic0=${eventSignature}&page=${page}&offset=1000&apikey=${apiKey}`;

      try {
        const { stdout, stderr } = await exec(`curl -s "${url}"`);
        const data = JSON.parse(stdout);

        if (data.status === "1" && data.result.length > 0) {
          for (const result of data.result) {
            const delegator = result.topics[1];
            results.push(delegator);
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
  return addresses.map((address) => address.replace("0x000000000000000000000000", "0x"));
}

module.exports = getDelegators;
