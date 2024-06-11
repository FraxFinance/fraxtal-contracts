// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/// @title IIncentivesReceiver
/// @notice Interface for a contract that receives incentives
interface IIncentivesReceiver {
    /// @param _amnount of tokens received.
    function distribute(address _tokenHolder, uint256 _amnount) external;
}
