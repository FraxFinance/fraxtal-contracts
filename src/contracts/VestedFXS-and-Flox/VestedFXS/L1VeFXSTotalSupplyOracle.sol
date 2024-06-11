// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

/**
 * ====================================================================
 * |     ______                   _______                             |
 * |    / _____________ __  __   / ____(_____  ____ _____  ________   |
 * |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
 * |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
 * | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
 * |                                                                  |
 * ====================================================================
 * ===================== L1VeFXSTotalSupplyOracle =====================
 * ====================================================================
 * Bot-set Oracle for reporting the Ethereum Mainnet veFXS totalSupply() info.
 * Eventually plan to update L1VeFXS with a proof-based solution
 * Frax Finance: https://github.com/FraxFinance
 */

/* solhint-disable max-line-length, not-rely-on-time */
import "./OwnedV2.sol";

contract L1VeFXSTotalSupplyOracle is OwnedV2 {
    /// @notice The last veFXS totalSupply data point
    uint256 public totalSupplyStored;

    /// @notice The block on Mainnet when the veFXS totalSupply was read
    uint128 public blkWhenTotalSupplyRead;

    /// @notice The timestamp on Mainnet when the veFXS totalSupply was read
    uint128 public tsWhenTotalSupplyRead;

    /// @notice When the information was last updated by the bot
    uint256 public lastBotUpdate;

    /// @notice Address of the bot that is allowed to update the contract
    address public botAddress;

    /**
     * @notice Initialize contract
     * @param _owner The owner of this contract
     * @param _bot Address of the bot that is allowed to post
     * @param _initTtlSupplyStored Initial/seed value of totalSupplyStored
     * @param _initBlkWhenTotalSupplyRead Initial/seed value of blkWhenTotalSupplyRead
     * @param _initTsWhenTtlSupplyRead Initial/seed value of tsWhenTotalSupplyRead
     */
    constructor(
        address _owner,
        address _bot,
        uint256 _initTtlSupplyStored,
        uint128 _initBlkWhenTotalSupplyRead,
        uint128 _initTsWhenTtlSupplyRead
    ) OwnedV2(_owner) {
        // Set bot address
        botAddress = _bot;

        // Set seed values
        totalSupplyStored = _initTtlSupplyStored;
        blkWhenTotalSupplyRead = _initBlkWhenTotalSupplyRead;
        tsWhenTotalSupplyRead = _initTsWhenTtlSupplyRead;
        if (_initTsWhenTtlSupplyRead > 0) lastBotUpdate = _initTsWhenTtlSupplyRead;
    }

    /* ========== MODIFIERS ========== */

    modifier onlyByOwnBot() {
        require(msg.sender == owner || msg.sender == botAddress, "You are not the owner or the bot");
        _;
    }

    /* ============ VIEWS ============ */

    /// @notice Get the most recent totalSupply from Mainnet veFXS
    /// @param _totalSupply The last reported Mainnet veFXS totalSupply
    function totalSupply() external view returns (uint256 _totalSupply) {
        return totalSupplyStored;
    }

    /// @notice Get the most recent totalSupply from Mainnet veFXS along with the time it was read
    /// @param _totalSupply The last reported Mainnet veFXS totalSupply
    /// @param _blk Block when the totalSupply was read on Mainnet
    /// @param _ts Timestamp when the totalSupply was read on Mainnet
    function totalSupplyExtra() external view returns (uint256 _totalSupply, uint128 _blk, uint128 _ts) {
        return (totalSupplyStored, blkWhenTotalSupplyRead, tsWhenTotalSupplyRead);
    }

    // ==============================================================================
    // BOT FUNCTIONS
    // ==============================================================================

    /// @notice Set the most recent totalSupply from Mainnet veFXS
    /// @param _totalSupply The last reported Mainnet veFXS totalSupply
    /// @param _blk Block when the totalSupply was read on Mainnet
    /// @param _ts Timestamp when the totalSupply was read on Mainnet
    function updateInfo(uint256 _totalSupply, uint128 _blk, uint128 _ts) external onlyByOwnBot {
        totalSupplyStored = _totalSupply;
        blkWhenTotalSupplyRead = _blk;
        tsWhenTotalSupplyRead = _ts;
    }

    // ==============================================================================
    // RESTRICTED FUNCTIONS
    // ==============================================================================

    /// @notice Set the bot address
    /// @param _newBot The address of the bot
    function setBot(address _newBot) external onlyOwner {
        botAddress = _newBot;
    }

    // ==============================================================================
    // EVENTS
    // ==============================================================================

    /// @notice When the veFXS info is updated
    /// @param totalSupply veFXS totalSupply from mainnet
    /// @param blk Block when the totalSupply was read on Mainnet
    /// @param ts Timestamp when the totalSupply was read on Mainnet
    event InfoUpdated(uint256 totalSupply, uint128 blk, uint128 ts);
}
