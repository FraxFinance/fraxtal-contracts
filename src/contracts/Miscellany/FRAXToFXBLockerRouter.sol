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
 * ====================== FRAXToFXBLockerRouter =======================
 * ====================================================================
 * Takes FRAX and converts it into FXB, then places it in a TimedLocker
 * Frax Finance: https://github.com/FraxFinance
 */
import { ERC20 } from "@openzeppelin-4/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin-4/contracts/token/ERC20/IERC20.sol";
import { IFXB } from "src/contracts/Miscellany/interfaces/IFXB.sol";
import { Math } from "@openzeppelin-4/contracts/utils/math/Math.sol";
import { OwnedV2 } from "./OwnedV2.sol";
import { ReentrancyGuard } from "@openzeppelin-4/contracts/security/ReentrancyGuard.sol";
import { TransferHelper } from "src/contracts/VestedFXS-and-Flox/Flox/TransferHelper.sol";
import { ISlippageAuction } from "src/contracts/Miscellany/interfaces/ISlippageAuction.sol";
import { TimedLocker } from "src/contracts/Miscellany/TimedLocker.sol";

// import "forge-std/console2.sol";

contract FRAXToFXBLockerRouter is OwnedV2, ReentrancyGuard {
    /* ========== STATE VARIABLES ========== */

    // Core variables
    // ----------------------------------------
    /// @notice The FRAX token
    ERC20 public frax = ERC20(0xFc00000000000000000000000000000000000001);

    /// @notice Routes for the FXB -> Auction -> TimedLocker -> isValid
    mapping(address fxb => mapping(address auction => mapping(address locker => bool isValid))) public routeStatuses;

    /* ========== CONSTRUCTOR ========== */

    /// @notice Constructor
    /// @param _owner The owner of the locker
    constructor(address _owner) OwnedV2(_owner) {}

    /* ========== MODIFIERS ========== */

    /* ========== VIEWS ========== */

    /* ========== MUTATIVE FUNCTIONS ========== */

    /// @notice Routes FRAX into a FXB TimedLocker
    /// @param _fxbAddr Address of the FXB token
    /// @param _auctionAddr Address of the FXB SlippageAuction
    /// @param _lockerAddr Address of the desired TimedLocker
    /// @param _fraxIn Amount of input FRAX
    /// @param _minOutFxb Minimum amount of FXB out
    /// @return _fxbOut Amount of FXB (and the vault tokens) that was generated
    /// @dev Approve FRAX to this contract first
    function routeFraxToTimedLocker(
        address _fxbAddr,
        address _auctionAddr,
        address _lockerAddr,
        uint256 _fraxIn,
        uint256 _minOutFxb
    ) public returns (uint256 _fxbOut) {
        // Take the FRAX from the user
        TransferHelper.safeTransferFrom(address(frax), msg.sender, address(this), _fraxIn);

        // Check the Route's validity
        if (!routeStatuses[_fxbAddr][_auctionAddr][_lockerAddr]) revert InvalidRoute();

        // Instantiate the SlippageAuction and the TimedLocker
        ISlippageAuction _auction = ISlippageAuction(_auctionAddr);
        TimedLocker _locker = TimedLocker(_lockerAddr);

        // Approve FRAX to the auction
        frax.approve(_auctionAddr, _fraxIn);

        // Prepare the path
        address[] memory _path = new address[](2);
        _path[0] = address(frax);
        _path[1] = _fxbAddr;

        // Buy FXBs from the auction
        uint256[] memory _amounts = _auction.swapExactTokensForTokens(
            _fraxIn,
            _minOutFxb,
            _path,
            address(this),
            block.timestamp + 3600
        );
        _fxbOut = _amounts[1];

        // Approve the FXB to the TimedLocker
        ERC20(_fxbAddr).approve(_lockerAddr, _fxbOut);

        // Do the lock
        _locker.stake(_fxbOut);

        // Give the vault tokens to the sender
        TransferHelper.safeTransfer(_lockerAddr, msg.sender, _fxbOut);

        emit FraxRouted(_fxbAddr, _auctionAddr, _lockerAddr, _fraxIn, _fxbOut);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /// @notice Set an allowed FRAX -> FXB (auction) -> TimedLocker route
    /// @param _fxb The address of the FXB
    /// @param _auction The address of the FXB SlippageAuction
    /// @param _locker The address of the TimedLocker
    /// @param _status True if the specified route is to be allowed
    function setRouteStatus(address _fxb, address _auction, address _locker, bool _status) external onlyOwner {
        // Check inputs
        if (_fxb == address(0)) revert InvalidFXB();

        // Will revert if inputs are not contracts, or if other checks don't pass
        try IFXB(_fxb).MATURITY_TIMESTAMP() {} catch {
            revert InvalidFXB();
        }
        if (ISlippageAuction(_auction).TOKEN_SELL() != _fxb) revert InvalidAuction();
        if (address(TimedLocker(_locker).stakingToken()) != _fxb) revert InvalidTimedLocker();

        // Set the route status
        routeStatuses[_fxb][_auction][_locker] = _status;

        emit RouteStatusSet(_fxb, _auction, _locker, _status);
    }

    /// @notice Added to support recovering LP Rewards and other mistaken tokens from other systems to be distributed to holders
    /// @param _tokenAddress The address of the token
    /// @param _tokenAmount The amount of the token
    function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        // Only the owner address can ever receive the recovery withdrawal
        TransferHelper.safeTransfer(_tokenAddress, owner, _tokenAmount);

        emit RecoveredERC20(_tokenAddress, _tokenAmount);
    }

    /* ========== ERRORS ========== */

    /// @notice When the SlippageAuction you are trying to set is invalid
    error InvalidAuction();

    /// @notice When the FXB you are trying to set is invalid
    error InvalidFXB();

    /// @notice When the Route you are using is invalid or disabled
    error InvalidRoute();

    /// @notice When the TimedLocker you are trying to set is invalid
    error InvalidTimedLocker();

    /* ========== EVENTS ========== */

    /// @notice When a FRAX -> FXB (auction) -> TimedLocker route is executed
    /// @param fxb The address of the FXB
    /// @param auction The address of the FXB SlippageAuction
    /// @param locker The address of the TimedLocker
    /// @param fraxIn Input amout of FRAX
    /// @param fxbOut Output amount of FXB that was subsequently locked in the TimedLocker
    event FraxRouted(address indexed fxb, address auction, address locker, uint256 fraxIn, uint256 fxbOut);

    /// @notice When ERC20 tokens were recovered
    /// @param token Token address
    /// @param amount Amount of tokens collected
    event RecoveredERC20(address token, uint256 amount);

    /// @notice When a FRAX -> FXB (auction) -> TimedLocker route is set
    /// @param fxb The address of the FXB
    /// @param auction The address of the FXB SlippageAuction
    /// @param locker The address of the TimedLocker
    /// @param status True if the specified route is to be allowed
    event RouteStatusSet(address indexed fxb, address auction, address locker, bool status);
}
