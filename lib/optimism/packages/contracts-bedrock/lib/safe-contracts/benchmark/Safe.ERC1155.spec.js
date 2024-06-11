"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const chai_1 = require("chai");
const hardhat_1 = require("hardhat");
require("@nomiclabs/hardhat-ethers");
const execution_1 = require("../src/utils/execution");
const ethers_1 = require("ethers");
const setup_1 = require("./utils/setup");
const [, , , , user5] = hardhat_1.waffle.provider.getWallets();
(0, setup_1.benchmark)("ERC1155", [{
        name: "transfer",
        prepare: async (contracts, target, nonce) => {
            const token = contracts.additions.token;
            await token.mint(target, 23, 1337, "0x");
            const data = token.interface.encodeFunctionData("safeTransferFrom", [target, user5.address, 23, 500, "0x"]);
            return (0, execution_1.buildSafeTransaction)({ to: token.address, data, safeTxGas: 1000000, nonce });
        },
        after: async (contracts) => {
            (0, chai_1.expect)(await contracts.additions.token.balanceOf(user5.address, 23)).to.be.deep.eq(ethers_1.BigNumber.from(500));
        },
        fixture: async () => {
            const tokenFactory = await hardhat_1.ethers.getContractFactory("ERC1155Token");
            return {
                token: await tokenFactory.deploy()
            };
        }
    }]);
