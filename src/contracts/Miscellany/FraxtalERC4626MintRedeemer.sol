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
 * ==================== FraxtalERC4626MintRedeemer ====================
 * ====================================================================
 * Mint/Redeemer for Fraxtal's bridged version of Ethereum Mainnet sFRAX
 * Frax Finance: https://github.com/FraxFinance
 */
import { AggregatorV3Interface } from "src/contracts/Miscellany/interfaces/AggregatorV3Interface.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20PermitPermissionedOptiMintable } from "./interfaces/IERC20PermitPermissionedOptiMintable.sol";
import { OwnedV2AutoMsgSender } from "src/contracts/VestedFXS-and-Flox/VestedFXS/OwnedV2AutoMsgSender.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "forge-std/console2.sol";

contract FraxtalERC4626MintRedeemer is OwnedV2AutoMsgSender, ReentrancyGuard {
    using Math for uint256;

    // STATE VARIABLES
    // ===================================================

    /// @notice Bridged underlying token from Ethereum Mainnet
    // 0xFc00000000000000000000000000000000000001 [FRAX]
    IERC20PermitPermissionedOptiMintable public underlyingTkn;

    /// @notice Bridged vault token from Ethereum Mainnet
    // 0xfc00000000000000000000000000000000000008 [sFRAX]
    IERC20PermitPermissionedOptiMintable public vaultTkn;

    /// @notice Decimals for the underlying token
    uint8 public constant decimals = 18;

    /// @notice Underlying token price oracle
    // 0x0000000000000000000000000000000000000000 (FRAX)
    AggregatorV3Interface public priceFeedUnderlying;

    /// @notice Vault token price oracle
    // 0x1B680F4385f24420D264D78cab7C58365ED3F1FF [sFRAX]
    AggregatorV3Interface public priceFeedVault;

    /// @notice Oracle delay tolerance, in seconds
    uint256 public oracleTimeTolerance;

    /// @notice If the contract was initialized
    bool wasInitialized;

    /// @notice Latest vault token price read from the oracle
    uint256 public vaultTknPrice;

    /// @notice Last time the vault token oracle was read
    uint256 public lastVaultTknOracleRead;

    /// @notice Micro Fee for deposit|mint/withdraw|redeem flow. 18 decimals
    uint256 public fee;

    // CONSTRUCTOR & INITIALIZER
    // ===================================================

    /// @notice Contract constructor
    constructor() {
        // Set the contract as initialized
        wasInitialized = true;
    }

    /**
     * @notice Initialize contract
     * @param _owner The owner of this contract
     * @param _underlyingTkn Address of the underlying token
     * @param _vaultTkn Address of the vault token
     * @param _underlyingOracle Price oracle for the underlying token
     * @param _vaultOracle Price oracle for the vault token
     * @param _fee The fee to implement on mint|deposit/redeem|withdraw flow
     * @param _initialVaultTknPrice Initial price of the vault token
     */
    function initialize(
        address _owner,
        address _underlyingTkn,
        address _vaultTkn,
        address _underlyingOracle,
        address _vaultOracle,
        uint256 _fee,
        uint256 _initialVaultTknPrice
    ) public {
        // Safety checks - no validation on admin in case this is initialized without admin
        if (wasInitialized || (address(underlyingTkn) != address(0))) {
            revert InitializeFailed();
        }

        // Set owner for OwnedV2
        owner = _owner;

        // Set token addresses
        underlyingTkn = IERC20PermitPermissionedOptiMintable(_underlyingTkn);
        vaultTkn = IERC20PermitPermissionedOptiMintable(_vaultTkn);

        // Set oracle addresses
        priceFeedUnderlying = AggregatorV3Interface(_underlyingOracle);
        priceFeedVault = AggregatorV3Interface(_vaultOracle);

        // Set initial vault token price
        vaultTknPrice = _initialVaultTknPrice;

        // Set the mint|deposit/redeem|withdraw flow fee
        fee = _fee;

        // Set initial oracle time tolerance
        oracleTimeTolerance = 86_400; // Default to 24 hours

        // Set the contract as initialized
        wasInitialized = true;
    }

    // ORACLE PUBLIC/EXTERNAL VIEWS
    // ===================================================

    /// @notice Gets the latest oracle price of underlyingTkn
    /// @return _price The E18 price of underlyingTkn
    function getLatestUnderlyingPriceE18() public view returns (int256 _price) {
        // Returns in E18
        if (address(priceFeedUnderlying) == address(0)) {
            return 1e18;
        } else {
            (uint80 roundID, int256 price, , uint256 updatedAt, uint80 answeredInRound) = priceFeedUnderlying
                .latestRoundData();
            if (price <= 0) {
                revert InvalidOraclePrice(underlyingTkn.symbol());
            } else if ((updatedAt + oracleTimeTolerance) < block.timestamp) {
                revert OracleIsStale(underlyingTkn.symbol());
            } else if (answeredInRound < roundID) {
                revert InvalidOracleRoundID(underlyingTkn.symbol());
            }

            return price;
        }
    }

    /// @notice Gets the latest oracle price of vaultTkn
    /// @return _price The E18 price of vaultTkn
    function getLatestVaultTknPriceE18() public view returns (int256 _price) {
        // Returns in E18
        (uint80 roundID, int256 price, , uint256 updatedAt, uint80 answeredInRound) = priceFeedVault.latestRoundData();
        if (price <= 0) {
            revert InvalidOraclePrice(vaultTkn.symbol());
        } else if ((updatedAt + oracleTimeTolerance) < block.timestamp) {
            revert OracleIsStale(vaultTkn.symbol());
        } else if (answeredInRound < roundID) {
            revert InvalidOracleRoundID(vaultTkn.symbol());
        }

        return price;
    }

    /// @notice Get the stored vault token price
    function getVaultTknPriceStoredE18() public view returns (uint256 _price) {
        // Revert if the vault token price is stale
        if (block.timestamp > (lastVaultTknOracleRead + oracleTimeTolerance)) {
            revert OracleIsStale(vaultTkn.symbol());
        }
        // Return the oracle price ingested
        return vaultTknPrice;
    }

    // ERC4626 PUBLIC/EXTERNAL VIEWS
    // ===================================================

    /// @notice Return the underlying asset
    /// @return _underlying The underlying asset
    function asset() public view returns (address _underlying) {
        _underlying = address(underlyingTkn);
    }

    /// @notice Share balance of the supplied address
    /// @param _addr The address to test
    /// @return _balance Total amount of shares
    function balanceOf(address _addr) public view returns (uint256 _balance) {
        return vaultTkn.balanceOf(_addr);
    }

    /// @notice Total amount of underlying asset available
    /// @param _assets Amount of underlying tokens
    /// @dev See {IERC4626-totalAssets}
    function totalAssets() public view returns (uint256 _assets) {
        return underlyingTkn.balanceOf(address(this));
    }

    /// @notice Total amount of shares
    /// @return _supply Total amount of shares
    function totalSupply() public view returns (uint256 _supply) {
        return vaultTkn.totalSupply();
    }

    /// @notice Returns the amount of shares that the contract would exchange for the amount of assets provided
    /// @param _assets Amount of underlying tokens
    /// @return _shares Amount of shares that the underlying _assets represents
    /// @dev See {IERC4626-convertToShares}
    function convertToShares(uint256 _assets) public view returns (uint256 _shares) {
        _shares = _convertToShares(_assets, Math.Rounding.Down);
    }

    /// @notice Returns the amount of assets that the contract would exchange for the amount of shares provided
    /// @param _shares Amount of shares
    /// @return _assets Amount of underlying asset that _shares represents
    /// @dev See {IERC4626-convertToAssets}
    function convertToAssets(uint256 _shares) public view returns (uint256 _assets) {
        _assets = _convertToAssets(_shares, Math.Rounding.Down);
    }

    /// @notice Returns the maximum amount of the underlying asset that can be deposited into the contract for the receiver, through a deposit call. Includes fee.
    /// @param _addr The address to test
    /// @return _maxAssetsIn The max amount that can be deposited
    /**
     * @dev See {IERC4626-maxDeposit}
     * Contract vaultTkn -> underlyingTkn needed
     */
    function maxDeposit(address _addr) public view returns (uint256 _maxAssetsIn) {
        // See how much underlyingTkn you would need to exchange for 100% of the vaultTkn in the contract
        _maxAssetsIn = previewMint(vaultTkn.balanceOf(address(this)));
    }

    /// @notice Returns the maximum amount of shares that can be minted for the receiver, through a mint call. Includes fee.
    /// @param _addr The address to test
    /// @return _maxSharesOut The max amount that can be minted
    /**
     * @dev See {IERC4626-maxMint}
     * Contract vaultTkn balance
     */
    function maxMint(address _addr) public view returns (uint256 _maxSharesOut) {
        // See how much vaultTkn is actually available in the contract
        _maxSharesOut = vaultTkn.balanceOf(address(this));
    }

    /// @notice Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the contract, through a withdraw call. Includes fee.
    /// @param _owner The address to check
    /// @return _maxAssetsOut The maximum amount of underlying asset that can be withdrawn
    /**
     * @dev See {IERC4626-maxWithdraw}
     * Lesser of
     *     a) User vaultTkn -> underlyingTkn amount
     *     b) Contract underlyingTkn balance
     */
    function maxWithdraw(address _owner) public view returns (uint256 _maxAssetsOut) {
        // See how much underlyingTkn the user could possibly withdraw with 100% of his vaultTkn
        uint256 _maxAssetsUser = previewRedeem(vaultTkn.balanceOf(address(_owner)));

        // See how much underlyingTkn is actually available in the contract
        uint256 _assetBalanceContract = underlyingTkn.balanceOf(address(this));

        // Return the lesser of the two
        _maxAssetsOut = ((_assetBalanceContract > _maxAssetsUser) ? _maxAssetsUser : _assetBalanceContract);
    }

    /// @notice Returns the maximum amount of shares that can be redeemed from the owner balance in the contract, through a redeem call. Includes fee.
    /// @param _owner The address to check
    /// @return _maxSharesIn The maximum amount of shares that can be redeemed
    /**
     * @dev See {IERC4626-maxRedeem}
     * Lesser of
     *     a) User vaultTkn
     *     b) Contract underlyingTkn -> vaultTkn amount
     */
    function maxRedeem(address _owner) public view returns (uint256 _maxSharesIn) {
        // See how much vaultTkn the contract could honor if 100% of its underlyingTkn was redeemed
        uint256 _maxSharesContract = previewWithdraw(underlyingTkn.balanceOf(address(this)));

        // See how much vaultTkn the user has
        uint256 _sharesBalanceUser = vaultTkn.balanceOf(address(_owner));

        // Return the lesser of the two
        _maxSharesIn = ((_maxSharesContract > _sharesBalanceUser) ? _sharesBalanceUser : _maxSharesContract);
    }

    /// @notice Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given current on-chain conditions.
    /// @param _assetsIn Amount of underlying you want to deposit
    /// @return _sharesOut The amount of output shares expected
    /// @dev See {IERC4626-previewDeposit}
    function previewDeposit(uint256 _assetsIn) public view returns (uint256 _sharesOut) {
        if (fee > 0) _assetsIn -= Math.mulDiv(fee, _assetsIn, 1e18, Math.Rounding.Up);
        _sharesOut = _convertToShares(_assetsIn, Math.Rounding.Down);
    }

    /// @notice Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given current on-chain conditions.
    /// @param _sharesOut Amount of shares you want to mint
    /// @return _assetsIn The amount of input assets needed
    /// @dev See {IERC4626-previewMint}
    function previewMint(uint256 _sharesOut) public view returns (uint256 _assetsIn) {
        _assetsIn = _convertToAssets(_sharesOut, Math.Rounding.Up);
        if (fee > 0) _assetsIn += Math.mulDiv(fee, _assetsIn, 1e18, Math.Rounding.Up);
    }

    /// @notice Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block, given current on-chain conditions.
    /// @param _assetsOut Amount of underlying tokens you want to get back
    /// @return _sharesIn Amount of shares needed
    /// @dev See {IERC4626-previewWithdraw}
    function previewWithdraw(uint256 _assetsOut) public view returns (uint256 _sharesIn) {
        if (fee > 0) _assetsOut += Math.mulDiv(fee, _assetsOut, 1e18, Math.Rounding.Up);
        _sharesIn = _convertToShares(_assetsOut, Math.Rounding.Up);
    }

    /// @notice Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block, given current on-chain conditions.
    /// @param _sharesIn Amount of shares you want to redeem
    /// @return _assetsOut Amount of output asset expected
    /// @dev See {IERC4626-previewRedeem}
    function previewRedeem(uint256 _sharesIn) public view returns (uint256 _assetsOut) {
        _assetsOut = _convertToAssets(_sharesIn, Math.Rounding.Down);
        if (fee > 0) _assetsOut -= Math.mulDiv(fee, _assetsOut, 1e18, Math.Rounding.Up);
    }

    // ERC4626 INTERNAL VIEWS
    // ===================================================

    /// @dev Internal conversion function (from assets to shares) with support for rounding direction.
    /// @param _assets Amount of underlying tokens to convert to shares
    /// @param _rounding Math.Rounding rounding direction
    /// @return _shares Amount of shares represented by the given underlying tokens
    function _convertToShares(uint256 _assets, Math.Rounding _rounding) internal view returns (uint256 _shares) {
        _shares = Math.mulDiv(
            _assets,
            uint256(getLatestUnderlyingPriceE18()),
            uint256(getVaultTknPriceStoredE18()),
            _rounding
        );
    }

    /// @dev Internal conversion function (from shares to assets) with support for rounding direction
    /// @param _shares Amount of shares to convert to underlying tokens
    /// @param _rounding Math.Rounding rounding direction
    /// @return _assets Amount of underlying tokens represented by the given number of shares
    function _convertToAssets(uint256 _shares, Math.Rounding _rounding) internal view returns (uint256 _assets) {
        _assets = Math.mulDiv(
            _shares,
            uint256(getVaultTknPriceStoredE18()),
            uint256(getLatestUnderlyingPriceE18()),
            _rounding
        );
    }

    /// @notice Price of 1E18 shares, in asset tokens
    /// @return _pricePerShare How many underlying asset tokens per 1E18 shares
    function pricePerShare() external view returns (uint256 _pricePerShare) {
        _pricePerShare = _convertToAssets(1e18, Math.Rounding.Down);
    }

    // ADDITIONAL PUBLIC VIEWS
    // ===================================================

    /// @notice Helper view for max deposit, mint, withdraw, and redeem inputs
    /// @return _maxAssetsDepositable Max amount of underlying asset you can deposit
    /// @return _maxSharesMintable Max number of shares that can be minted
    /// @return _maxAssetsWithdrawable Max amount of underlying asset withdrawable
    /// @return _maxSharesRedeemable Max number of shares redeemable
    function mdwrComboView()
        public
        view
        returns (
            uint256 _maxAssetsDepositable,
            uint256 _maxSharesMintable,
            uint256 _maxAssetsWithdrawable,
            uint256 _maxSharesRedeemable
        )
    {
        return (
            previewMint(vaultTkn.balanceOf(address(this))),
            vaultTkn.balanceOf(address(this)),
            underlyingTkn.balanceOf(address(this)),
            previewWithdraw(underlyingTkn.balanceOf(address(this)))
        );
    }

    // ERC4626 INTERNAL MUTATORS
    // ===================================================

    /// @notice Deposit/mint common workflow.
    /// @param _caller The caller
    /// @param _receiver Reciever of the shares
    /// @param _assets Amount of assets taken in
    /// @param _shares Amount of shares given out
    function _deposit(address _caller, address _receiver, uint256 _assets, uint256 _shares) internal nonReentrant {
        // If _asset is ERC-777, `transferFrom` can trigger a reentrancy BEFORE the transfer happens through the
        // `tokensToSend` hook. On the other hand, the `tokenReceived` hook, that is triggered after the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer beforehand so that any reentrancy would happen before the
        // _assets are transferred and before the _shares are minted, which is a valid state.
        // slither-disable-next-line reentrancy-no-eth

        // Take in the assets
        // User will need to approve _caller -> address(this) first
        SafeERC20.safeTransferFrom(IERC20(address(underlyingTkn)), _caller, address(this), _assets);

        // Transfer out the shares
        SafeERC20.safeTransfer(IERC20(address(vaultTkn)), _receiver, _shares);

        emit Deposit(_caller, _receiver, _assets, _shares);
    }

    /// @notice Withdraw/redeem common workflow.
    /// @param _caller The caller
    /// @param _receiver Reciever of the assets
    /// @param _owner The owner of the shares
    /// @param _assets Amount of assets given out
    /// @param _shares Amount of shares taken in
    function _withdraw(
        address _caller,
        address _receiver,
        address _owner,
        uint256 _assets,
        uint256 _shares
    ) internal nonReentrant {
        // If _asset is ERC-777, `transfer` can trigger a reentrancy AFTER the transfer happens through the
        // `tokensReceived` hook. On the other hand, the `tokensToSend` hook, that is triggered before the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer afterwards so that any reentrancy would happen after the
        // _shares are burned and after the _assets are transferred, which is a valid state.

        // Take in the shares
        // User will need to approve owner -> address(this) first
        SafeERC20.safeTransferFrom(IERC20(address(vaultTkn)), _owner, address(this), _shares);

        // Transfer out the assets
        SafeERC20.safeTransfer(IERC20(address(underlyingTkn)), _receiver, _assets);

        emit Withdraw(_caller, _receiver, _owner, _assets, _shares);
    }

    // ERC4626 PUBLIC/EXTERNAL MUTATIVE
    // ===================================================

    /// @notice Deposit a specified amount of underlying tokens and generate shares. Make sure to approve msg.sender's assets to this contract first.
    /// @param _assetsIn Amount of underlying tokens you are depositing
    /// @param _receiver Recipient of the generated shares
    /// @return _sharesOut Amount of shares generated by the deposit
    /// @dev See {IERC4626-deposit}
    function deposit(uint256 _assetsIn, address _receiver) public returns (uint256 _sharesOut) {
        // Update the oracle if necessary
        updateVaultTknOracle();

        // See how many asset tokens the user can deposit
        uint256 _maxAssets = maxDeposit(_receiver);

        // Revert if the user is trying to deposit too many asset tokens
        if (_assetsIn > _maxAssets) {
            revert ERC4626ExceededMaxDeposit(_receiver, _assetsIn, _maxAssets);
        }

        // See how many shares would be generated with the specified number of asset tokens
        _sharesOut = previewDeposit(_assetsIn);

        // Do the deposit
        _deposit(msg.sender, _receiver, _assetsIn, _sharesOut);
    }

    /// @notice Mint a specified amount of shares using underlying asset tokens. Make sure to approve msg.sender's assets to this contract first.
    /// @param _sharesOut Amount of shares you want to mint
    /// @param _receiver Recipient of the minted shares
    /// @return _assetsIn Amount of assets used to generate the shares
    /// @dev See {IERC4626-mint}
    function mint(uint256 _sharesOut, address _receiver) public returns (uint256 _assetsIn) {
        // Update the oracle if necessary
        updateVaultTknOracle();

        // See how many shares the user's can mint
        uint256 _maxShares = maxMint(_receiver);

        // Revert if you are trying to mint too many shares
        if (_sharesOut > _maxShares) {
            revert ERC4626ExceededMaxMint(_receiver, _sharesOut, _maxShares);
        }

        // See how many asset tokens are needed to generate the specified amount of shares
        _assetsIn = previewMint(_sharesOut);

        // Do the minting
        _deposit(msg.sender, _receiver, _assetsIn, _sharesOut);
    }

    /// @notice Withdraw a specified amount of underlying tokens. Make sure to approve _owner's shares to this contract first
    /// @param _assetsOut Amount of asset tokens you want to withdraw
    /// @param _receiver Recipient of the asset tokens
    /// @param _owner Owner of the shares. Must be msg.sender
    /// @return _sharesIn Amount of shares used for the withdrawal
    /// @dev See {IERC4626-withdraw}. Leaving _owner param for ABI compatibility
    function withdraw(uint256 _assetsOut, address _receiver, address _owner) public returns (uint256 _sharesIn) {
        // Make sure _owner is msg.sender
        if (_owner != msg.sender) revert TokenOwnerShouldBeSender();

        // Update the oracle if necessary
        updateVaultTknOracle();

        // See how much assets the owner can withdraw
        uint256 _maxAssets = maxWithdraw(_owner);

        // Revert if you are trying to withdraw too many asset tokens
        if (_assetsOut > _maxAssets) {
            revert ERC4626ExceededMaxWithdraw(_owner, _assetsOut, _maxAssets);
        }

        // See how many shares are needed
        _sharesIn = previewWithdraw(_assetsOut);

        // Do the withdrawal
        _withdraw(msg.sender, _receiver, _owner, _assetsOut, _sharesIn);
    }

    /// @notice Redeem a specified amount of shares for the underlying tokens. Make sure to approve _owner's shares to this contract first.
    /// @param _sharesIn Number of shares to redeem
    /// @param _receiver Recipient of the underlying asset tokens
    /// @param _owner Owner of the shares being redeemed. Must be msg.sender.
    /// @return _assetsOut Amount of underlying tokens out
    /// @dev See {IERC4626-redeem}. Leaving _owner param for ABI compatibility
    function redeem(uint256 _sharesIn, address _receiver, address _owner) public returns (uint256 _assetsOut) {
        // Make sure _owner is msg.sender
        if (_owner != msg.sender) revert TokenOwnerShouldBeSender();

        // Update the oracle if necessary
        updateVaultTknOracle();

        // See how many shares the owner can redeem
        uint256 _maxShares = maxRedeem(_owner);

        // Revert if you are trying to redeem too many shares
        if (_sharesIn > _maxShares) {
            revert ERC4626ExceededMaxRedeem(_owner, _sharesIn, _maxShares);
        }

        // See how many asset tokens are expected
        _assetsOut = previewRedeem(_sharesIn);

        // Do the redemption
        _withdraw(msg.sender, _receiver, _owner, _assetsOut, _sharesIn);
    }

    /// @notice Update the vault token price, if necessary
    function updateVaultTknOracle() public {
        // Read from the oracle
        uint256 fetchedPrice = uint256(getLatestVaultTknPriceE18());

        if (block.timestamp == lastVaultTknOracleRead) return ();

        // Set the new vault token price
        vaultTknPrice = fetchedPrice;

        // Note: this ignores updatedAt that is returned by the oracle
        lastVaultTknOracleRead = block.timestamp;
    }

    // RESTRICTED FUNCTIONS
    // ===================================================

    /// @notice Set the underlyingTkn and vaultTkn price oracles
    /// @param _underlyingOracleAddr Address of the underlyingTkn price oracle
    /// @param _vaultOracleAddr Address of the vaultTkn price oracle
    function setOracles(address _underlyingOracleAddr, address _vaultOracleAddr) public onlyOwner {
        // Check for zero addresses on the vaultTkn oracle only. underlyingTkn can be 0x0; its price will default to 1e18
        require(_vaultOracleAddr != address(0), "Zero address detected");

        // Set the oracles
        priceFeedUnderlying = AggregatorV3Interface(_underlyingOracleAddr);
        priceFeedVault = AggregatorV3Interface(_vaultOracleAddr);
    }

    /// @notice Set the fee for the contract on mint|deposit/redeem|withdraw flow
    /// @param _fee The new fee to set, (In denominations of underlying & vault token)
    function setMintRedeemFee(uint256 _fee) public onlyOwner {
        require(_fee < 1 * (10 ** decimals), "Fee must be a fraction of underlying");
        fee = _fee;
    }

    /// @notice Set the max time an oracle can be stale before reverting
    /// @param _secs Seconds of tolerance
    function setOracleTimeTolerance(uint256 _secs) public onlyOwner {
        oracleTimeTolerance = _secs;
    }

    /// @notice Added to support tokens
    /// @param _tokenAddress The token to recover
    /// @param _tokenAmount The amount to recover
    function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        // Only the owner address can ever receive the recovery withdrawal
        SafeERC20.safeTransfer(IERC20(_tokenAddress), owner, _tokenAmount);
        emit RecoveredERC20(_tokenAddress, _tokenAmount);
    }

    // EVENTS
    // ===================================================

    /// @notice When a deposit/mint has occured
    /// @param sender The transaction sender
    /// @param owner The owner of the assets
    /// @param assets Amount of assets taken in
    /// @param shares Amount of shares given out
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    /// @notice When ERC20 tokens were recovered
    /// @param token Token address
    /// @param amount Amount of tokens collected
    event RecoveredERC20(address token, uint256 amount);

    /// @notice When a withdrawal/redemption has occured
    /// @param sender The transaction sender
    /// @param receiver Reciever of the assets
    /// @param owner The owner of the shares
    /// @param assets Amount of assets given out
    /// @param shares Amount of shares taken in
    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    // ERRORS
    // ===================================================

    /// @notice Attempted to deposit more assets than the max amount for `receiver`
    /// @param receiver The intended recipient of the shares
    /// @param assets The amount of underlying that was attempted to be deposited
    /// @param max Max amount of underlying depositable
    error ERC4626ExceededMaxDeposit(address receiver, uint256 assets, uint256 max);

    /// @notice Attempted to mint more shares than the max amount for `receiver`
    /// @param receiver The intended recipient of the shares
    /// @param shares The number of shares that was attempted to be minted
    /// @param max Max number of shares mintable
    error ERC4626ExceededMaxMint(address receiver, uint256 shares, uint256 max);

    /// @notice Attempted to withdraw more assets than the max amount for `receiver`
    /// @param owner The owner of the shares
    /// @param assets The amount of underlying that was attempted to be withdrawn
    /// @param max Max amount of underlying withdrawable
    error ERC4626ExceededMaxWithdraw(address owner, uint256 assets, uint256 max);

    /// @notice Attempted to redeem more shares than the max amount for `receiver`
    /// @param owner The owner of the shares
    /// @param shares The number of shares that was attempted to be redeemed
    /// @param max Max number of shares redeemable
    error ERC4626ExceededMaxRedeem(address owner, uint256 shares, uint256 max);

    /// @notice Cannot initialize twice
    error InitializeFailed();

    /// @notice When an oracle returns an invalid price
    /// @param symbol Symbol of the token whose oracle has an invalid price
    error InvalidOraclePrice(string symbol);

    /// @notice When an oracle returns an invalid roundID
    /// @param symbol Symbol of the token whose oracle has an invalid roundID
    error InvalidOracleRoundID(string symbol);

    /// @notice When the price of the oracle is stale
    /// @param symbol Symbol of the token whose oracle is stale
    error OracleIsStale(string symbol);

    /// @notice When you are attempting to pull tokens from an owner address that is not msg.sender
    error TokenOwnerShouldBeSender();
}
