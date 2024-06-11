const util = require("util");
const path = require("path");
const exec = util.promisify(require("child_process").exec);
const { writeFileSync, readFileSync, existsSync } = require("fs");
const { tokenWeightConsts, fxtlBoostMultiplier } = require("./utils/floxConstants");

const [_blockNumber] = process.argv.slice(2);

async function calculateFLOXPRank(startBlockNumber) {
  const startingBlock = parseInt(startBlockNumber);
  let _blockNo = startingBlock;

  var statsFilename = "allocations/traces_" + _blockNo + ".json";
  var statsFile = path.join(__dirname, statsFilename);
  var tokenFilename = "allocations/traces_tokens_" + _blockNo + ".json";
  var tokenFile = path.join(__dirname, tokenFilename);
  var fxtlPositionFilename = "allocations/traces_tokens_users_FXTL_" + _blockNo + ".json";
  var fxtlPositionFile = path.join(__dirname, fxtlPositionFilename);
  var outputFilenameJson = "allocations/traces_rank_" + _blockNo + ".json";
  var outputFileJson = path.join(__dirname, outputFilenameJson);
  var outputFilenameCSV = "allocations/traces_rank_" + _blockNo + ".csv";
  var outputFileCSV = path.join(__dirname, outputFilenameCSV);

  if (existsSync(statsFile)) {
    var stats = JSON.parse(readFileSync(statsFile));
    var tokens = JSON.parse(readFileSync(tokenFile));
    var fxtlPosition = JSON.parse(readFileSync(fxtlPositionFile));
    var transferTotalFee = 0;
    var transferTotalGas = 0;
    var transferTotalCalls = 0;
    var result = {};
    var users = (result.users = {});
    var contracts = (result.contracts = {});
    for (var contract in stats.contracts) {
      var tokenInfo = tokens[contract];
      if (tokenInfo) {
        var tokenBoost = 0;
        for (var token in tokenWeightConsts) {
          if (tokenInfo[token]) tokenBoost += tokenInfo[token] * tokenWeightConsts[token];
        }
        stats.contracts[contract].tokenBoost =
          (tokenBoost + stats.contracts[contract].totalFee) / stats.contracts[contract].totalFee;
        console.log(contract + ":" + stats.contracts[contract].tokenBoost);
      }
    }

    for (var user in stats.users) {
      for (var contract in stats.users[user].contracts) {
        var targetContract = contract;
        if (stats.users[user].contracts[contract].totalGas == 21000) {
          targetContract = "0xtransfer";
          transferTotalFee += stats.users[user].contracts[contract].totalFee;
          transferTotalGas += stats.users[user].contracts[contract].totalGas;
          transferTotalCalls++;
        }
        var userAdd = stats.users[user].contracts[contract].totalFee;
        if (!users[user]) users[user] = userAdd;
        else users[user] += userAdd;
        var contractAdd = stats.users[user].contracts[contract].totalFee;
        if (!contracts[targetContract]) contracts[targetContract] = contractAdd;
        else contracts[targetContract] += contractAdd;
      }
      if (fxtlPosition.userBalances[user] && stats.users[user].totalFee > 0) {
        var boost = parseInt(fxtlPosition.userBalances[user].hex, 16) * fxtlBoostMultiplier;
        stats.users[user].fxtlBoost = (stats.users[user].totalFee + boost) / stats.users[user].totalFee;
      } else stats.users[user].fxtlBoost = 1;
    }
    normalize(users);
    normalize(contracts);
    for (i = 0; i < 50; i++) {
      rank(stats, result);
      process.stdout.write("round:" + i + " oxtransfer:" + result.contracts["oxtransfer"] + "\n");
    }
    writeFileSync(outputFileJson, JSON.stringify(result, null, 2));

    var out = "type,address,totalGas,totalFee,calls,rank0,rank\n";
    for (var user in result.users) {
      out +=
        "EOA," +
        user +
        "," +
        stats.users[user].totalGas +
        "," +
        stats.users[user].totalFee +
        "," +
        stats.users[user].transactions +
        "," +
        users[user] +
        "," +
        result.users[user] +
        "\n";
    }
    for (var contract in result.contracts) {
      if (contract == "0xtransfer")
        out +=
          "CONTRACT," +
          contract +
          "," +
          transferTotalGas +
          "," +
          transferTotalFee +
          "," +
          transferTotalCalls +
          "," +
          contracts[contract] +
          "," +
          result.contracts[contract] +
          "\n";
      else if (stats.contracts[contract])
        out +=
          "CONTRACT," +
          contract +
          "," +
          stats.contracts[contract].totalGas +
          "," +
          stats.contracts[contract].totalFee +
          "," +
          stats.contracts[contract].calls +
          "," +
          contracts[contract] +
          "," +
          result.contracts[contract] +
          "\n";
      else
        out +=
          "CONTRACT," +
          contract +
          "," +
          0 +
          "," +
          0 +
          "," +
          0 +
          "," +
          contracts[contract] +
          "," +
          result.contracts[contract] +
          "\n";
    }
    writeFileSync(outputFileCSV, out);
  }
}
function rank(stats, result) {
  var newContracts = {};
  var newUsers = {};
  for (var user in result.users) {
    for (var contract in stats.users[user].contracts) {
      var targetContract = stats.users[user].contracts[contract].totalGas == 21000 ? "oxtransfer" : contract;
      var userAdd = stats.users[user].contracts[contract].totalFee * Math.sqrt(result.contracts[targetContract]);
      if (!userAdd) userAdd = stats.users[user].contracts[contract].totalFee * 1e-50;
      if (stats.contracts[contract].tokenBoost) userAdd = userAdd * stats.contracts[contract].tokenBoost;
      if (stats.users[user].fxtlBoost) userAdd = userAdd * stats.users[user].fxtlBoost;
      if (!newUsers[user]) newUsers[user] = userAdd;
      else newUsers[user] += userAdd;
      var contractAdd = stats.users[user].contracts[contract].totalFee * Math.sqrt(result.users[user]);
      if (stats.users[user].fxtlBoost) contractAdd = contractAdd * stats.users[user].fxtlBoost;
      if (!newContracts[targetContract]) newContracts[targetContract] = contractAdd;
      else newContracts[targetContract] += contractAdd;
    }
  }
  result.users = normalize(newUsers);
  result.contracts = normalize(newContracts);
}

function normalize(map) {
  var sum = 0;
  for (var el in map) sum += map[el];
  for (var el in map) map[el] = map[el] / sum;
  return map;
}

module.exports = calculateFLOXPRank;
