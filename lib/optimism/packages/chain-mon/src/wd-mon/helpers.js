"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getLastFinalizedBlock = void 0;
/**
 * Finds
 *
 * @param
 * @param
 * @param
 * @returns
 */
const getLastFinalizedBlock = async (l1RpcProvider, faultProofWindow, logger) => {
    let guessWindowStartBlock;
    try {
        const l1Block = await l1RpcProvider.getBlock('latest');
        // The time corresponding to the start of the FPW, based on the current block.
        const windowStartTime = l1Block.timestamp - faultProofWindow;
        // Use the FPW to find the block number that is the start of the FPW.
        guessWindowStartBlock = l1Block.number - faultProofWindow / 12;
        let block = await l1RpcProvider.getBlock(guessWindowStartBlock);
        while (block.timestamp > windowStartTime) {
            guessWindowStartBlock--;
            block = await l1RpcProvider.getBlock(guessWindowStartBlock);
        }
        return block.number;
    }
    catch (err) {
        logger.fatal('error when calling querying for block', {
            errors: err,
        });
        throw new Error(`unable to find block number ${guessWindowStartBlock || 'latest'}`);
    }
};
exports.getLastFinalizedBlock = getLastFinalizedBlock;
