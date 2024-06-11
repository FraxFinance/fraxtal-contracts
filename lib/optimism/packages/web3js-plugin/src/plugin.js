import Web3, { BlockTags, Contract, DEFAULT_RETURN_FORMAT, FMT_BYTES, FMT_NUMBER, Web3PluginBase, } from 'web3';
import { TransactionFactory } from 'web3-eth-accounts';
import { estimateGas, formatTransaction } from 'web3-eth';
import { gasPriceOracleABI, gasPriceOracleAddress, } from '@eth-optimism/contracts-ts';
import { RLP } from '@ethereumjs/rlp';
export class OptimismPlugin extends Web3PluginBase {
    pluginNamespace = 'op';
    _gasPriceOracleContract;
    /**
     * Retrieves the current L2 base fee
     * @param {DataFormat} [returnFormat=DEFAULT_RETURN_FORMAT] - The web3.js format object that specifies how to format number and bytes values
     * @returns {Promise<bigint>} - The L2 base fee as a BigInt by default, but {returnFormat} determines type
     * @example
     * const baseFeeValue: bigint = await web3.op.getBaseFee();
     * @example
     * const numberFormat = { number: FMT_NUMBER.NUMBER, bytes: FMT_BYTES.HEX }
     * const baseFeeValue: number = await web3.op.getBaseFee(numberFormat);
     */
    async getBaseFee(returnFormat) {
        return Web3.utils.format({ format: 'uint' }, await this._getPriceOracleContractInstance().methods.baseFee().call(), returnFormat ?? DEFAULT_RETURN_FORMAT);
    }
    /**
     * Retrieves the decimals used in the scalar
     * @param {DataFormat} [returnFormat=DEFAULT_RETURN_FORMAT] - The web3.js format object that specifies how to format number and bytes values
     * @returns {Promise<Numbers>} - The number of decimals as a BigInt by default, but {returnFormat} determines type
     * @example
     * const decimalsValue: bigint = await web3.op.getDecimals();
     * @example
     * const numberFormat = { number: FMT_NUMBER.NUMBER, bytes: FMT_BYTES.HEX }
     * const decimalsValue: number = await web3.op.getDecimals(numberFormat);
     */
    async getDecimals(returnFormat) {
        return Web3.utils.format({ format: 'uint' }, await this._getPriceOracleContractInstance().methods.decimals().call(), returnFormat ?? DEFAULT_RETURN_FORMAT);
    }
    /**
     * Retrieves the current L2 gas price (base fee)
     * @param {DataFormat} [returnFormat=DEFAULT_RETURN_FORMAT] - The web3.js format object that specifies how to format number and bytes values
     * @returns {Promise<Numbers>} - The current L2 gas price as a BigInt by default, but {returnFormat} determines type
     * @example
     * const gasPriceValue: bigint = await web3.op.getGasPrice();
     * @example
     * const numberFormat = { number: FMT_NUMBER.NUMBER, bytes: FMT_BYTES.HEX }
     * const gasPriceValue: number = await web3.op.getGasPrice(numberFormat);
     */
    async getGasPrice(returnFormat) {
        return Web3.utils.format({ format: 'uint' }, await this._getPriceOracleContractInstance().methods.gasPrice().call(), returnFormat ?? DEFAULT_RETURN_FORMAT);
    }
    /**
     * Computes the L1 portion of the fee based on the size of the rlp encoded input
     * transaction, the current L1 base fee, and the various dynamic parameters
     * @param transaction - An unsigned web3.js {Transaction} object
     * @param {DataFormat} [returnFormat=DEFAULT_RETURN_FORMAT] - The web3.js format object that specifies how to format number and bytes values
     * @returns {Promise<Numbers>} - The fee as a BigInt by default, but {returnFormat} determines type
     * @example
     * const l1FeeValue: bigint = await getL1Fee(transaction);
     * @example
     * const numberFormat = { number: FMT_NUMBER.NUMBER, bytes: FMT_BYTES.HEX }
     * const l1FeeValue: number = await getL1Fee(transaction, numberFormat);
     */
    async getL1Fee(transaction, returnFormat) {
        return Web3.utils.format({ format: 'uint' }, await this._getPriceOracleContractInstance()
            .methods.getL1Fee(this._serializeTransaction(transaction))
            .call(), returnFormat ?? DEFAULT_RETURN_FORMAT);
    }
    /**
     * Computes the amount of L1 gas used for {transaction}. Adds the overhead which
     * represents the per-transaction gas overhead of posting the {transaction} and state
     * roots to L1. Adds 68 bytes of padding to account for the fact that the input does
     * not have a signature.
     * @param transaction - An unsigned web3.js {Transaction} object
     * @param {DataFormat} [returnFormat=DEFAULT_RETURN_FORMAT] - The web3.js format object that specifies how to format number and bytes values
     * @returns {Promise<Numbers>} - The amount gas as a BigInt by default, but {returnFormat} determines type
     * @example
     * const gasUsedValue: bigint = await getL1GasUsed(transaction);
     * @example
     * const numberFormat = { number: FMT_NUMBER.NUMBER, bytes: FMT_BYTES.HEX }
     * const gasUsedValue: number = await getL1GasUsed(transaction, numberFormat);
     */
    async getL1GasUsed(transaction, returnFormat) {
        return Web3.utils.format({ format: 'uint' }, await this._getPriceOracleContractInstance()
            .methods.getL1GasUsed(this._serializeTransaction(transaction))
            .call(), returnFormat ?? DEFAULT_RETURN_FORMAT);
    }
    /**
     * Retrieves the latest known L1 base fee
     * @param {DataFormat} [returnFormat=DEFAULT_RETURN_FORMAT] - The web3.js format object that specifies how to format number and bytes values
     * @returns {Promise<Numbers>} - The L1 base fee as a BigInt by default, but {returnFormat} determines type
     * @example
     * const baseFeeValue: bigint = await web3.op.getL1BaseFee();
     * @example
     * const numberFormat = { number: FMT_NUMBER.NUMBER, bytes: FMT_BYTES.HEX }
     * const baseFeeValue: number = await web3.op.getL1BaseFee(numberFormat);
     */
    async getL1BaseFee(returnFormat) {
        return Web3.utils.format({ format: 'uint' }, await this._getPriceOracleContractInstance().methods.l1BaseFee().call(), returnFormat ?? DEFAULT_RETURN_FORMAT);
    }
    /**
     * Retrieves the current fee overhead
     * @param {DataFormat} [returnFormat=DEFAULT_RETURN_FORMAT] - The web3.js format object that specifies how to format number and bytes values
     * @returns {Promise<Numbers>} - The current overhead fee as a BigInt by default, but {returnFormat} determines type
     * @example
     * const overheadValue: bigint = await web3.op.getOverhead();
     * @example
     * const numberFormat = { number: FMT_NUMBER.NUMBER, bytes: FMT_BYTES.HEX }
     * const overheadValue: number = await web3.op.getOverhead(numberFormat);
     */
    async getOverhead(returnFormat) {
        return Web3.utils.format({ format: 'uint' }, await this._getPriceOracleContractInstance().methods.overhead().call(), returnFormat ?? DEFAULT_RETURN_FORMAT);
    }
    /**
     * Retrieves the current fee scalar
     * @param {DataFormat} [returnFormat=DEFAULT_RETURN_FORMAT] - The web3.js format object that specifies how to format number and bytes values
     * @returns {Promise<Numbers>} - The current scalar fee as a BigInt by default, but {returnFormat} determines type
     * @example
     * const scalarValue: bigint = await web3.op.getScalar();
     * @example
     * const numberFormat = { number: FMT_NUMBER.NUMBER, bytes: FMT_BYTES.HEX }
     * const scalarValue: number = await web3.op.getScalar(numberFormat);
     */
    async getScalar(returnFormat) {
        return Web3.utils.format({ format: 'uint' }, await this._getPriceOracleContractInstance().methods.scalar().call(), returnFormat ?? DEFAULT_RETURN_FORMAT);
    }
    /**
     * Retrieves the full semver version of GasPriceOracle
     * @returns {Promise<string>} - The semver version
     * @example
     * const version = await web3.op.getVersion();
     */
    async getVersion() {
        return this._getPriceOracleContractInstance().methods.version().call();
    }
    /**
     * Retrieves the amount of L2 gas estimated to execute {transaction}
     * @param transaction - An unsigned web3.js {Transaction} object
     * @param {{ blockNumber: BlockNumberOrTag, returnFormat: DataFormat }} [options={blockNumber: BlockTags.LATEST, returnFormat: DEFAULT_RETURN_FORMAT}] -
     * An options object specifying what block to use for gas estimates and the web3.js format object that specifies how to format number and bytes values
     * @returns {Promise<Numbers>} - The gas estimate as a BigInt by default, but {returnFormat} determines type
     * @example
     * const l2Fee: bigint = await getL2Fee(transaction);
     * @example
     * const numberFormat = { number: FMT_NUMBER.NUMBER, bytes: FMT_BYTES.HEX }
     * const l2Fee: number = await getL2Fee(transaction, numberFormat);
     */
    async getL2Fee(transaction, options) {
        const [gasCost, gasPrice] = await Promise.all([
            estimateGas(this, transaction, options?.blockNumber ?? BlockTags.LATEST, DEFAULT_RETURN_FORMAT),
            this.getGasPrice(),
        ]);
        return Web3.utils.format({ format: 'uint' }, gasCost * gasPrice, options?.returnFormat ?? DEFAULT_RETURN_FORMAT);
    }
    /**
     * Computes the total (L1 + L2) fee estimate to execute {transaction}
     * @param transaction - An unsigned web3.js {Transaction} object
     * @param {DataFormat} [returnFormat=DEFAULT_RETURN_FORMAT] - The web3.js format object that specifies how to format number and bytes values
     * @returns {Promise<Numbers>} - The estimated total fee as a BigInt by default, but {returnFormat} determines type
     * @example
     * const estimatedFees: bigint = await estimateFees(transaction);
     * @example
     * const numberFormat = { number: FMT_NUMBER.NUMBER, bytes: FMT_BYTES.HEX }
     * const estimatedFees: number = await estimateFees(transaction, numberFormat);
     */
    async estimateFees(transaction, returnFormat) {
        const [l1Fee, l2Fee] = await Promise.all([
            this.getL1Fee(transaction),
            this.getL2Fee(transaction),
        ]);
        return Web3.utils.format({ format: 'uint' }, l1Fee + l2Fee, returnFormat ?? DEFAULT_RETURN_FORMAT);
    }
    /**
     * Used to get the web3.js contract instance for gas price oracle contract
     * @returns {Contract<typeof gasPriceOracleABI>} - A web.js contract instance with an RPC provider inherited from root {web3} instance
     */
    _getPriceOracleContractInstance() {
        if (this._gasPriceOracleContract === undefined) {
            this._gasPriceOracleContract = new Contract(gasPriceOracleABI, gasPriceOracleAddress[420]);
            // This plugin's Web3Context is overridden with main Web3 instance's context
            // when the plugin is registered. This overwrites the Contract instance's context
            this._gasPriceOracleContract.link(this);
        }
        return this._gasPriceOracleContract;
    }
    /**
     * Returns the RLP encoded hex string for {transaction}
     * @param transaction - A web3.js {Transaction} object
     * @returns {string} - The RLP encoded hex string
     */
    _serializeTransaction(transaction) {
        const ethereumjsTransaction = TransactionFactory.fromTxData(formatTransaction(transaction, {
            number: FMT_NUMBER.HEX,
            bytes: FMT_BYTES.HEX,
        }));
        return Web3.utils.bytesToHex(Web3.utils.uint8ArrayConcat(Web3.utils.hexToBytes(ethereumjsTransaction.type.toString(16).padStart(2, '0')), 
        // If <transaction> doesn't include a signature,
        // <ethereumjsTransaction.raw()> will autofill v, r, and s
        // with empty uint8Array. Because L1 fee calculation
        // is dependent on the number of bytes, we are removing
        // the zero values bytes
        RLP.encode(ethereumjsTransaction.raw().slice(0, -3))));
    }
}
