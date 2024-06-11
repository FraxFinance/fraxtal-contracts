const util = require('util');
const exec = util.promisify(require('child_process').exec);
const { writeFileSync, readFileSync, existsSync } = require("fs");

const [blockNumber, mainnetUrl] = process.argv.slice(2);

const BLOCKNO_OFFSET = 56612;

async function gasStats() {
	var blockNo = blockNumber.startsWith("0x")?parseInt(blockNumber,16):parseInt(blockNumber);
	var dayBlockStart = Math.floor((blockNo-BLOCKNO_OFFSET)/(30*60*24))*30*60*24+BLOCKNO_OFFSET;
	var stats = {};
	stats.users={};
	stats.contracts={};
	process.stdout.write("dayBlockStart:"+dayBlockStart+"\n");

	var file = "traces_"+dayBlockStart+".json"; // put a day of blocks into a single file
	if (existsSync(file)) {
		var data = readFileSync(file);
		stats = JSON.parse(data);
		blockNo = parseInt(stats.blockLastBlock)+1;
   } else {
		blockNo = dayBlockStart;
		stats.blockStart =blockNo;
	}
	while (Math.floor((blockNo-BLOCKNO_OFFSET)/(30*60*24))*30*60*24+BLOCKNO_OFFSET == dayBlockStart) {
		stats.blockLastBlock =blockNo;
		await getStatsOfBlock(stats,blockNo);
		if (blockNo%10==0) writeFileSync(file, JSON.stringify(stats, null, 2)); // Write to disk in case we crash
		blockNo++;
	}
	writeFileSync(file, JSON.stringify(stats, null, 2));
	//process.stdout.write("stats:"+JSON.stringify(stats,null,2)+"\n");
}

gasStats();

async function getStatsOfBlock(stats, blockNo) {
		process.stdout.write("block:"+blockNo+"\n");
		var block={};
		var cmd = "curl "+mainnetUrl+" -X POST -H \"Content-Type: application/json\" --data '{\"method\":\"eth_getBlockByNumber\",\"params\":[\"0x"+blockNo.toString(16)+"\",true],\"id\":1,\"jsonrpc\":\"2.0\"}'";
		var execResult = await exec(cmd);
		if (execResult.error && execResult.error !== null) {
			console.log("exec error: " + execResult.error);
			return;
		}
		var block= JSON.parse(execResult.stdout).result;
		var hasTransactionWithGas = false;
		for (var i=0;i<block.transactions.length;i++) {
			hasTransactionWithGas|=parseHex(block.transactions[i].gasPrice)>0;
	   }
		if (hasTransactionWithGas) {
			cmd = "curl "+mainnetUrl+" -X POST -H \"Content-Type: application/json\" --data '{\"method\":\"debug_traceBlockByNumber\",\"params\":[\"0x"+blockNo.toString(16)+"\",{\"tracer\": \"callTracer\", \"timeout\": \"150s\"}],\"id\":1,\"jsonrpc\":\"2.0\"}'";
			execResult = await exec(cmd,{maxBuffer: 100 * 1024 * 1024});
			if (execResult.error && execResult.error !== null) {
				console.log("exec error: " + execResult.error);
				return;
			}
			var traces = JSON.parse(execResult.stdout).result;
			if (!traces) console.log(execResult.stdout);

			for (var i=0;i<block.transactions.length;i++) {
			  var transaction = block.transactions[i];
			  var gasPrice = parseHex(transaction.gasPrice);
			  if (gasPrice>0) { // skip free transactions
				  process.stdout.write("transaction:"+transaction.hash+"\n");
				  for (var j=0;j<traces.length;j++) {
					  var trace = traces[i];
					  if (trace.txHash==transaction.hash) {
						  addTraceToStats(gasPrice, trace, stats);
						  break;
				  	  }
				  }
			  }
		  }
	  }
}

function addTraceToStats(gasPrice, trace, stats) {
	var user = trace.result.from;
	var userInfo = stats.users[user];
	if (!userInfo) userInfo=stats.users[user]={"totalGas":0, "totalFee":0, "transactions":0, "contracts":{}};
	var gasUsed = parseHex(trace.result.gasUsed);
	if (gasUsed>0) {
		userInfo.totalGas+=gasUsed;
		userInfo.totalFee+=gasUsed*gasPrice;
		userInfo.transactions++;
		var contract = trace.result.to;

		gasUsed = addCallsToStatsRecurse(gasUsed,1,trace.result.calls,user, gasPrice,stats);

		var contractInfo = userInfo.contracts[trace.result.to];
		if (!contractInfo) contractInfo = userInfo.contracts[trace.result.to]={"totalGas":0, "totalFee":0, "calls":0};
		contractInfo.totalGas+=gasUsed;
		contractInfo.totalFee+=gasUsed*gasPrice;
		contractInfo.calls++;

		contractInfo = stats.contracts[trace.result.to];
		if (!contractInfo) contractInfo = stats.contracts[trace.result.to]={"totalGas":0, "totalFee":0, "calls":0};
		contractInfo.totalGas+=gasUsed;
		contractInfo.totalFee+=gasUsed*gasPrice;
		contractInfo.calls++;
   }
}

function addCallsToStatsRecurse(gasUsed, gasMultiplier, calls, user, gasPrice, stats) {
	var totalGasUsed = 0;
	var gasMultiplier2 = 1;
	if (calls && calls.length>0) {
		for (var i=0;i<calls.length;i++) {
			var call = calls[i];
			if (call.to && !call.to.startsWith("0x000000000000000000000000000000000000")) { // skip precompiles
				totalGasUsed+=parseHex(call.gasUsed);
			}
		}
		if (totalGasUsed>gasUsed) {
			gasMultiplier2 = gasUsed/totalGasUsed;
			gasMultiplier*=gasMultiplier2;
		}

		for (var i=0;i<calls.length;i++) {
			var call = calls[i];
			if (call.to && !call.to.startsWith("0x000000000000000000000000000000000000")) { // skip precompiles
				var gasUsed2 = parseHex(call.gasUsed);
				if (gasUsed2>0) {
					var contract = call.type=="DELEGATECALL"?call.from:call.to;

					gasUsed2 = addCallsToStatsRecurse(gasUsed2, gasMultiplier, call.calls, user, gasPrice,stats )
					var contractInfo = stats.users[user].contracts[contract];
					if (!contractInfo) contractInfo = stats.users[user].contracts[contract]={"totalGas":0, "totalFee":0, "calls":0};
					contractInfo.totalGas+=gasUsed2*gasMultiplier;
					contractInfo.totalFee+=gasUsed2*gasMultiplier*gasPrice;
					contractInfo.calls++;

					contractInfo = stats.contracts[contract];
					if (!contractInfo) contractInfo = stats.contracts[contract]={"totalGas":0, "totalFee":0, "calls":0};

					contractInfo.totalGas+=gasUsed2*gasMultiplier;
					contractInfo.totalFee+=gasUsed2*gasMultiplier*gasPrice;
					contractInfo.calls++;
				}
			}
		}
   }

	return gasUsed-totalGasUsed*gasMultiplier2;
}

function parseHex(val) {
		return parseInt(val.substring(2),16);
}
