"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
require("@nomiclabs/hardhat-ethers");
const setup_1 = require("./utils/setup");
const contractSetup = (0, setup_1.setupBenchmarkContracts)(undefined, true);
describe("Safe", async () => {
    it("creation", async () => {
        await contractSetup();
    });
});
