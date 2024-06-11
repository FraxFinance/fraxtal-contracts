"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const chai_1 = require("chai");
const hardhat_1 = __importDefault(require("hardhat"));
require("@nomiclabs/hardhat-ethers");
const constants_1 = require("@ethersproject/constants");
describe("Proxy", async () => {
    describe("constructor", async () => {
        it("should revert with invalid singleton address", async () => {
            const Proxy = await hardhat_1.default.ethers.getContractFactory("SafeProxy");
            await (0, chai_1.expect)(Proxy.deploy(constants_1.AddressZero)).to.be.revertedWith("Invalid singleton address provided");
        });
    });
});
