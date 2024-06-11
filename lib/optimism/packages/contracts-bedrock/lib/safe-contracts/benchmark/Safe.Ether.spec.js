"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const chai_1 = require("chai");
const hardhat_1 = require("hardhat");
require("@nomiclabs/hardhat-ethers");
const execution_1 = require("../src/utils/execution");
const ethers_1 = require("ethers");
const setup_1 = require("./utils/setup");
const testTarget = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE";
const [user1] = hardhat_1.waffle.provider.getWallets();
(0, setup_1.benchmark)("Ether", [{
        name: "transfer",
        prepare: async (_, target, nonce) => {
            // Create account, as we don't want to test this in the benchmark
            await user1.sendTransaction({ to: testTarget, value: 1 });
            await user1.sendTransaction({ to: target, value: 1000 });
            return (0, execution_1.buildSafeTransaction)({ to: testTarget, value: 500, safeTxGas: 1000000, nonce });
        },
        after: async () => {
            (0, chai_1.expect)(await hardhat_1.ethers.provider.getBalance(testTarget)).to.be.deep.eq(ethers_1.BigNumber.from(501));
        },
    }]);
