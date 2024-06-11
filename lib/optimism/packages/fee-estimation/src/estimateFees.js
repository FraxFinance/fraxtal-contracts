import { gasPriceOracleABI, gasPriceOracleAddress, } from '@eth-optimism/contracts-ts';
import { getContract, createPublicClient, http, serializeTransaction, encodeFunctionData, } from 'viem';
import * as chains from 'viem/chains';
const knownChains = [
    chains.optimism.id,
    chains.goerli.id,
    chains.base,
    chains.baseGoerli.id,
    chains.zora,
    chains.zoraTestnet,
];
/**
 * Throws an error if fetch is not defined
 * Viem requires fetch
 */
const validateFetch = () => {
    if (typeof fetch === 'undefined') {
        throw new Error('No fetch implementation found. Please provide a fetch polyfill. This can be done in NODE by passing in NODE_OPTIONS=--experimental-fetch or by using the isomorphic-fetch npm package');
    }
};
/**
 * Internal helper to serialize a transaction
 */
const transactionSerializer = (options) => {
    const encodedFunctionData = encodeFunctionData(options);
    const serializedTransaction = serializeTransaction({
        ...options,
        data: encodedFunctionData,
        type: 'eip1559',
    });
    return serializedTransaction;
};
/**
 * Gets L2 client
 * @example
 * const client = getL2Client({ chainId: 1, rpcUrl: "http://localhost:8545" });
 */
export const getL2Client = (options) => {
    validateFetch();
    if ('chainId' in options && options.chainId) {
        const viemChain = Object.values(chains)?.find((chain) => chain.id === options.chainId);
        const rpcUrls = options.rpcUrl
            ? { default: { http: [options.rpcUrl] } }
            : viemChain?.rpcUrls;
        if (!rpcUrls) {
            throw new Error(`No rpcUrls found for chainId ${options.chainId}.  Please explicitly provide one`);
        }
        return createPublicClient({
            chain: {
                id: options.chainId,
                name: viemChain?.name ?? 'op-chain',
                nativeCurrency: options.nativeCurrency ??
                    viemChain?.nativeCurrency ??
                    chains.optimism.nativeCurrency,
                network: viemChain?.network ?? 'Unknown OP Chain',
                rpcUrls,
                explorers: viemChain?.blockExplorers ??
                    chains.optimism.blockExplorers,
            },
            transport: http(options.rpcUrl ?? chains[options.chainId].rpcUrls.public.http[0]),
        });
    }
    return options;
};
/**
 * Get gas price Oracle contract
 */
export const getGasPriceOracleContract = (params) => {
    return getContract({
        address: gasPriceOracleAddress['420'],
        abi: gasPriceOracleABI,
        publicClient: getL2Client(params),
    });
};
/**
 * Returns the base fee
 * @returns {Promise<bigint>} - The base fee
 * @example
 * const baseFeeValue = await baseFee(params);
 */
export const baseFee = async ({ client, blockNumber, blockTag, }) => {
    const contract = getGasPriceOracleContract(client);
    return contract.read.baseFee({ blockNumber, blockTag });
};
/**
 * Returns the decimals used in the scalar
 * @example
 * const decimalsValue = await decimals(params);
 */
export const decimals = async ({ client, blockNumber, blockTag, }) => {
    const contract = getGasPriceOracleContract(client);
    return contract.read.decimals({ blockNumber, blockTag });
};
/**
 * Returns the gas price
 * @example
 * const gasPriceValue = await gasPrice(params);
 */
export const gasPrice = async ({ client, blockNumber, blockTag, }) => {
    const contract = getGasPriceOracleContract(client);
    return contract.read.gasPrice({ blockNumber, blockTag });
};
/**
 * Computes the L1 portion of the fee based on the size of the rlp encoded input
 * transaction, the current L1 base fee, and the various dynamic parameters.
 * @example
 * const L1FeeValue = await getL1Fee(data, params);
 */
export const getL1Fee = async (options) => {
    const data = transactionSerializer(options);
    const contract = getGasPriceOracleContract(options.client);
    return contract.read.getL1Fee([data], {
        blockNumber: options.blockNumber,
        blockTag: options.blockTag,
    });
};
/**
 * Returns the L1 gas used
 * @example
 */
export const getL1GasUsed = async (options) => {
    const data = transactionSerializer(options);
    const contract = getGasPriceOracleContract(options.client);
    return contract.read.getL1GasUsed([data], {
        blockNumber: options.blockNumber,
        blockTag: options.blockTag,
    });
};
/**
 * Returns the L1 base fee
 * @example
 * const L1BaseFeeValue = await l1BaseFee(params);
 */
export const l1BaseFee = async ({ client, blockNumber, blockTag, }) => {
    const contract = getGasPriceOracleContract(client);
    return contract.read.l1BaseFee({ blockNumber, blockTag });
};
/**
 * Returns the overhead
 * @example
 * const overheadValue = await overhead(params);
 */
export const overhead = async ({ client, blockNumber, blockTag, }) => {
    const contract = getGasPriceOracleContract(client);
    return contract.read.overhead({ blockNumber, blockTag });
};
/**
 * Returns the current fee scalar
 * @example
 * const scalarValue = await scalar(params);
 */
export const scalar = async ({ client, ...params }) => {
    const contract = getGasPriceOracleContract(client);
    return contract.read.scalar(params);
};
/**
 * Returns the version
 * @example
 * const versionValue = await version(params);
 */
export const version = async ({ client, ...params }) => {
    const contract = getGasPriceOracleContract(client);
    return contract.read.version(params);
};
/**
 * Estimates gas for an L2 transaction including the l1 fee
 */
export const estimateFees = async (options) => {
    const client = getL2Client(options.client);
    const encodedFunctionData = encodeFunctionData({
        abi: options.abi,
        args: options.args,
        functionName: options.functionName,
    });
    const [l1Fee, l2Gas, l2GasPrice] = await Promise.all([
        getL1Fee({
            ...options,
            // account must be undefined or else viem will return undefined
            account: undefined,
        }),
        client.estimateGas({
            to: options.to,
            account: options.account,
            accessList: options.accessList,
            blockNumber: options.blockNumber,
            blockTag: options.blockTag,
            data: encodedFunctionData,
            value: options.value,
        }),
        client.getGasPrice(),
    ]);
    return l1Fee + l2Gas * l2GasPrice;
};
