"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.bnToAddress = void 0;
const bignumber_1 = require("@ethersproject/bignumber");
const address_1 = require("@ethersproject/address");
const hex_strings_1 = require("./hex-strings");
/**
 * Converts an ethers BigNumber into an equivalent Ethereum address representation.
 *
 * @param bn BigNumber to convert to an address.
 * @return BigNumber converted to an address, represented as a hex string.
 */
const bnToAddress = (bn) => {
    // Coerce numbers into a BigNumber.
    bn = bignumber_1.BigNumber.from(bn);
    // Negative numbers are converted to addresses by adding MAX_ADDRESS + 1.
    // TODO: Explain this in more detail, it's basically just matching the behavior of doing
    // addr(uint256(addr) - some_number) in Solidity where some_number > uint256(addr).
    if (bn.isNegative()) {
        bn = bignumber_1.BigNumber.from('0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF')
            .add(bn)
            .add(1);
    }
    // Convert to a hex string
    let addr = bn.toHexString();
    // Remove leading 0x so we can mutate the address a bit
    addr = (0, hex_strings_1.remove0x)(addr);
    // Make sure it's 40 characters (= 20 bytes)
    addr = addr.padStart(40, '0');
    // Only take the last 40 characters (= 20 bytes)
    addr = addr.slice(addr.length - 40, addr.length);
    // Add 0x again
    addr = (0, hex_strings_1.add0x)(addr);
    // Convert into a checksummed address
    addr = (0, address_1.getAddress)(addr);
    return addr;
};
exports.bnToAddress = bnToAddress;
