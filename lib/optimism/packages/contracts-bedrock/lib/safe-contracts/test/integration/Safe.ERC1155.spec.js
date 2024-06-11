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
const ethers_1 = require("ethers");
require("@nomiclabs/hardhat-ethers");
const constants_1 = require("@ethersproject/constants");
const setup_1 = require("../utils/setup");
describe("Safe", async () => {
    const mockErc1155 = async () => {
        const Erc1155 = await hardhat_1.default.ethers.getContractFactory("ERC1155Token");
        return await Erc1155.deploy();
    };
    const setupWithTemplate = hardhat_1.deployments.createFixture(async ({ deployments }) => {
        await deployments.fixture();
        return {
            safe: await (0, setup_1.getSafeTemplate)(),
            token: await mockErc1155(),
        };
    });
    const [user1, user2] = hardhat_1.waffle.provider.getWallets();
    describe("ERC1155", async () => {
        it("should reject if callback not accepted", async () => {
            const { safe, token } = await setupWithTemplate();
            // Setup Safe
            await safe.setup([user1.address, user2.address], 1, constants_1.AddressZero, "0x", constants_1.AddressZero, constants_1.AddressZero, 0, constants_1.AddressZero);
            // Mint test tokens
            await token.mint(user1.address, 23, 1337, "0x");
            await (0, chai_1.expect)(await token.balanceOf(user1.address, 23)).to.be.deep.eq(ethers_1.BigNumber.from(1337));
            await (0, chai_1.expect)(token.mint(safe.address, 23, 1337, "0x"), "Should not accept minted token if handler not set").to.be.reverted;
            await (0, chai_1.expect)(token.safeTransferFrom(user1.address, safe.address, 23, 1337, "0x"), "Should not accept sent token if handler not set").to.be.reverted;
        });
        it("should not reject if callback is accepted", async () => {
            const { safe, token } = await setupWithTemplate();
            const handler = await (0, setup_1.defaultTokenCallbackHandlerDeployment)();
            // Setup Safe
            await safe.setup([user1.address, user2.address], 1, constants_1.AddressZero, "0x", handler.address, constants_1.AddressZero, 0, constants_1.AddressZero);
            await token.mint(safe.address, 23, 1337, "0x");
            await (0, chai_1.expect)(await token.balanceOf(safe.address, 23)).to.be.deep.eq(ethers_1.BigNumber.from(1337));
            await token.mint(user1.address, 23, 23, "0x");
            await (0, chai_1.expect)(await token.balanceOf(user1.address, 23)).to.be.deep.eq(ethers_1.BigNumber.from(23));
            await token.safeTransferFrom(user1.address, safe.address, 23, 23, "0x");
            await (0, chai_1.expect)(await token.balanceOf(user1.address, 23)).to.be.deep.eq(ethers_1.BigNumber.from(0));
            await (0, chai_1.expect)(await token.balanceOf(safe.address, 23)).to.be.deep.eq(ethers_1.BigNumber.from(1360));
        });
    });
});
