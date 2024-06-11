"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const chai_1 = require("chai");
const hardhat_1 = require("hardhat");
require("@nomiclabs/hardhat-ethers");
const execution_1 = require("../src/utils/execution");
const ethers_1 = require("ethers");
const setup_1 = require("./utils/setup");
const [, , , , user5] = hardhat_1.waffle.provider.getWallets();
(0, setup_1.benchmark)("ERC20", [{
        name: "transfer",
        prepare: async (contracts, target, nonce) => {
            const token = contracts.additions.token;
            await token.transfer(target, 1000);
            const data = token.interface.encodeFunctionData("transfer", [user5.address, 500]);
            return (0, execution_1.buildSafeTransaction)({ to: token.address, data, safeTxGas: 1000000, nonce });
        },
        after: async (contracts) => {
            (0, chai_1.expect)(await contracts.additions.token.balanceOf(user5.address)).to.be.deep.eq(ethers_1.BigNumber.from(500));
        },
        fixture: async () => {
            const tokenFactory = await hardhat_1.ethers.getContractFactory("ERC20Token");
            return {
                token: await tokenFactory.deploy()
            };
        }
    }]);
