const traceMainnetVeFXS = require("./traceMainnetVeFXS");
const retrieveMainnetVeFXSBalances = require("./retrieveMainnetVeFXSBalances");
const calculateMainnetVeFXSFXTLAllocation = require("./calculateMainnetVeFXSFXTLAllocation");

async function main() {
  try {
    // await traceMainnetVeFXS();
    await retrieveMainnetVeFXSBalances();
    await calculateMainnetVeFXSFXTLAllocation();
  } catch (error) {
    console.error("Error:", error.message);
  }
}

main();
