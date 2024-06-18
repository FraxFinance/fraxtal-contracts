// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ========================== EpochTracker ============================
// ====================================================================

import { OwnedV2 } from "src/contracts/VestedFXS-and-Flox/VestedFXS/OwnedV2.sol";

/**
 * @title EpochTracker
 * @author Frax Finance
 * @notice The EpochTracker contract is used to retrieve the balances of collateral and LP tokens of pools.
 */
contract EpochTracker is OwnedV2 {
    struct Epoch {
        uint256 firstBlock;
        uint256 lastBlock;
        bool allocated;
    }

    mapping(uint256 epochNumber => Epoch) public epochs;

    uint256 public numberOfCurentlyTrackedEpochs;
    uint256 public epochLength;

    constructor(uint256 _intialEpochLength, uint256 _firstEpochFirstBlock) OwnedV2(msg.sender) {
        epochLength = _intialEpochLength;
        epochs[0] = Epoch(_firstEpochFirstBlock, _firstEpochFirstBlock + _intialEpochLength - 1, true);
        numberOfCurentlyTrackedEpochs = 1;
    }

    /**
     * @notice Used to set the length of the epoch.
     * @param _epochLength The length of the epoch in blocks
     */
    function setEpochLength(uint256 _epochLength) external {
        _onlyOwner();
        epochLength = _epochLength;
    }

    /**
     * @notice Used to mark the next epoch as allocated.
     * @dev This will revert if the last epoch is not finished yet.
     */
    function allocatedNextEpoch() external {
        _onlyOwner();
        if (epochs[numberOfCurentlyTrackedEpochs - 1].lastBlock + epochLength > block.number) {
            revert AttemptingToAllocateUnfinishedEpoch();
        }

        epochs[numberOfCurentlyTrackedEpochs] = Epoch({
            firstBlock: epochs[numberOfCurentlyTrackedEpochs - 1].lastBlock + 1,
            lastBlock: epochs[numberOfCurentlyTrackedEpochs - 1].lastBlock + epochLength,
            allocated: true
        });
        ++numberOfCurentlyTrackedEpochs;

        emit NewEpoch(
            numberOfCurentlyTrackedEpochs,
            epochs[numberOfCurentlyTrackedEpochs - 1].firstBlock,
            epochs[numberOfCurentlyTrackedEpochs - 1].lastBlock,
            true
        );
    }

    /**
     * @notice Used to toggle the allocation status of an epoch.
     * @param _epochNumber The number of the epoch
     */
    function toggleAllocationStatus(uint256 _epochNumber) external {
        _onlyOwner();
        if (_epochNumber > numberOfCurentlyTrackedEpochs) revert AttemptingToManipulateUntrackedEpoch();

        epochs[_epochNumber - 1].allocated = !epochs[_epochNumber - 1].allocated;
    }

    /**
     * @notice Used to get the last allocated epoch.
     * @return epochNumber The number of the epoch
     * @return firstBlock The first block of the epoch
     * @return lastBlock The last block of the epoch
     */
    function getLastAllocatedEpoch()
        external
        view
        returns (uint256 epochNumber, uint256 firstBlock, uint256 lastBlock)
    {
        epochNumber = numberOfCurentlyTrackedEpochs;
        firstBlock = epochs[numberOfCurentlyTrackedEpochs - 1].firstBlock;
        lastBlock = epochs[numberOfCurentlyTrackedEpochs - 1].lastBlock;
    }

    /**
     * @notice Used to get the current epoch.
     * @dev This will return the current epoch, not the next one to be allocated.
     * @return epochNumber Number of the epoch
     * @return firstBlock The first block of the epoch
     * @return lastBlock The last point of the epoch
     */
    function getCurrentEpoch() external view returns (uint256 epochNumber, uint256 firstBlock, uint256 lastBlock) {
        epochNumber = numberOfCurentlyTrackedEpochs;
        Epoch memory currentEpoch = epochs[epochNumber - 1];
        firstBlock = currentEpoch.firstBlock;
        lastBlock = currentEpoch.lastBlock;

        while (lastBlock < block.number) {
            firstBlock += epochLength;
            lastBlock += epochLength;
            ++epochNumber;
        }
    }

    /**
     * @notice Used to get a specific epoch.
     * @dev This will return the data for both, the allocated and not allcoated epochs.
     * @param _epochNumber The number of the epoch
     * @return firstBlock The first block of the epoch
     * @return lastBlock The last block of the epoch
     * @return allocated The status of the epoch
     */
    function getEpoch(
        uint256 _epochNumber
    ) external view returns (uint256 firstBlock, uint256 lastBlock, bool allocated) {
        if (_epochNumber <= numberOfCurentlyTrackedEpochs) {
            Epoch memory epoch = epochs[_epochNumber - 1];
            firstBlock = epoch.firstBlock;
            lastBlock = epoch.lastBlock;
            allocated = epoch.allocated;
        } else {
            Epoch memory firstEpoch = epochs[0];
            firstBlock = firstEpoch.firstBlock + (epochLength * (_epochNumber - 1));
            lastBlock = firstBlock + epochLength - 1;
            allocated = false;
        }
    }

    event NewEpoch(uint256 indexed epochNumber, uint256 firstBlock, uint256 lastBlock, bool allocated);

    error AttemptingToAllocateUnfinishedEpoch();
    error AttemptingToManipulateUntrackedEpoch();
}
