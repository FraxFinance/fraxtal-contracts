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
// ================= L1QuitCreditorReceiverConverter ==================
// ====================================================================
// Accepts an L1 message from an Ethereum Mainnet FraxFarmQuitCreditor_XXX and converts the provided USD value to another token

// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)
// Travis Moore: https://github.com/FortisFortuna

// Reviewer(s) / Contributor(s)
// Dennis: https://github.com/denett

import { SafeERC20 } from "@openzeppelin-4/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin-4/contracts/token/ERC20/IERC20.sol";
import { OwnedV2 } from "src/contracts/Miscellany/OwnedV2.sol";
import { ReentrancyGuard } from "@openzeppelin-4/contracts/security/ReentrancyGuard.sol";
import { ICrossDomainMessenger } from "./ICrossDomainMessenger.sol";
import { IExponentialPriceOracle } from "./IExponentialPriceOracle.sol";

/// @notice Accepts an L1 message from an Ethereum Mainnet FraxFarmQuitCreditor_XXX and converts the provided USD value to another token
contract L1QuitCreditorReceiverConverter is ReentrancyGuard, OwnedV2 {
    // STATE VARIABLES
    // ===================================================

    /// @notice Fraxtal CrossDomainMessenger
    ICrossDomainMessenger public messenger = ICrossDomainMessenger(0x4200000000000000000000000000000000000007);

    /// @notice Address of the L1 FraxFarmQuitCreditor_XXX
    address public quitCreditorAddress;

    /// @notice Token that the L1 USD credit is being exchanged for
    IERC20 public conversionToken;

    /// @notice Manually set conversion price (USDe18 per 1e18 conversion token)
    uint256 public conversionPrice;

    /// @notice Used for testing
    mapping(address pinger => Ping lastPing) public lastPingReceived;

    // STRUCTS
    // ===================================================

    /// @notice Ping used for testing purposes
    /// @param sourceTs Timestamp the ping was triggered on Ethereum
    /// @param fraxtalTs Timestamp the ping was received on this contract
    struct Ping {
        uint256 sourceTs;
        uint256 fraxtalTs;
    }

    // MODIFIERS
    // ===================================================

    modifier correctSender() {
        // Make sure the direct msg.sender is the messenger
        if (msg.sender != address(messenger)) revert BadSender();

        // Make sure that the caller on L1 was the FraxFarmQuitCreditor_XXX
        if (messenger.xDomainMessageSender() != quitCreditorAddress) revert BadXDomainMessageSender();

        _;
    }

    // CONSTRUCTOR
    // ===================================================

    /// @notice Constructor
    /// @param _owner The owner of the contract
    /// @param _quitCreditor Address of the L1 FraxFarmQuitCreditor_XXX
    /// @param _conversionToken Token being converted to
    /// @param _conversionPrice Price of the conversion token, in E18 USD
    constructor(
        address _owner,
        address _quitCreditor,
        address _conversionToken,
        uint256 _conversionPrice
    ) OwnedV2(_owner) {
        quitCreditorAddress = _quitCreditor;
        conversionToken = IERC20(_conversionToken);
        conversionPrice = _conversionPrice;
    }

    // PUBLIC FUNCTIONS
    // ===================================================

    /// @notice Used to test connectivity. Receives a dummy message from Ethereum
    /// @param _pinger Original pinger on Ethereum
    /// @param _sourceTs Time the ping was sent on Ethereum
    function receivePing(address _pinger, uint256 _sourceTs) external nonReentrant correctSender {
        // Mark when the last ping was received
        lastPingReceived[_pinger] = Ping(_sourceTs, block.timestamp);

        emit PingReceived(_pinger, _sourceTs, block.timestamp);
    }

    /// @notice Processes the L1-originating message from the FraxFarmQuitCreditor_XXX
    /// @param _originalStaker Address of the original farmer who held the position
    /// @param _recipient Recipient for the newly converted tokens
    /// @param _usdCredit The USD value that should be converted into the conversion token
    function processMessage(
        address _originalStaker,
        address _recipient,
        uint256 _usdCredit
    ) external nonReentrant correctSender returns (uint256 _convTknOut) {
        // Do the conversion
        _convTknOut = (_usdCredit * 1e18) / conversionPrice;

        // Send out the tokens
        SafeERC20.safeTransfer(conversionToken, _recipient, _convTknOut);

        emit MessageProcessed(_originalStaker, _recipient, _usdCredit, _convTknOut);
    }

    // RESTRICTED FUNCTIONS
    // ===================================================

    /// @notice Allows the owner to recover any ERC20
    /// @param tokenAddress The address of the token to recover
    /// @param tokenAmount The amount of the token to recover
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        SafeERC20.safeTransfer(IERC20(tokenAddress), msg.sender, tokenAmount);
    }

    /// @notice Set the price of the conversion token, in E18 USD
    /// @param _newConversionPrice The new conversion price
    function setConversionPrice(uint256 _newConversionPrice) external onlyOwner {
        conversionPrice = _newConversionPrice;
    }

    /// @notice Set the address for the L1 FraxFarmQuitCreditor_XXX
    /// @param _newQuitCreditorAddress The new address for the L1 FraxFarmQuitCreditor_XXX
    function setQuitCreditorAddress(address _newQuitCreditorAddress) external onlyOwner {
        quitCreditorAddress = _newQuitCreditorAddress;
    }

    // ERRORS
    // ===================================================

    /// @notice Only the CrossDomainMessenger should be the sender
    error BadSender();

    /// @notice Only the FraxFarmQuitCreditor_XXX should be the messenger.xDomainMessageSender()
    error BadXDomainMessageSender();

    // EVENTS
    // ===================================================

    /// @notice When the ping from L1 was received
    /// @param sender The msg.sender that triggered the ping on the FraxFarmQuitCreditor_XXX
    /// @param sourceTs Ethereum time the ping was received
    /// @param fraxtalTs Fraxtal time the ping was received
    event PingReceived(address indexed sender, uint256 sourceTs, uint256 fraxtalTs);

    /// @notice When the crediting message from the L1 FraxFarmQuitCreditor_XXX was processed
    /// @param originalStaker Address of the original farmer who held the position
    /// @param recipient Recipient for the newly converted tokens
    /// @param usdCredit Amount of USD credit processed
    /// @param convTknOut Conversion token output amount to the recipient
    event MessageProcessed(
        address indexed originalStaker,
        address indexed recipient,
        uint256 usdCredit,
        uint256 convTknOut
    );

    /// @notice When ERC20 tokens were recovered
    /// @param token Token address
    /// @param amount Amount of tokens collected
    event RecoveredERC20(address token, uint256 amount);
}
