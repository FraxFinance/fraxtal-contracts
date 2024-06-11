const getDelegators = require("./getDelegators");
const getDelegatees = require("./getDelegatees");
const setDelegations = require("./setDelegations");

async function main() {
  try {
    await getDelegators();
    await getDelegatees();
    await setDelegations();
  } catch (error) {
    console.error("Error:", error.message);
  }
}

main();
