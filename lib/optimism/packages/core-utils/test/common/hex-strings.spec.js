"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const bignumber_1 = require("@ethersproject/bignumber");
/* Imports: Internal */
const setup_1 = require("../setup");
const src_1 = require("../../src");
describe('remove0x', () => {
    it('should return undefined', () => {
        (0, setup_1.expect)((0, src_1.remove0x)(undefined)).to.deep.equal(undefined);
    });
    it('should return without a 0x', () => {
        const cases = [
            { input: '0x', output: '' },
            {
                input: '0x1f9840a85d5af5bf1d1762f925bdaddc4201f984',
                output: '1f9840a85d5af5bf1d1762f925bdaddc4201f984',
            },
            { input: 'a', output: 'a' },
        ];
        for (const test of cases) {
            (0, setup_1.expect)((0, src_1.remove0x)(test.input)).to.deep.equal(test.output);
        }
    });
});
describe('add0x', () => {
    it('should return undefined', () => {
        (0, setup_1.expect)((0, src_1.add0x)(undefined)).to.deep.equal(undefined);
    });
    it('should return with a 0x', () => {
        const cases = [
            { input: '0x', output: '0x' },
            {
                input: '1f9840a85d5af5bf1d1762f925bdaddc4201f984',
                output: '0x1f9840a85d5af5bf1d1762f925bdaddc4201f984',
            },
            { input: '', output: '0x' },
        ];
        for (const test of cases) {
            (0, setup_1.expect)((0, src_1.add0x)(test.input)).to.deep.equal(test.output);
        }
    });
});
describe('toHexString', () => {
    it('should throw an error when input is null', () => {
        (0, setup_1.expect)(() => {
            (0, src_1.toHexString)(null);
        }).to.throw('The first argument must be of type string or an instance of Buffer, ArrayBuffer, or Array or an Array-like Object. Received null');
    });
    it('should return with a hex string', () => {
        const cases = [
            { input: 0, output: '0x00' },
            { input: 48, output: '0x30' },
            {
                input: '0',
                output: '0x30',
            },
            { input: '', output: '0x' },
        ];
        for (const test of cases) {
            (0, setup_1.expect)((0, src_1.toHexString)(test.input)).to.deep.equal(test.output);
        }
    });
});
describe('fromHexString', () => {
    it('should return a buffer from a hex string', () => {
        const cases = [
            { input: '0x', output: Buffer.from('', 'hex') },
            {
                input: '0x1f9840a85d5af5bf1d1762f925bdaddc4201f984',
                output: Buffer.from('1f9840a85d5af5bf1d1762f925bdaddc4201f984', 'hex'),
            },
            { input: '', output: Buffer.from('', 'hex') },
            {
                input: Buffer.from('1f9840a85d5af5bf1d1762f925bdaddc4201f984'),
                output: Buffer.from('1f9840a85d5af5bf1d1762f925bdaddc4201f984'),
            },
        ];
        for (const test of cases) {
            (0, setup_1.expect)((0, src_1.fromHexString)(test.input)).to.deep.equal(test.output);
        }
    });
});
describe('padHexString', () => {
    it('should return return input string if length is 2 + length * 2', () => {
        (0, setup_1.expect)((0, src_1.padHexString)('abcd', 1)).to.deep.equal('abcd');
        (0, setup_1.expect)((0, src_1.padHexString)('abcdefgh', 3).length).to.deep.equal(8);
    });
    it('should return a string padded with 0x and zeros', () => {
        (0, setup_1.expect)((0, src_1.padHexString)('0xabcd', 3)).to.deep.equal('0x00abcd');
    });
});
describe('toRpcHexString', () => {
    it('should parse 0', () => {
        (0, setup_1.expect)((0, src_1.toRpcHexString)(0)).to.deep.equal('0x0');
        (0, setup_1.expect)((0, src_1.toRpcHexString)(bignumber_1.BigNumber.from(0))).to.deep.equal('0x0');
    });
    it('should parse non 0', () => {
        const cases = [
            { input: 2, output: '0x2' },
            { input: bignumber_1.BigNumber.from(2), output: '0x2' },
            { input: 100, output: '0x64' },
            { input: bignumber_1.BigNumber.from(100), output: '0x64' },
            { input: 300, output: '0x12c' },
            { input: bignumber_1.BigNumber.from(300), output: '0x12c' },
        ];
        for (const test of cases) {
            (0, setup_1.expect)((0, src_1.toRpcHexString)(test.input)).to.deep.equal(test.output);
        }
    });
});
describe('encodeHex', () => {
    it('should throw an error when val is invalid', () => {
        (0, setup_1.expect)(() => {
            (0, src_1.encodeHex)(null, 0);
        }).to.throw('invalid BigNumber value');
        (0, setup_1.expect)(() => {
            (0, src_1.encodeHex)(10.5, 0);
        }).to.throw('fault="underflow", operation="BigNumber.from", value=10.5');
        (0, setup_1.expect)(() => {
            (0, src_1.encodeHex)('10.5', 0);
        }).to.throw('invalid BigNumber string');
    });
    it('should return a hex string of val with length len', () => {
        const cases = [
            {
                input: {
                    val: 0,
                    len: 0,
                },
                output: '00',
            },
            {
                input: {
                    val: 0,
                    len: 4,
                },
                output: '0000',
            },
            {
                input: {
                    val: 1,
                    len: 0,
                },
                output: '01',
            },
            {
                input: {
                    val: 1,
                    len: 10,
                },
                output: '0000000001',
            },
            {
                input: {
                    val: 100,
                    len: 4,
                },
                output: '0064',
            },
            {
                input: {
                    val: '100',
                    len: 0,
                },
                output: '64',
            },
        ];
        for (const test of cases) {
            (0, setup_1.expect)((0, src_1.encodeHex)(test.input.val, test.input.len)).to.deep.equal(test.output);
        }
    });
});
describe('hexStringEquals', () => {
    it('should throw an error when input is not a hex string', () => {
        (0, setup_1.expect)(() => {
            (0, src_1.hexStringEquals)('', '');
        }).to.throw('input is not a hex string: ');
        (0, setup_1.expect)(() => {
            (0, src_1.hexStringEquals)('0xx', '0x1');
        }).to.throw('input is not a hex string: 0xx');
        (0, setup_1.expect)(() => {
            (0, src_1.hexStringEquals)('0x1', '2');
        }).to.throw('input is not a hex string: 2');
        (0, setup_1.expect)(() => {
            (0, src_1.hexStringEquals)('-0x1', '0x1');
        }).to.throw('input is not a hex string: -0x1');
    });
    it('should return the hex strings equality', () => {
        const cases = [
            {
                input: {
                    stringA: '0x',
                    stringB: '0x',
                },
                output: true,
            },
            {
                input: {
                    stringA: '0x1',
                    stringB: '0x1',
                },
                output: true,
            },
            {
                input: {
                    stringA: '0x064',
                    stringB: '0x064',
                },
                output: true,
            },
            {
                input: {
                    stringA: '0x',
                    stringB: '0x0',
                },
                output: false,
            },
            {
                input: {
                    stringA: '0x0',
                    stringB: '0x1',
                },
                output: false,
            },
            {
                input: {
                    stringA: '0x64',
                    stringB: '0x064',
                },
                output: false,
            },
        ];
        for (const test of cases) {
            (0, setup_1.expect)((0, src_1.hexStringEquals)(test.input.stringA, test.input.stringB)).to.deep.equal(test.output);
        }
    });
});
describe('bytes32ify', () => {
    it('should throw an error when input is invalid', () => {
        (0, setup_1.expect)(() => {
            (0, src_1.bytes32ify)(-1);
        }).to.throw('invalid hex string');
    });
    it('should return a zero padded, 32 bytes hex string', () => {
        const cases = [
            {
                input: 0,
                output: '0x0000000000000000000000000000000000000000000000000000000000000000',
            },
            {
                input: bignumber_1.BigNumber.from(0),
                output: '0x0000000000000000000000000000000000000000000000000000000000000000',
            },
            {
                input: 2,
                output: '0x0000000000000000000000000000000000000000000000000000000000000002',
            },
            {
                input: bignumber_1.BigNumber.from(2),
                output: '0x0000000000000000000000000000000000000000000000000000000000000002',
            },
            {
                input: 100,
                output: '0x0000000000000000000000000000000000000000000000000000000000000064',
            },
        ];
        for (const test of cases) {
            (0, setup_1.expect)((0, src_1.bytes32ify)(test.input)).to.deep.equal(test.output);
        }
    });
});
