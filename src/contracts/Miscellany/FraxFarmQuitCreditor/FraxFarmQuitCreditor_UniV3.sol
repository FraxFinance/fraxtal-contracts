// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ==================== FraxFarmQuitCreditor_UniV3 ====================
// ====================================================================
// Exits a Frax UniV3 farm and credits a USD value to a special contract on Fraxtal (L1QuitCreditorReceiverConverter),
// which can be converted there into another token, such as an FXB

// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)
// Travis Moore: https://github.com/FortisFortuna

// Reviewer(s) / Contributor(s)
// Dennis: https://github.com/denett
// Carter Carlson: https://github.com/pegahcarter
// Thomas Clement: https://github.com/tom2o17

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { INonfungiblePositionManager, IFraxFarmUniV3 } from "./Imports.sol";
import { OwnedV2 } from "src/contracts/Miscellany/OwnedV2.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IL1CrossDomainMessenger } from "./IL1CrossDomainMessenger.sol";
import { L1QuitCreditorReceiverConverter } from "./L1QuitCreditorReceiverConverter.sol";

/// @notice Exits a Frax UniV3 farm and credits a USD value to a special contract on Fraxtal, which can be converted there into another token, such as an FXB
/// @dev Make sure to enable this contract as a migrator first on the target farm
contract FraxFarmQuitCreditor_UniV3 is ReentrancyGuard, OwnedV2 {
    // STATE VARIABLES
    // ===================================================

    /// @notice The farm holding the UniV3 NFT
    IFraxFarmUniV3 public farm;

    /// @notice The NFT
    INonfungiblePositionManager public nft = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    /// @notice token0 for the NFT
    IERC20Metadata public token0;

    /// @notice token1 for the NFT
    IERC20Metadata public token1;

    /// @notice token0 and token1 missing decimals away from 18. So FRAX would have 0, while USDC would have 12
    uint256[2] public missingDecimals;

    /// @notice FXS reward tokens
    IERC20Metadata public fxsToken = IERC20Metadata(0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0);

    /// @notice On Fraxtal. Accepts a cross-chain message and converts the USD value to another specified token
    address public fxtlL1QuitCdRecCvtrAddr;

    /// @notice L1CrossDomainMessenger for sending messages to Fraxtal
    IL1CrossDomainMessenger public l1CrossDomainMessenger =
        IL1CrossDomainMessenger(0x126bcc31Bc076B3d515f60FBC81FddE0B0d542Ed);

    /// @notice Minimum gas limit for the L1CrossDomainMessenger sendMessage
    uint32 public minGasLimit = 500_000;

    // CONSTRUCTOR
    // ===================================================

    /// @param _owner The owner of the contract
    /// @param _fxtlL1QuitCdRecCvtrAddr On Fraxtal. Accepts a cross-chain message and converts the USD value to another specified token
    /// @param _farm The address of the UniV3 farm.
    constructor(address _owner, address _fxtlL1QuitCdRecCvtrAddr, address _farm) OwnedV2(_owner) {
        fxtlL1QuitCdRecCvtrAddr = _fxtlL1QuitCdRecCvtrAddr;
        farm = IFraxFarmUniV3(_farm);
        token0 = IERC20Metadata(IFraxFarmUniV3(_farm).uni_token0());
        token1 = IERC20Metadata(IFraxFarmUniV3(_farm).uni_token1());

        // Check missing decimals
        missingDecimals[0] = 18 - token0.decimals();
        missingDecimals[1] = 18 - token1.decimals();
    }

    // INTERNAL
    // ===================================================

    /// @notice Internal logic for withdrawing and unwinding the NFT
    /// @param _tknId ID of the NFT
    /// @param _liquidity Liquidity of the NFT
    /// @return _tokensOutOne token0 fees, token1 fees, token0 principal, token1 principal respectively. Fees goes to the original farmer, principals to this QuitCreditor contract for later collection
    function _withdrawLogic(uint256 _tknId, uint256 _liquidity) internal returns (uint256[4] memory _tokensOutOne) {
        // Do the withdrawal
        farm.migrator_withdraw_locked(msg.sender, _tknId);

        // Prepare to collect token0 and token1 fees and send to the original staker
        INonfungiblePositionManager.CollectParams memory _collectParams = INonfungiblePositionManager.CollectParams(
            _tknId,
            msg.sender,
            type(uint128).max,
            type(uint128).max
        );

        // Do the collection
        {
            // Collect fees
            (uint256 _fees0Out, uint256 fees1Out) = nft.collect(_collectParams);

            // Note the collected fees
            _tokensOutOne[0] += _fees0Out;
            _tokensOutOne[1] += fees1Out;
        }

        // Remove the principal and fees
        {
            // Prepare to remove the principal and fees
            INonfungiblePositionManager.DecreaseLiquidityParams memory _decLiqParams = INonfungiblePositionManager
                .DecreaseLiquidityParams(
                    _tknId,
                    uint128(_liquidity),
                    0, // If frontrun, it will be all $1 tokens anyways
                    0, // If frontrun, it will be all $1 tokens anyways
                    block.timestamp + 604_800
                );

            // Decrease the liquidity (DOES NOT ACTUALLY TRANSFER OUT TOKEN0 AND TOKEN1 YET)
            (uint256 _principal0Out, uint256 _principal1Out) = nft.decreaseLiquidity(_decLiqParams);

            // Prepare to collect the principal + fees
            _collectParams = INonfungiblePositionManager.CollectParams(
                _tknId,
                address(this),
                type(uint128).max,
                type(uint128).max
            );

            // Do the collection
            nft.collect(_collectParams);

            // Note the collected principals. Fees were accounted for before.
            // Principals will be kept in this contract for later recovery
            _tokensOutOne[2] += _principal0Out;
            _tokensOutOne[3] += _principal1Out;
        }

        // Burn the NFT
        nft.burn(_tknId);
    }

    /// @notice Exits NFTs and sends a message to Fraxtal indicating how much FXB the user is entitled to
    /// @param _recipientOnFraxtal Recipient address on Fraxtal
    /// @param _onlyExitOne If you are only exiting one NFT. Needed in case _nftId is legitimately 0
    /// @param _nftId The single NFT Id to exit
    /// @return _totalLiquidity Sum total of all of the NFTs' liquidities
    /// @return _tokensOut FXS rewards, token0 fees, token1 fees, token0 principal, token1 principal respectively. Fees goes to the original farmer, principals to this QuitCreditor contract for later collection
    /// @return _usdCredit The calculated USD value of the NFTs. Info will be "sent" to Fraxtal for conversion into a specified token there.
    /// @return _encodedMessage Encoded message to send to the Fraxtal L1QuitCreditorReceiverConverter
    function _exitForCredit(
        address _recipientOnFraxtal,
        bool _onlyExitOne,
        uint256 _nftId
    )
        internal
        nonReentrant
        returns (
            uint256 _totalLiquidity,
            uint256[5] memory _tokensOut,
            uint256 _usdCredit,
            bytes memory _encodedMessage
        )
    {
        // Check the recipient
        if (_recipientOnFraxtal == address(0)) revert InvalidRecipient();

        // Get all locked NFTs of the sender
        IFraxFarmUniV3.LockedNFT[] memory lockedNFTs = farm.lockedNFTsOf(msg.sender);

        // Note FXS balance before
        uint256 _fxsBefore = fxsToken.balanceOf(address(this));

        // Loop through the NFTs and withdraw them here
        for (uint256 i; i < lockedNFTs.length; ) {
            // Get token info
            uint256 _tknId = lockedNFTs[i].token_id;
            uint256 _liquidity = lockedNFTs[i].liquidity;

            // Proceed if there is liquidity
            if (_liquidity > 0) {
                if (_onlyExitOne && !(_tknId == _nftId)) {
                    // Do nothing
                } else {
                    // Withdraw one NFT
                    uint256[4] memory _tokensOutOne = _withdrawLogic(_tknId, _liquidity);

                    // Accounting
                    _tokensOut[1] += _tokensOutOne[0];
                    _tokensOut[2] += _tokensOutOne[1];
                    _tokensOut[3] += _tokensOutOne[2];
                    _tokensOut[4] += _tokensOutOne[3];

                    // Tally the total liquidity
                    _totalLiquidity += _liquidity;

                    // Break if _onlyExitOne is true
                    if (_onlyExitOne) break;
                }
            }

            unchecked {
                ++i;
            }
        }

        // Make sure there is something to actually unlock
        if (_totalLiquidity == 0) revert NothingToUnlock();

        // Note the FXS balance change
        _tokensOut[0] = fxsToken.balanceOf(address(this)) - _fxsBefore;

        // Send the FXS rewards to the original staker
        SafeERC20.safeTransfer(fxsToken, msg.sender, _tokensOut[0]);

        // Send the fees to the original staker
        SafeERC20.safeTransfer(token0, msg.sender, _tokensOut[1]);
        SafeERC20.safeTransfer(token1, msg.sender, _tokensOut[2]);

        // Assume token0 and token1 are both worth $1 per 1x10^(decimals)
        _usdCredit = (_tokensOut[3] * (10 ** missingDecimals[0])) + (_tokensOut[4] * (10 ** missingDecimals[1]));

        // Create the encoded message
        _encodedMessage = abi.encodeCall(
            L1QuitCreditorReceiverConverter.processMessage,
            (msg.sender, _recipientOnFraxtal, _usdCredit)
        );

        // Send the message to Fraxtal via the L1CrossDomainMessenger
        l1CrossDomainMessenger.sendMessage(fxtlL1QuitCdRecCvtrAddr, _encodedMessage, minGasLimit);

        emit MessageSent(msg.sender, _recipientOnFraxtal, _usdCredit, _tokensOut);
    }

    // PUBLIC FUNCTIONS
    // ===================================================

    /// @notice Exits all NFTs and sends a message to Fraxtal indicating how much FXB the user is entitled to
    /// @param _recipientOnFraxtal Recipient address on Fraxtal
    /// @return _totalLiquidity Sum total of all of the NFTs' liquidities
    /// @return _tokensOut FXS rewards, token0 fees, token1 fees, token0 principal, token1 principal respectively. Fees goes to the original farmer, principals to this QuitCreditor contract for later collection
    /// @return _usdCredit The calculated USD value of the NFTs. Info will be "sent" to Fraxtal for conversion into a specified token there.
    /// @return _encodedMessage Encoded message to send to the Fraxtal L1QuitCreditorReceiverConverter
    function exitAllForCredit(
        address _recipientOnFraxtal
    )
        external
        returns (
            uint256 _totalLiquidity,
            uint256[5] memory _tokensOut,
            uint256 _usdCredit,
            bytes memory _encodedMessage
        )
    {
        return _exitForCredit(_recipientOnFraxtal, false, 0);
    }

    /// @notice Exits a single NFT and sends a message to Fraxtal indicating how much FXB the user is entitled to
    /// @param _recipientOnFraxtal Recipient address on Fraxtal
    /// @param _nftId The NFT ID to exit
    /// @return _totalLiquidity Sum total of all of the NFTs' liquidities
    /// @return _tokensOut FXS rewards, token0 fees, token1 fees, token0 principal, token1 principal respectively. Fees goes to the original farmer, principals to this QuitCreditor contract for later collection
    /// @return _usdCredit The calculated USD value of the NFTs. Info will be "sent" to Fraxtal for conversion into a specified token there.
    /// @return _encodedMessage Encoded message to send to the Fraxtal L1QuitCreditorReceiverConverter
    function exitOneForCredit(
        address _recipientOnFraxtal,
        uint256 _nftId
    )
        external
        returns (
            uint256 _totalLiquidity,
            uint256[5] memory _tokensOut,
            uint256 _usdCredit,
            bytes memory _encodedMessage
        )
    {
        return _exitForCredit(_recipientOnFraxtal, true, _nftId);
    }

    /// @notice to indicate that this contract is ERC721 compatible
    function onERC721Received(address, address, uint256, bytes memory) public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /// @notice Used to test connectivity. Sends a dummy message to Fraxtal
    function ping() external nonReentrant {
        // Send the message to Fraxtal via the L1CrossDomainMessenger
        l1CrossDomainMessenger.sendMessage(
            fxtlL1QuitCdRecCvtrAddr,
            abi.encodeCall(L1QuitCreditorReceiverConverter.receivePing, (msg.sender, block.timestamp)),
            minGasLimit
        );

        emit PingSent(msg.sender, block.timestamp);
    }

    // RESTRICTED FUNCTIONS
    // ===================================================

    /// @notice Collect all token0 and token1 in the contract
    function collectAllTkn0AndTkn1() external onlyOwner returns (uint256[2] memory _tknsOut) {
        // Note balances
        _tknsOut[0] = token0.balanceOf(address(this));
        _tknsOut[1] = token1.balanceOf(address(this));

        // Send the tokens
        SafeERC20.safeTransfer(token0, msg.sender, _tknsOut[0]);
        SafeERC20.safeTransfer(token1, msg.sender, _tknsOut[1]);
    }

    /// @notice Allows the owner to recover any ERC20
    /// @param tokenAddress The address of the token to recover
    /// @param tokenAmount The amount of the token to recover
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        SafeERC20.safeTransfer(IERC20Metadata(tokenAddress), msg.sender, tokenAmount);
    }

    /// @notice Allows the owner to recover any ERC721
    /// @param tokenAddress The address of the token to recover
    /// @param token_id The NFT id to recover
    function recoverERC721(address tokenAddress, uint256 token_id) external onlyOwner {
        // Only the owner address can ever receive the recovery withdrawal
        // INonfungiblePositionManager inherits IERC721 so the latter does not need to be imported
        INonfungiblePositionManager(tokenAddress).safeTransferFrom(address(this), owner, token_id);
        emit RecoveredERC721(tokenAddress, token_id);
    }

    /// @notice Set the address for the L1QuitCreditorReceiverConverter located on Fraxtal
    /// @param _newFxtlL1QuitCdRecCvtrAddr The new address for the L1QuitCreditorReceiverConverter
    function setFxtlL1QuitCdRecCvtrAddr(address _newFxtlL1QuitCdRecCvtrAddr) external onlyOwner {
        fxtlL1QuitCdRecCvtrAddr = _newFxtlL1QuitCdRecCvtrAddr;
    }

    /// @notice Set the min gas limit for the L1CrossDomainMessenger
    /// @param _minGasLimit Minimum gas limit
    function setXChainMinGasLimit(uint32 _minGasLimit) external onlyOwner {
        minGasLimit = _minGasLimit;
    }

    // ERRORS
    // ===================================================

    /// @notice When the Fraxtal recipient is invalid
    error InvalidRecipient();

    /// @notice When there are no NFTs to unlock
    error NothingToUnlock();

    // EVENTS
    // ===================================================

    /// @notice When the ping to L2 was sent
    /// @param sender The msg.sender that triggered the ping
    /// @param ts Time the ping was sent
    event PingSent(address indexed sender, uint256 ts);

    /// @notice When the crediting message to L2 was sent
    /// @param originalStaker Address of the original farmer who held the position
    /// @param recipient Recipient for the newly converted tokens
    /// @param usdCredit Amount of USD credit processed
    /// @param tokensOut FXS rewards, token0 fees, token1 fees, token0 principal, token1 principal respectively. Fees goes to the original farmer, principals to this QuitCreditor contract for later collection
    event MessageSent(
        address indexed originalStaker,
        address indexed recipient,
        uint256 usdCredit,
        uint256[5] tokensOut
    );

    /// @notice When ERC20 tokens were recovered
    /// @param token Token address
    /// @param amount Amount of tokens collected
    event RecoveredERC20(address token, uint256 amount);

    /// @notice When ERC721 tokens were recovered
    /// @param tokenAddress NFT address
    /// @param tokenId ID of the recovered NFT
    event RecoveredERC721(address tokenAddress, uint256 tokenId);
}
