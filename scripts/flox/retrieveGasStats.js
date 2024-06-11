const util = require("util");
const path = require("path");
const exec = util.promisify(require("child_process").exec);
const { writeFileSync, readFileSync, existsSync, mkdirSync } = require("fs");
const { hourBlockDuration, weightedContractAddresses } = require("./utils/floxConstants");

let mainnetUrl;

const L1GAS_MULTIPLIER = 1.0; // 100% of L1 gas is used to boost gasprice

async function retrieveGasStats(startBlockNumber, endBlockNumber, rpcUrl) {
  mainnetUrl = rpcUrl;
  const startingBlock = parseInt(startBlockNumber);
  let blockNo = startingBlock;
  const endBlock = parseInt(endBlockNumber);
  const stats = {
    users: {},
    contracts: {},
  };

  process.stdout.write(`startingBlock: ${startingBlock}\n`);

  const file = path.join(__dirname, `allocations/traces_${startingBlock}.json`);
  console.log(`file: ${file}\n`);

  if (existsSync(file)) {
    try {
      const data = readFileSync(file);
      const parsedData = JSON.parse(data);
      blockNo = parseInt(parsedData.blockLastBlock) + 1;
      stats.blockStart = parsedData.blockStart;
      stats.blockLastBlock = parsedData.blockLastBlock;
      stats.users = parsedData.users;
      stats.contracts = parsedData.contracts;
    } catch (error) {
      console.error("Error parsing existing file:", error);
    }
  } else {
    blockNo = startingBlock;
    stats.blockStart = blockNo;
  }

  let currentHour = Math.floor((blockNo - startingBlock) / hourBlockDuration);
  let currentStats = {
    users: {},
    contracts: {},
  };
  let currentStatsFile = path.join(__dirname, `allocations/hourly_traces_${startingBlock}/traces_${currentHour}.json`);

  if (existsSync(currentStatsFile)) {
    try {
      const data = readFileSync(currentStatsFile);
      const parsedData = JSON.parse(data);
      currentStats.blockStart = parsedData.blockStart;
      currentStats.blockLastBlock = parsedData.blockLastBlock;
      currentStats.users = parsedData.users;
      currentStats.contracts = parsedData.contracts;
    } catch (error) {
      console.error("Error parsing existing file:", error);
    }
  } else {
    currentStats.blockStart = blockNo;
    try {
      mkdirSync(path.join(__dirname, `allocations/hourly_traces_${startingBlock}`), { recursive: true });
      console.log("Hourly trace log directory created successfully.");
    } catch (err) {
      console.error("Error creating hourly trace log directory:", err);
    }
  }

  while (blockNo <= endBlock) {
    if (currentHour !== Math.floor((blockNo - startingBlock) / hourBlockDuration)) {
      currentHour = Math.floor((blockNo - startingBlock) / hourBlockDuration);
      currentStats = {
        users: {},
        contracts: {},
      };
      currentStatsFile = path.join(__dirname, `allocations/hourly_traces_${startingBlock}/traces_${currentHour}.json`);
    }
    stats.blockLastBlock = blockNo;
    currentStats.blockLastBlock = blockNo;
    await getStatsOfBlock(stats, blockNo);
    await getStatsOfBlock(currentStats, blockNo);

    if (blockNo % 10 === 0) {
      // Write to disk in case we crash
      writeFileSync(currentStatsFile, JSON.stringify(currentStats, null, 2));
      writeFileSync(file, JSON.stringify(stats, null, 2));
    }
    blockNo++;
  }

  writeFileSync(file, JSON.stringify(stats, null, 2));
  console.log(file);

  retrieveTokenBalances(file, mainnetUrl, startingBlock, endBlock)
    .then(() => console.log("Token balances retrieved successfully"))
    .catch((error) => console.error("Error retrieving token balances:", error));
}

async function getStatsOfBlock(stats, blockNo) {
  process.stdout.write(`block: ${blockNo}\n`);
  const cmd = `curl ${mainnetUrl} -X POST -H "Content-Type: application/json" --data '{"method":"eth_getBlockByNumber","params":["0x${blockNo.toString(
    16,
  )}",true],"id":1,"jsonrpc":"2.0"}'`;

  try {
    const execResult = await exec(cmd);
    if (execResult.error && execResult.error !== null) {
      console.error("exec error:", execResult.error);
      return;
    }

    const block = JSON.parse(execResult.stdout).result;
    const hasTransactionWithGas = block.transactions.some((transaction) => parseHex(transaction.gasPrice) > 0);

    if (hasTransactionWithGas) {
      var l1BlockValues = parseL1BlockValues(block.transactions[0].input);
      const traceCmd = `curl ${mainnetUrl} -X POST -H "Content-Type: application/json" --data '{"method":"debug_traceBlockByNumber","params":["0x${blockNo.toString(
        16,
      )}",{"tracer": "callTracer", "timeout": "150s"}],"id":1,"jsonrpc":"2.0"}'`;
      const traceResult = await exec(traceCmd, { maxBuffer: 100 * 1024 * 1024 });
      const traces = JSON.parse(traceResult.stdout).result;

      if (!traces) console.log(traceResult.stdout);

      for (const transaction of block.transactions) {
        const gasPrice = parseHex(transaction.gasPrice);
        if (gasPrice > 0) {
          var l1GasPaid = estimateL1FeePaid(transaction, l1BlockValues);
          process.stdout.write(`transaction: ${transaction.hash}, ${l1GasPaid}\n`);
          for (const trace of traces) {
            if (trace.txHash === transaction.hash) {
              const gasUsed = parseHex(trace.result.gasUsed);
              var l1multiplier = (gasPrice * gasUsed + l1GasPaid * L1GAS_MULTIPLIER) / (gasPrice * gasUsed);
              addTraceToStats(gasPrice * l1multiplier, trace, stats);
              break;
            }
          }
        }
      }
    }
  } catch (error) {
    console.error("Error processing block:", error);
  }
}

async function retrieveTokenBalances(statsFile, mainnetUrl, startBlockNumber, endBlockNumber) {
  const blockNo = Math.floor(Math.random() * (endBlockNumber - startBlockNumber + 1)) + startBlockNumber;

  if (existsSync(statsFile)) {
    const data = readFileSync(statsFile);
    const stats = JSON.parse(data);
    let list = [];
    for (const contract in stats.contracts) {
      if (contract.length === 42 && stats.contracts[contract].totalGas > 50000) list.push(contract);
    }
    console.log("Total contracts:", list.length);

    let tokenAmounts = {};
    const tokens = weightedContractAddresses;

    for (const tokenAddress of tokens) {
      tokenAmounts[tokenAddress] = {}; // Initialize balances object for each token
      for (let i = 0; i < list.length; i += 300) {
        let data = "0x252dba42" + toWord(32);
        let count = Math.min(list.length - i, 300);
        data += toWord(count); // number
        for (let c = 0; c < count; c++) data += toWord(count * 32 + c * 5 * 32); // pointers
        for (let c = 0; c < count; c++) {
          data += "000000000000000000000000" + tokenAddress.substring(2); // contract
          data += toWord(2 * 32); // pointer
          data += toWord(36); // length of data
          data +=
            "70a08231000000000000000000000000" +
            list[i + c].substring(2) +
            "00000000000000000000000000000000000000000000000000000000"; // data
        }

        const cmd =
          "curl " +
          mainnetUrl +
          ' -X POST -H "Content-Type: application/json" --data \'' +
          JSON.stringify({
            method: "eth_call",
            params: [
              {
                from: null,
                to: "0xcA11bde05977b3631167028862bE2a173976CA11",
                data: data,
              },
              "0x" + blockNo.toString(16),
            ],
            id: 1,
            jsonrpc: "2.0",
          }) +
          "'";
        const execResult = await exec(cmd);
        if (execResult.error && execResult.error !== null) {
          console.log("exec error: " + execResult.error);
          return;
        }

        const dataOut = JSON.parse(execResult.stdout).result;
        if (!dataOut) {
          console.log("execResult:" + execResult.stdout);
          for (let w = 0; w < data.length; w += 64) console.log(data.substring(w + 10, w + 64 + 10));
          break;
        }

        for (let c = 0; c < count; c++) {
          const amount = parseInt(
            "0x" + dataOut.substring(258 + 64 * count + 128 * c, 258 + 64 * count + 128 * c + 64),
          );
          if (amount > 0) {
            const address = list[i + c];
            console.log(address + ":" + amount);
            if (!tokenAmounts[address]) tokenAmounts[address] = {};
            tokenAmounts[address][tokenAddress] = amount;
          }
        }
      }
    }

    // Remove users with empty balances
    for (const userAddress in tokenAmounts) {
      if (Object.values(tokenAmounts[userAddress]).every((balance) => balance === 0)) {
        delete tokenAmounts[userAddress];
      }
    }

    // Write token balances and block number to a JSON file
    const balancesAndBlockNumber = {
      balances: tokenAmounts,
      blockNumber: blockNo,
    };

    const outputFileName = `traces_tokens_${startBlockNumber}.json`;
    const outputFilePath = path.join(__dirname, `allocations/${outputFileName}`);
    writeFileSync(outputFilePath, JSON.stringify(balancesAndBlockNumber, null, 2));

    console.log("Token balances and block number written to", outputFileName);
  }
}
// Quick&dirty estimate of L1 fees
function estimateL1FeePaid(transaction, l1BlockValues) {
  var result = l1BlockValues.l1FeeOverhead;
  var data = transaction.from.substring(2) + transaction.input.substring(2);
  if (transaction.to != null && transaction.to != "0x0") data += transaction.to.substring(2);
  if (transaction.r != null && transaction.r != "0x0") data += transaction.r.substring(2);
  if (transaction.s != null && transaction.s != "0x0") data += transaction.s.substring(2);
  for (var i = 0; i + 1 < data.length; i += 2) {
    if (data.substring(i, i + 2) == "00") result += 4;
    else result += 16;
  }
  result = (result * l1BlockValues.basefee * l1BlockValues.l1FeeScalar) / 1000000;
  return result;
}
function parseL1BlockValues(input) {
  result = {};
  result.number = parseInt(input.substring(10, 74), 16);
  result.timestamp = parseInt(input.substring(74, 138), 16);
  result.basefee = parseInt(input.substring(138, 202), 16);
  result.hash = "0x" + input.substring(202, 266);
  result.sequenceNumber = parseInt(input.substring(266, 330), 16);
  result.batcherHash = "0x" + input.substring(330, 394);
  result.l1FeeOverhead = parseInt(input.substring(394, 458), 16);
  result.l1FeeScalar = parseInt(input.substring(458, 522), 16);
  return result;
}

function toWord(val) {
  var result = val.toString(16);
  result = "0000000000000000000000000000000000000000000000000000000000000000".substring(0, 64 - result.length) + result;
  return result;
}

function addTraceToStats(gasPrice, trace, stats) {
  const user = trace.result.from;
  let userInfo = stats.users[user];

  if (!userInfo) {
    userInfo = stats.users[user] = { totalGas: 0, totalFee: 0, transactions: 0, contracts: {} };
  }

  let gasUsed = parseHex(trace.result.gasUsed);

  if (gasUsed > 0) {
    userInfo.totalGas += gasUsed;
    userInfo.totalFee += gasUsed * gasPrice;
    userInfo.transactions++;

    const contract = trace.result.to;
    gasUsed = addCallsToStatsRecurse(gasUsed, 1, trace.result.calls, user, gasPrice, stats);

    let contractInfo = userInfo.contracts[trace.result.to];

    if (!contractInfo) {
      contractInfo = userInfo.contracts[trace.result.to] = { totalGas: 0, totalFee: 0, calls: 0 };
    }

    contractInfo.totalGas += gasUsed;
    contractInfo.totalFee += gasUsed * gasPrice;
    contractInfo.calls++;

    contractInfo = stats.contracts[trace.result.to];

    if (!contractInfo) {
      contractInfo = stats.contracts[trace.result.to] = { totalGas: 0, totalFee: 0, calls: 0 };
    }

    contractInfo.totalGas += gasUsed;
    contractInfo.totalFee += gasUsed * gasPrice;
    contractInfo.calls++;
  }
}

function addCallsToStatsRecurse(gasUsed, gasMultiplier, calls, user, gasPrice, stats) {
  let totalGasUsed = 0;
  let gasMultiplier2 = 1;

  if (calls && calls.length > 0) {
    for (const call of calls) {
      if (call.to && !call.to.startsWith("0x000000000000000000000000000000000000")) {
        totalGasUsed += parseHex(call.gasUsed);
      }
    }

    if (totalGasUsed > gasUsed) {
      gasMultiplier2 = gasUsed / totalGasUsed;
      gasMultiplier *= gasMultiplier2;
    }

    for (const call of calls) {
      if (call.to && !call.to.startsWith("0x000000000000000000000000000000000000")) {
        let gasUsed2 = parseHex(call.gasUsed);

        if (gasUsed2 > 0) {
          const contract = call.type === "DELEGATECALL" ? call.from : call.to;

          gasUsed2 = addCallsToStatsRecurse(gasUsed2, gasMultiplier, call.calls, user, gasPrice, stats);
          let contractInfo = stats.users[user].contracts[contract];

          if (!contractInfo) {
            contractInfo = stats.users[user].contracts[contract] = { totalGas: 0, totalFee: 0, calls: 0 };
          }

          contractInfo.totalGas += gasUsed2 * gasMultiplier;
          contractInfo.totalFee += gasUsed2 * gasMultiplier * gasPrice;
          contractInfo.calls++;

          contractInfo = stats.contracts[contract];

          if (!contractInfo) {
            contractInfo = stats.contracts[contract] = { totalGas: 0, totalFee: 0, calls: 0 };
          }

          contractInfo.totalGas += gasUsed2 * gasMultiplier;
          contractInfo.totalFee += gasUsed2 * gasMultiplier * gasPrice;
          contractInfo.calls++;
        }
      }
    }
  }

  return gasUsed - totalGasUsed * gasMultiplier2;
}

function parseHex(val) {
  return parseInt(val.substring(2), 16);
}

module.exports = retrieveGasStats;
