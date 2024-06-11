"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const chai_1 = require("chai");
const hardhat_1 = require("hardhat");
require("@nomiclabs/hardhat-ethers");
const constants_1 = require("@ethersproject/constants");
const setup_1 = require("../utils/setup");
describe("TokenCallbackHandler", async () => {
    beforeEach(async () => {
        await hardhat_1.deployments.fixture();
    });
    describe("ERC1155", async () => {
        it("should support ERC1155 interface", async () => {
            const handler = await (0, setup_1.getTokenCallbackHandler)();
            await (0, chai_1.expect)(await handler.callStatic.supportsInterface("0x4e2312e0")).to.be.eq(true);
        });
        it("to handle onERC1155Received", async () => {
            const handler = await (0, setup_1.getTokenCallbackHandler)();
            await (0, chai_1.expect)(await handler.callStatic.onERC1155Received(constants_1.AddressZero, constants_1.AddressZero, 0, 0, "0x")).to.be.eq("0xf23a6e61");
        });
        it("to handle onERC1155BatchReceived", async () => {
            const handler = await (0, setup_1.getTokenCallbackHandler)();
            await (0, chai_1.expect)(await handler.callStatic.onERC1155BatchReceived(constants_1.AddressZero, constants_1.AddressZero, [], [], "0x")).to.be.eq("0xbc197c81");
        });
    });
    describe("ERC721", async () => {
        it("should support ERC721 interface", async () => {
            const handler = await (0, setup_1.getTokenCallbackHandler)();
            await (0, chai_1.expect)(await handler.callStatic.supportsInterface("0x150b7a02")).to.be.eq(true);
        });
        it("to handle onERC721Received", async () => {
            const handler = await (0, setup_1.getTokenCallbackHandler)();
            await (0, chai_1.expect)(await handler.callStatic.onERC721Received(constants_1.AddressZero, constants_1.AddressZero, 0, "0x")).to.be.eq("0x150b7a02");
        });
    });
    describe("ERC777", async () => {
        it("to handle tokensReceived", async () => {
            const handler = await (0, setup_1.getTokenCallbackHandler)();
            await handler.callStatic.tokensReceived(constants_1.AddressZero, constants_1.AddressZero, constants_1.AddressZero, 0, "0x", "0x");
        });
    });
    describe("ERC165", async () => {
        it("should support ERC165 interface", async () => {
            const handler = await (0, setup_1.getTokenCallbackHandler)();
            await (0, chai_1.expect)(await handler.callStatic.supportsInterface("0x01ffc9a7")).to.be.eq(true);
        });
        it("should not support random interface", async () => {
            const handler = await (0, setup_1.getTokenCallbackHandler)();
            await (0, chai_1.expect)(await handler.callStatic.supportsInterface("0xbaddad42")).to.be.eq(false);
        });
        it("should not support invalid interface", async () => {
            const handler = await (0, setup_1.getTokenCallbackHandler)();
            await (0, chai_1.expect)(await handler.callStatic.supportsInterface("0xffffffff")).to.be.eq(false);
        });
    });
});
