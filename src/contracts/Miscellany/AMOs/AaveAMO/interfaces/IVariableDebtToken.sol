// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Borrowed tokens
// E.g. Aave Ethereum Variable Debt FRAX (variableDebtEthFRAX) https://etherscan.io/token/0x88b8358f5bc87c2d7e116cca5b65a9eeb2c5ea3f
interface IVariableDebtToken {
    function DEBT_TOKEN_REVISION() external view returns (uint256);

    function DELEGATION_WITH_SIG_TYPEHASH() external view returns (bytes32);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function EIP712_REVISION() external view returns (bytes memory);

    function POOL() external view returns (address);

    function UNDERLYING_ASSET_ADDRESS() external view returns (address);

    function allowance(address, address) external view returns (uint256);

    function approve(address, uint256) external returns (bool);

    function approveDelegation(address delegatee, uint256 amount) external;

    function balanceOf(address user) external view returns (uint256);

    function borrowAllowance(address fromUser, address toUser) external view returns (uint256);

    function burn(address from, uint256 amount, uint256 index) external returns (uint256);

    function decimals() external view returns (uint8);

    function decreaseAllowance(address, uint256) external returns (bool);

    function delegationWithSig(
        address delegator,
        address delegatee,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function getIncentivesController() external view returns (address);

    function getPreviousIndex(address user) external view returns (uint256);

    function getScaledUserBalanceAndSupply(address user) external view returns (uint256, uint256);

    function increaseAllowance(address, uint256) external returns (bool);

    function initialize(
        address initializingPool,
        address underlyingAsset,
        address incentivesController,
        uint8 debtTokenDecimals,
        string memory debtTokenName,
        string memory debtTokenSymbol,
        bytes calldata params
    ) external;

    function mint(address user, address onBehalfOf, uint256 amount, uint256 index) external returns (bool, uint256);

    function name() external view returns (string memory);

    function nonces(address owner) external view returns (uint256);

    function scaledBalanceOf(address user) external view returns (uint256);

    function scaledTotalSupply() external view returns (uint256);

    function setIncentivesController(address controller) external;

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address, uint256) external returns (bool);

    function transferFrom(address, address, uint256) external returns (bool);
}
