const util = require('util');
const exec = util.promisify(require('child_process').exec);
const { writeFileSync, readFileSync, existsSync } = require("fs");

const [_blockNumber] = process.argv.slice(2);

const BLOCKNO_OFFSET = 56612;

async function gasStatsConvert() {
	var _blockNo = _blockNumber.startsWith("0x")?parseInt(_blockNumber,16):parseInt(_blockNumber);
	var dayBlockStart = Math.floor((_blockNo-BLOCKNO_OFFSET)/(30*60*24))*30*60*24+BLOCKNO_OFFSET;
	process.stdout.write("dayBlockStart:"+dayBlockStart+"\n");

	var statsFile = "traces_"+dayBlockStart+".json";
	var outputFile = "traces_"+dayBlockStart+".csv";
	if (existsSync(statsFile)) {
		var data = readFileSync(statsFile);
		_stats = JSON.parse(data);
		var result = "type,address,totalGas,totalFee,calls\n";
		for (var user in _stats.users) {
			result+="EOA,"+user+","+_stats.users[user].totalGas+","+_stats.users[user].totalFee+","+_stats.users[user].transactions+"\n"
		}
		for (var contract in _stats.contracts) {
			result+="CONTRACT,"+contract+","+_stats.contracts[contract].totalGas+","+_stats.contracts[contract].totalFee+","+_stats.contracts[contract].calls+"\n"
		}
		writeFileSync(outputFile, result);
   }
}

gasStatsConvert();
