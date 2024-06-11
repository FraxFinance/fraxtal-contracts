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
const units_1 = require("@ethersproject/units");
describe("Safe", async () => {
    const [user1] = hardhat_1.waffle.provider.getWallets();
    const setupTests = hardhat_1.deployments.createFixture(async ({ deployments }) => {
        await deployments.fixture();
        const source = `
        contract Test {
            function transferEth(address payable safe) public payable returns (bool success) {
                safe.transfer(msg.value);
            }
            function sendEth(address payable safe) public payable returns (bool success) {
                require(safe.send(msg.value));
            }
            function callEth(address payable safe) public payable returns (bool success) {
                (bool success,) = safe.call{ value: msg.value }("");
                require(success);
            }
        }`;
        return {
            safe: await (0, setup_1.getSafeWithOwners)([user1.address]),
            caller: await (0, setup_1.deployContract)(user1, source),
        };
    });
    describe("fallback", async () => {
        it("should be able to receive ETH via transfer", async () => {
            const { safe, caller } = await setupTests();
            // Notes: It is not possible to load storage + a call + emit event with 2300 gas
            await (0, chai_1.expect)(caller.transferEth(safe.address, { value: (0, units_1.parseEther)("1") })).to.be.reverted;
        });
        it("should be able to receive ETH via send", async () => {
            const { safe, caller } = await setupTests();
            // Notes: It is not possible to load storage + a call + emit event with 2300 gas
            await (0, chai_1.expect)(caller.sendEth(safe.address, { value: (0, units_1.parseEther)("1") })).to.be.reverted;
        });
        it("should be able to receive ETH via call", async () => {
            const { safe, caller } = await setupTests();
            await (0, chai_1.expect)(caller.callEth(safe.address, {
                value: (0, units_1.parseEther)("1"),
            }))
                .to.emit(safe, "SafeReceived")
                .withArgs(caller.address, (0, units_1.parseEther)("1"));
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getBalance(safe.address)).to.be.deep.eq((0, units_1.parseEther)("1"));
        });
        it("should be able to receive ETH via transaction", async () => {
            const { safe } = await setupTests();
            await (0, chai_1.expect)(user1.sendTransaction({
                to: safe.address,
                value: (0, units_1.parseEther)("1"),
            }))
                .to.emit(safe, "SafeReceived")
                .withArgs(user1.address, (0, units_1.parseEther)("1"));
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getBalance(safe.address)).to.be.deep.eq((0, units_1.parseEther)("1"));
        });
        it("should throw for incoming eth with data", async () => {
            const { safe } = await setupTests();
            await (0, chai_1.expect)(user1.sendTransaction({ to: safe.address, value: 23, data: "0xbaddad" })).to.be.revertedWith("fallback function is not payable and was called with value 23");
        });
    });
});
