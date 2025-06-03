// SPDX-License-Identifier: MIT
// @version 0.2.8
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
 * ======================== FrxUSDDistributor =========================
 * ====================================================================
 * Mints and distributes FrxUSD yield to addresses
 * Frax Finance: https://github.com/FraxFinance
 */
import {
    IERC20PermitPermissionedOptiMintable
} from "src/contracts/Fraxtal/universal/interfaces/IERC20PermitPermissionedOptiMintable.sol";
import { OwnedV2AutoMsgSender } from "src/contracts/VestedFXS-and-Flox/VestedFXS/OwnedV2AutoMsgSender.sol";
import { ReentrancyGuard } from "@openzeppelin-5/contracts/utils/ReentrancyGuard.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { SafeERC20 } from "@openzeppelin-5/contracts/token/ERC20/utils/SafeERC20.sol";
// import "forge-std/console2.sol";

contract FrxUSDDistributor is Initializable, OwnedV2AutoMsgSender, ReentrancyGuard {
    // STATE VARIABLES
    // ===================================================

    /// @notice Permissioned bot
    address public bot;

    /// @notice frxUSD
    IERC20PermitPermissionedOptiMintable public frxUSD;

    /// @notice Whitelisted addresses to receive yield
    mapping(address => bool) public whitelistedAddresses;

    /// @notice Total amount an address has been paid (all time)
    mapping(address => uint256) public ttlPaidByAddress;

    /// @notice Total amount an address has been paid (by day)
    /// @dev address -> epoch day -> amount paid
    mapping(address => mapping(uint256 => uint256)) public ttlPaidByAddressByDay;

    /// @notice Total amount that has been paid by the bot by epoch day
    mapping(uint256 => uint256) public ttlPaidByDay;

    /// @notice Total amount all addresses have been paid
    uint256 public ttlPaid;

    /// @notice Max amount the bot can pay out per day
    uint256 public dailyPayCap;

    // CONSTRUCTOR
    // ===================================================

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() OwnedV2AutoMsgSender() {
        _disableInitializers();
    }

    // INITIALIZER
    // ===================================================

    /// @notice Initializes the contract
    /// @param _owner Contract owner
    /// @param _bot The bot
    function initialize(address _owner, address _bot, address _frxUSD) public initializer {
        owner = _owner;
        bot = _bot;
        frxUSD = IERC20PermitPermissionedOptiMintable(_frxUSD);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyByOwnerOrBot() {
        if (msg.sender != owner && msg.sender != bot) revert NotOwnerOrBot();
        _;
    }

    // BOT FUNCTIONS
    // ===================================================

    /// @notice Sends yield to the target address (must be whitelisted). Called once daily by the bot.
    /// @param _to Address to mint tokens to.
    /// @param _amount Amount of tokens to mint.
    function payYield(address _to, uint256 _amount) external onlyByOwnerOrBot nonReentrant {
        // Get the epoch day
        uint256 _epochDay = block.timestamp / 1 days;

        // Cannot pay zero
        if (_amount == 0) revert CannotPayZero();

        // Check if the address is whitelisted
        if (!whitelistedAddresses[_to]) revert AddressNotWhitelisted();

        // Check if the address was already paid today
        if (ttlPaidByAddressByDay[_to][_epochDay] > 0) revert AlreadyPaidAddressToday();

        // Increment the tracking variables
        ttlPaidByAddressByDay[_to][_epochDay] += _amount;
        ttlPaidByAddress[_to] += _amount;
        ttlPaidByDay[_epochDay] += _amount;
        ttlPaid += _amount;

        // Revert if too much has been paid out today
        if (ttlPaidByDay[_epochDay] > dailyPayCap) revert DailyPayCapReached();

        // Do the minting last
        frxUSD.minter_mint(_to, _amount);

        emit YieldPaid(_to, _amount, _epochDay);
    }

    // RESTRICTED FUNCTIONS
    // ===================================================

    /// @notice Set the bot address
    /// @param _addr The new bot address
    function setBot(address _addr) external onlyOwner {
        // Set the new bot address
        bot = _addr;

        emit BotAddressSet(_addr);
    }

    /// @notice Set the daily pay cap
    /// @param _cap The new daily pay cap
    function setDailyPayCap(uint256 _cap) external onlyOwner {
        // Set the daily pay cap
        dailyPayCap = _cap;

        emit DailyPayCapSet(_cap);
    }

    /// @notice Whitelist/De-whitelist an address
    /// @param _addr The address in question
    /// @param _isWhitelisted Whether the address should be whitelisted or not
    function setWhitelistedAddress(address _addr, bool _isWhitelisted) external onlyOwner {
        // Set the whitelist status for the provided address
        whitelistedAddresses[_addr] = _isWhitelisted;

        emit AddressWhitelistSet(_addr, _isWhitelisted);
    }

    // ERRORS
    // ===================================================

    /// @notice When the payee address has not been whitelisted
    error AddressNotWhitelisted();

    /// @notice When an address has already been paid today
    error AlreadyPaidAddressToday();

    /// @notice Cannot pay zero yield
    error CannotPayZero();

    /// @notice When too much has already been paid out today
    error DailyPayCapReached();

    /// @notice When the caller is neither the owner nor the bot
    error NotOwnerOrBot();

    // EVENTS
    // ===================================================

    /// @notice When the whitelist status of an address changes
    /// @param addr The address in question
    /// @param isWhitelisted Whether the address should be whitelisted or not
    event AddressWhitelistSet(address indexed addr, bool isWhitelisted);

    /// @notice When the new bot address is set
    /// @param addr The new bot address
    event BotAddressSet(address indexed addr);

    /// @notice When the new daily pay cap is set
    /// @param cap The new daily pay cap
    event DailyPayCapSet(uint256 cap);

    /// @notice When the bot has paid the yield
    /// @param to The recipient of the yield
    /// @param amount Amount of the yield
    /// @param epochDay The epoch day that the yield was paid
    event YieldPaid(address indexed to, uint256 amount, uint256 epochDay);
}
