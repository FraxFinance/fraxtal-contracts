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
const constants_1 = require("@ethersproject/constants");
const setup_1 = require("../utils/setup");
describe("HandlerContext", async () => {
    const [user1, user2] = hardhat_1.waffle.provider.getWallets();
    const setup = hardhat_1.deployments.createFixture(async ({ deployments }) => {
        await deployments.fixture();
        const TestHandler = await hardhat_1.default.ethers.getContractFactory("TestHandler");
        const handler = await TestHandler.deploy();
        return {
            safe: await (0, setup_1.getSafeTemplate)(),
            handler,
        };
    });
    it("parses information correctly", async () => {
        const { handler } = await setup();
        const response = await user1.call({
            to: handler.address,
            data: handler.interface.encodeFunctionData("dudududu") + user2.address.slice(2),
        });
        (0, chai_1.expect)(handler.interface.decodeFunctionResult("dudududu", response)).to.be.deep.eq([user2.address, user1.address]);
    });
    it("works with the Safe", async () => {
        const { safe, handler } = await setup();
        await safe.setup([user1.address, user2.address], 1, constants_1.AddressZero, "0x", handler.address, constants_1.AddressZero, 0, constants_1.AddressZero);
        const response = await user1.call({
            to: safe.address,
            data: handler.interface.encodeFunctionData("dudududu"),
        });
        (0, chai_1.expect)(handler.interface.decodeFunctionResult("dudududu", response)).to.be.deep.eq([user1.address, safe.address]);
    });
});
