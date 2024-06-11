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
const execution_1 = require("../../src/utils/execution");
describe("FallbackManager", async () => {
    const setupWithTemplate = hardhat_1.deployments.createFixture(async ({ deployments }) => {
        await deployments.fixture();
        const source = `
        contract Mirror {
            function lookAtMe() public returns (bytes memory) {
                return msg.data;
            }

            function nowLookAtYou(address you, string memory howYouLikeThat) public returns (bytes memory) {
                return msg.data;
            }
        }`;
        const mirror = await (0, setup_1.deployContract)(user1, source);
        return {
            safe: await (0, setup_1.getSafeTemplate)(),
            mirror,
        };
    });
    const [user1, user2] = hardhat_1.waffle.provider.getWallets();
    describe("setFallbackManager", async () => {
        it("is correctly set on deployment", async () => {
            const { safe } = await setupWithTemplate();
            const handler = await (0, setup_1.defaultTokenCallbackHandlerDeployment)();
            // Check fallback handler
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getStorageAt(safe.address, "0x6c9a6c4a39284e37ed1cf53d337577d14212a4870fb976a4366c693b939918d5")).to.be.eq("0x" + "".padStart(64, "0"));
            // Setup Safe
            await safe.setup([user1.address, user2.address], 1, constants_1.AddressZero, "0x", handler.address, constants_1.AddressZero, 0, constants_1.AddressZero);
            // Check fallback handler
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getStorageAt(safe.address, "0x6c9a6c4a39284e37ed1cf53d337577d14212a4870fb976a4366c693b939918d5")).to.be.eq("0x" + handler.address.toLowerCase().slice(2).padStart(64, "0"));
        });
        it("is correctly set", async () => {
            const { safe } = await setupWithTemplate();
            const handler = await (0, setup_1.defaultTokenCallbackHandlerDeployment)();
            // Setup Safe
            await safe.setup([user1.address, user2.address], 1, constants_1.AddressZero, "0x", constants_1.AddressZero, constants_1.AddressZero, 0, constants_1.AddressZero);
            // Check fallback handler
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getStorageAt(safe.address, "0x6c9a6c4a39284e37ed1cf53d337577d14212a4870fb976a4366c693b939918d5")).to.be.eq("0x" + "".padStart(64, "0"));
            await (0, chai_1.expect)((0, execution_1.executeContractCallWithSigners)(safe, safe, "setFallbackHandler", [handler.address], [user1]))
                .to.emit(safe, "ChangedFallbackHandler")
                .withArgs(handler.address);
            // Check fallback handler
            await (0, chai_1.expect)(await hardhat_1.default.ethers.provider.getStorageAt(safe.address, "0x6c9a6c4a39284e37ed1cf53d337577d14212a4870fb976a4366c693b939918d5")).to.be.eq("0x" + handler.address.toLowerCase().slice(2).padStart(64, "0"));
        });
        it("emits event when is set", async () => {
            const { safe } = await setupWithTemplate();
            const handler = await (0, setup_1.defaultTokenCallbackHandlerDeployment)();
            // Setup Safe
            await safe.setup([user1.address, user2.address], 1, constants_1.AddressZero, "0x", constants_1.AddressZero, constants_1.AddressZero, 0, constants_1.AddressZero);
            // Check event
            await (0, chai_1.expect)((0, execution_1.executeContractCallWithSigners)(safe, safe, "setFallbackHandler", [handler.address], [user1]))
                .to.emit(safe, "ChangedFallbackHandler")
                .withArgs(handler.address);
        });
        it("is called when set", async () => {
            const { safe } = await setupWithTemplate();
            const handler = await (0, setup_1.defaultTokenCallbackHandlerDeployment)();
            const safeHandler = (await (0, setup_1.defaultTokenCallbackHandlerContract)()).attach(safe.address);
            // Check that Safe is NOT setup
            await (0, chai_1.expect)(await safe.getThreshold()).to.be.deep.eq(ethers_1.BigNumber.from(0));
            // Check unset callbacks
            await (0, chai_1.expect)(safeHandler.callStatic.onERC1155Received(constants_1.AddressZero, constants_1.AddressZero, 0, 0, "0x")).to.be.reverted;
            // Setup Safe
            await safe.setup([user1.address, user2.address], 1, constants_1.AddressZero, "0x", handler.address, constants_1.AddressZero, 0, constants_1.AddressZero);
            // Check callbacks
            await (0, chai_1.expect)(await safeHandler.callStatic.onERC1155Received(constants_1.AddressZero, constants_1.AddressZero, 0, 0, "0x")).to.be.eq("0xf23a6e61");
        });
        it("sends along msg.sender on simple call", async () => {
            const { safe, mirror } = await setupWithTemplate();
            // Setup Safe
            await safe.setup([user1.address, user2.address], 1, constants_1.AddressZero, "0x", mirror.address, constants_1.AddressZero, 0, constants_1.AddressZero);
            const tx = {
                to: safe.address,
                data: mirror.interface.encodeFunctionData("lookAtMe"),
            };
            // Check that mock works as handler
            const response = await user1.call(tx);
            (0, chai_1.expect)(response).to.be.eq("0x" +
                "0000000000000000000000000000000000000000000000000000000000000020" +
                "0000000000000000000000000000000000000000000000000000000000000018" +
                "7f8dc53c" +
                user1.address.slice(2).toLowerCase() +
                "0000000000000000");
        });
        it("sends along msg.sender on more complex call", async () => {
            const { safe, mirror } = await setupWithTemplate();
            // Setup Safe
            await safe.setup([user1.address, user2.address], 1, constants_1.AddressZero, "0x", mirror.address, constants_1.AddressZero, 0, constants_1.AddressZero);
            const tx = {
                to: safe.address,
                data: mirror.interface.encodeFunctionData("nowLookAtYou", [user2.address, "pink<>black"]),
            };
            // Check that mock works as handler
            const response = await user1.call(tx);
            (0, chai_1.expect)(response).to.be.eq("0x" +
                "0000000000000000000000000000000000000000000000000000000000000020" +
                "0000000000000000000000000000000000000000000000000000000000000098" +
                // Function call
                "b2a88d99" +
                "000000000000000000000000" +
                user2.address.slice(2).toLowerCase() +
                "0000000000000000000000000000000000000000000000000000000000000040" +
                "000000000000000000000000000000000000000000000000000000000000000b" +
                "70696e6b3c3e626c61636b000000000000000000000000000000000000000000" +
                user1.address.slice(2).toLowerCase() +
                "0000000000000000");
        });
        it("cannot be set to self", async () => {
            const { safe } = await setupWithTemplate();
            // Setup Safe
            await safe.setup([user1.address], 1, constants_1.AddressZero, "0x", constants_1.AddressZero, constants_1.AddressZero, 0, constants_1.AddressZero);
            // The transaction execution function doesn't bubble up revert messages so we check for a generic transaction fail code GS013
            await (0, chai_1.expect)((0, execution_1.executeContractCallWithSigners)(safe, safe, "setFallbackHandler", [safe.address], [user1])).to.be.revertedWith("GS013");
        });
    });
});
