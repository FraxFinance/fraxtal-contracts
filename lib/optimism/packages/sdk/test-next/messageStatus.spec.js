"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const vitest_1 = require("vitest");
const src_1 = require("../src");
const ethersProviders_1 = require("./testUtils/ethersProviders");
const crossChainMessenger = new src_1.CrossChainMessenger({
    l1SignerOrProvider: ethersProviders_1.l1Provider,
    l2SignerOrProvider: ethersProviders_1.l2Provider,
    l1ChainId: 5,
    l2ChainId: 420,
    bedrock: true,
});
(0, vitest_1.describe)('getMessageStatus', () => {
    (0, vitest_1.it)(`should be able to correctly find a finalized withdrawal`, async () => {
        /**
         * Tx hash of a withdrawal
         *
         * @see https://goerli-optimism.etherscan.io/tx/0x8fb235a61079f3fa87da66e78c9da075281bc4ba5f1af4b95197dd9480e03bb5
         */
        const txWithdrawalHash = '0x8fb235a61079f3fa87da66e78c9da075281bc4ba5f1af4b95197dd9480e03bb5';
        const txReceipt = await ethersProviders_1.l2Provider.getTransactionReceipt(txWithdrawalHash);
        (0, vitest_1.expect)(txReceipt).toBeDefined();
        (0, vitest_1.expect)(await crossChainMessenger.getMessageStatus(txWithdrawalHash, 0, 9370789 - 1000, 9370789)).toBe(src_1.MessageStatus.RELAYED);
    }, 20000);
    (0, vitest_1.it)(`should return READY_FOR_RELAY if not in block range`, async () => {
        const txWithdrawalHash = '0x8fb235a61079f3fa87da66e78c9da075281bc4ba5f1af4b95197dd9480e03bb5';
        const txReceipt = await ethersProviders_1.l2Provider.getTransactionReceipt(txWithdrawalHash);
        (0, vitest_1.expect)(txReceipt).toBeDefined();
        (0, vitest_1.expect)(await crossChainMessenger.getMessageStatus(txWithdrawalHash, 0, 0, 0)).toBe(src_1.MessageStatus.READY_FOR_RELAY);
    }, 20000);
});
