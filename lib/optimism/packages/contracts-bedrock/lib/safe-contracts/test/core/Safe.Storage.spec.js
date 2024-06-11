"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const chai_1 = require("chai");
const hardhat_1 = __importDefault(require("hardhat"));
require("@nomiclabs/hardhat-ethers");
const storage_1 = require("../utils/storage");
describe("Safe", async () => {
    it("follows storage layout defined by SafeStorage library", async () => {
        const safeStorageLayout = await (0, storage_1.getContractStorageLayout)(hardhat_1.default, "SafeStorage");
        const safeSingletonStorageLayout = await (0, storage_1.getContractStorageLayout)(hardhat_1.default, "Safe");
        // Chai doesn't have built-in matcher for deep object equality
        // For the sake of simplicity I decided just to convert the object to a string and compare the strings
        (0, chai_1.expect)(JSON.stringify(safeSingletonStorageLayout).startsWith(JSON.stringify(safeStorageLayout))).to.be.true;
    });
});
