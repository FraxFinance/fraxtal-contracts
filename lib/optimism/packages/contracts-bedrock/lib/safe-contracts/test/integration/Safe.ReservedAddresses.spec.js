"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    Object.defineProperty(o, k2, { enumerable: true, get: function() { return m[k]; } });
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
const chai_1 = require("chai");
const hardhat_1 = __importStar(require("hardhat"));
require("@nomiclabs/hardhat-ethers");
const setup_1 = require("../utils/setup");
const constants_1 = require("../../src/utils/constants");
describe("Safe", async () => {
    const [user1] = hardhat_1.waffle.provider.getWallets();
    const setupTests = hardhat_1.deployments.createFixture(async ({ deployments }) => {
        await deployments.fixture();
        return {
            safe: await (0, setup_1.getSafeWithOwners)([user1.address]),
        };
    });
    describe("Reserved Addresses", async () => {
        it("sentinels should not be owners or modules", async () => {
            const { safe } = await setupTests();
            const readOnlySafe = safe.connect(hardhat_1.default.ethers.provider);
            (0, chai_1.expect)(await safe.isOwner(constants_1.AddressOne)).to.be.false;
            const sig = "0x" +
                "0000000000000000000000000000000000000000000000000000000000000001" +
                "0000000000000000000000000000000000000000000000000000000000000000" +
                "01";
            await (0, chai_1.expect)(readOnlySafe.callStatic.execTransaction("0x1", 0, "0x", 0, 0, 0, 0, 0, 0, sig, {
                from: "0x0000000000000000000000000000000000000001",
            }), "Should not be able to execute transaction from sentinel as owner").to.be.reverted;
            await (0, chai_1.expect)(readOnlySafe.callStatic.execTransactionFromModule("0x1", 0, "0x", 0, {
                from: "0x0000000000000000000000000000000000000001",
            }), "Should not be able to execute transaction from sentinel as module").to.be.reverted;
        });
    });
});
