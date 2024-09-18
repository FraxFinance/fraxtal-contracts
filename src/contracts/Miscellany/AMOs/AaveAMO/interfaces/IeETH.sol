// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IeETH {
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function allowance(address _owner, address _spender) external view returns (uint256);

    function allowances(address, address) external view returns (uint256);

    function approve(address _spender, uint256 _amount) external returns (bool);

    function balanceOf(address _user) external view returns (uint256);

    function burnShares(address _user, uint256 _share) external;

    function decimals() external pure returns (uint8);

    function decreaseAllowance(address _spender, uint256 _decreaseAmount) external returns (bool);

    function getImplementation() external view returns (address);

    function increaseAllowance(address _spender, uint256 _increaseAmount) external returns (bool);

    function initialize(address _liquidityPool) external;

    function liquidityPool() external view returns (address);

    function mintShares(address _user, uint256 _share) external;

    function name() external pure returns (string memory);

    function nonces(address owner) external view returns (uint256);

    function owner() external view returns (address);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function proxiableUUID() external view returns (bytes32);

    function renounceOwnership() external;

    function shares(address) external view returns (uint256);

    function symbol() external pure returns (string memory);

    function totalShares() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(address _recipient, uint256 _amount) external returns (bool);

    function transferFrom(address _sender, address _recipient, uint256 _amount) external returns (bool);

    function transferOwnership(address newOwner) external;

    function upgradeTo(address newImplementation) external;

    function upgradeToAndCall(address newImplementation, bytes calldata data) external;
}
