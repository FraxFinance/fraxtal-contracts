"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.undoL1ToL2Alias = exports.applyL1ToL2Alias = exports.L1_TO_L2_ALIAS_OFFSET = void 0;
const address_1 = require("@ethersproject/address");
const bignumber_1 = require("@ethersproject/bignumber");
const common_1 = require("../common");
// Constant representing the alias to apply to the msg.sender when a contract sends an L1 => L2
// message. We need this aliasing scheme because a contract can be deployed to the same address
// on both L1 and L2 but with different bytecode (address is not dependent on bytecode when using
// the standard CREATE opcode). We want to treat L1 contracts as having a different address while
// still making it possible for L2 contracts to easily reverse the aliasing scheme and figure out
// the real address of the contract that sent the L1 => L2 message.
exports.L1_TO_L2_ALIAS_OFFSET = '0x1111000000000000000000000000000000001111';
/**
 * Applies the L1 => L2 aliasing scheme to an address.
 *
 * @param address Address to apply the scheme to.
 * @returns Address with the scheme applied.
 */
const applyL1ToL2Alias = (address) => {
    if (!(0, address_1.isAddress)(address)) {
        throw new Error(`not a valid address: ${address}`);
    }
    return (0, common_1.bnToAddress)(bignumber_1.BigNumber.from(address).add(exports.L1_TO_L2_ALIAS_OFFSET));
};
exports.applyL1ToL2Alias = applyL1ToL2Alias;
/**
 * Reverses the L1 => L2 aliasing scheme from an address.
 *
 * @param address Address to reverse the scheme from.
 * @returns Alias with the scheme reversed.
 */
const undoL1ToL2Alias = (address) => {
    if (!(0, address_1.isAddress)(address)) {
        throw new Error(`not a valid address: ${address}`);
    }
    return (0, common_1.bnToAddress)(bignumber_1.BigNumber.from(address).sub(exports.L1_TO_L2_ALIAS_OFFSET));
};
exports.undoL1ToL2Alias = undoL1ToL2Alias;
