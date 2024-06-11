"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.asL2Provider = exports.isL2Provider = exports.estimateTotalGasCost = exports.estimateL2GasCost = exports.estimateL1GasCost = exports.estimateL1Gas = exports.getL1GasPrice = void 0;
const transactions_1 = require("@ethersproject/transactions");
const ethers_1 = require("ethers");
const contracts_1 = require("@eth-optimism/contracts");
const cloneDeep_1 = __importDefault(require("lodash/cloneDeep"));
const assert_1 = require("./utils/assert");
const utils_1 = require("./utils");
/**
 * Gets a reasonable nonce for the transaction.
 *
 * @param provider Provider to get the nonce from.
 * @param tx Requested transaction.
 * @returns A reasonable nonce for the transaction.
 */
const getNonceForTx = async (provider, tx) => {
    if (tx.nonce !== undefined) {
        return (0, utils_1.toNumber)(tx.nonce);
    }
    else if (tx.from !== undefined) {
        return (0, utils_1.toProvider)(provider).getTransactionCount(tx.from);
    }
    else {
        // Large nonce with lots of non-zero bytes
        return 0xffffffff;
    }
};
/**
 * Returns a Contract object for the GasPriceOracle.
 *
 * @param provider Provider to attach the contract to.
 * @returns Contract object for the GasPriceOracle.
 */
const connectGasPriceOracle = (provider) => {
    return new ethers_1.Contract(contracts_1.predeploys.OVM_GasPriceOracle, (0, contracts_1.getContractInterface)('OVM_GasPriceOracle'), (0, utils_1.toProvider)(provider));
};
/**
 * Gets the current L1 gas price as seen on L2.
 *
 * @param l2Provider L2 provider to query the L1 gas price from.
 * @returns Current L1 gas price as seen on L2.
 */
const getL1GasPrice = async (l2Provider) => {
    const gpo = connectGasPriceOracle(l2Provider);
    return gpo.l1BaseFee();
};
exports.getL1GasPrice = getL1GasPrice;
/**
 * Estimates the amount of L1 gas required for a given L2 transaction.
 *
 * @param l2Provider L2 provider to query the gas usage from.
 * @param tx Transaction to estimate L1 gas for.
 * @returns Estimated L1 gas.
 */
const estimateL1Gas = async (l2Provider, tx) => {
    const gpo = connectGasPriceOracle(l2Provider);
    return gpo.getL1GasUsed((0, transactions_1.serialize)({
        to: tx.to,
        gasLimit: tx.gasLimit,
        gasPrice: tx.gasPrice,
        maxFeePerGas: tx.maxFeePerGas,
        maxPriorityFeePerGas: tx.maxPriorityFeePerGas,
        data: tx.data,
        value: tx.value,
        chainId: tx.chainId,
        type: tx.type,
        accessList: tx.accessList,
        nonce: tx.nonce
            ? ethers_1.BigNumber.from(tx.nonce).toNumber()
            : await getNonceForTx(l2Provider, tx),
    }));
};
exports.estimateL1Gas = estimateL1Gas;
/**
 * Estimates the amount of L1 gas cost for a given L2 transaction in wei.
 *
 * @param l2Provider L2 provider to query the gas usage from.
 * @param tx Transaction to estimate L1 gas cost for.
 * @returns Estimated L1 gas cost.
 */
const estimateL1GasCost = async (l2Provider, tx) => {
    const gpo = connectGasPriceOracle(l2Provider);
    return gpo.getL1Fee((0, transactions_1.serialize)({
        to: tx.to,
        gasLimit: tx.gasLimit,
        gasPrice: tx.gasPrice,
        maxFeePerGas: tx.maxFeePerGas,
        maxPriorityFeePerGas: tx.maxPriorityFeePerGas,
        data: tx.data,
        value: tx.value,
        chainId: tx.chainId,
        type: tx.type,
        accessList: tx.accessList,
        nonce: tx.nonce
            ? ethers_1.BigNumber.from(tx.nonce).toNumber()
            : await getNonceForTx(l2Provider, tx),
    }));
};
exports.estimateL1GasCost = estimateL1GasCost;
/**
 * Estimates the L2 gas cost for a given L2 transaction in wei.
 *
 * @param l2Provider L2 provider to query the gas usage from.
 * @param tx Transaction to estimate L2 gas cost for.
 * @returns Estimated L2 gas cost.
 */
const estimateL2GasCost = async (l2Provider, tx) => {
    const parsed = (0, utils_1.toProvider)(l2Provider);
    const l2GasPrice = await parsed.getGasPrice();
    const l2GasCost = await parsed.estimateGas(tx);
    return l2GasPrice.mul(l2GasCost);
};
exports.estimateL2GasCost = estimateL2GasCost;
/**
 * Estimates the total gas cost for a given L2 transaction in wei.
 *
 * @param l2Provider L2 provider to query the gas usage from.
 * @param tx Transaction to estimate total gas cost for.
 * @returns Estimated total gas cost.
 */
const estimateTotalGasCost = async (l2Provider, tx) => {
    const l1GasCost = await (0, exports.estimateL1GasCost)(l2Provider, tx);
    const l2GasCost = await (0, exports.estimateL2GasCost)(l2Provider, tx);
    return l1GasCost.add(l2GasCost);
};
exports.estimateTotalGasCost = estimateTotalGasCost;
/**
 * Determines if a given Provider is an L2Provider.  Will coerce type
 * if true
 *
 * @param provider The provider to check
 * @returns Boolean
 * @example
 * if (isL2Provider(provider)) {
 *   // typescript now knows it is of type L2Provider
 *   const gasPrice = await provider.estimateL2GasPrice(tx)
 * }
 */
const isL2Provider = (provider) => {
    return Boolean(provider._isL2Provider);
};
exports.isL2Provider = isL2Provider;
/**
 * Returns an provider wrapped as an Optimism L2 provider. Adds a few extra helper functions to
 * simplify the process of estimating the gas usage for a transaction on Optimism. Returns a COPY
 * of the original provider.
 *
 * @param provider Provider to wrap into an L2 provider.
 * @returns Provider wrapped as an L2 provider.
 */
const asL2Provider = (provider) => {
    // Skip if we've already wrapped this provider.
    if ((0, exports.isL2Provider)(provider)) {
        return provider;
    }
    // Make a copy of the provider since we'll be modifying some internals and don't want to mess
    // with the original object.
    const l2Provider = (0, cloneDeep_1.default)(provider);
    // Not exactly sure when the provider wouldn't have a formatter function, but throw an error if
    // it doesn't have one. The Provider type doesn't define it but every provider I've dealt with
    // seems to have it.
    // TODO this may be fixed if library has gotten updated since
    const formatter = l2Provider.formatter;
    (0, assert_1.assert)(formatter, `provider.formatter must be defined`);
    // Modify the block formatter to return the state root. Not strictly related to Optimism, just a
    // generally useful thing that really should've been on the Ethers block object to begin with.
    // TODO: Maybe we should make a PR to add this to the Ethers library?
    const ogBlockFormatter = formatter.block.bind(formatter);
    formatter.block = (block) => {
        const parsed = ogBlockFormatter(block);
        parsed.stateRoot = block.stateRoot;
        return parsed;
    };
    // Modify the block formatter to include all the L2 fields for transactions.
    const ogBlockWithTxFormatter = formatter.blockWithTransactions.bind(formatter);
    formatter.blockWithTransactions = (block) => {
        const parsed = ogBlockWithTxFormatter(block);
        parsed.stateRoot = block.stateRoot;
        parsed.transactions = parsed.transactions.map((tx, idx) => {
            const ogTx = block.transactions[idx];
            tx.l1BlockNumber = ogTx.l1BlockNumber
                ? (0, utils_1.toNumber)(ogTx.l1BlockNumber)
                : ogTx.l1BlockNumber;
            tx.l1Timestamp = ogTx.l1Timestamp
                ? (0, utils_1.toNumber)(ogTx.l1Timestamp)
                : ogTx.l1Timestamp;
            tx.l1TxOrigin = ogTx.l1TxOrigin;
            tx.queueOrigin = ogTx.queueOrigin;
            tx.rawTransaction = ogTx.rawTransaction;
            return tx;
        });
        return parsed;
    };
    // Modify the transaction formatter to include all the L2 fields for transactions.
    const ogTxResponseFormatter = formatter.transactionResponse.bind(formatter);
    formatter.transactionResponse = (tx) => {
        const parsed = ogTxResponseFormatter(tx);
        parsed.txType = tx.txType;
        parsed.queueOrigin = tx.queueOrigin;
        parsed.rawTransaction = tx.rawTransaction;
        parsed.l1TxOrigin = tx.l1TxOrigin;
        parsed.l1BlockNumber = tx.l1BlockNumber
            ? parseInt(tx.l1BlockNumber, 16)
            : tx.l1BlockNumbers;
        return parsed;
    };
    // Modify the receipt formatter to include all the L2 fields.
    const ogReceiptFormatter = formatter.receipt.bind(formatter);
    formatter.receipt = (receipt) => {
        const parsed = ogReceiptFormatter(receipt);
        parsed.l1GasPrice = (0, utils_1.toBigNumber)(receipt.l1GasPrice);
        parsed.l1GasUsed = (0, utils_1.toBigNumber)(receipt.l1GasUsed);
        parsed.l1Fee = (0, utils_1.toBigNumber)(receipt.l1Fee);
        parsed.l1FeeScalar = parseFloat(receipt.l1FeeScalar);
        return parsed;
    };
    // Connect extra functions.
    l2Provider.getL1GasPrice = async () => {
        return (0, exports.getL1GasPrice)(l2Provider);
    };
    l2Provider.estimateL1Gas = async (tx) => {
        return (0, exports.estimateL1Gas)(l2Provider, tx);
    };
    l2Provider.estimateL1GasCost = async (tx) => {
        return (0, exports.estimateL1GasCost)(l2Provider, tx);
    };
    l2Provider.estimateL2GasCost = async (tx) => {
        return (0, exports.estimateL2GasCost)(l2Provider, tx);
    };
    l2Provider.estimateTotalGasCost = async (tx) => {
        return (0, exports.estimateTotalGasCost)(l2Provider, tx);
    };
    l2Provider._isL2Provider = true;
    return l2Provider;
};
exports.asL2Provider = asL2Provider;
