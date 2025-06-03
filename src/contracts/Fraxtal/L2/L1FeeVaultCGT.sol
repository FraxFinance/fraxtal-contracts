// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { ISemver } from "@eth-optimism/contracts-bedrock/src/universal/interfaces/ISemver.sol";
import { FeeVaultCGT } from "./FeeVaultCGT.sol";
import {
    Initializable
} from "@eth-optimism/contracts-bedrock/lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import { Types } from "@eth-optimism/contracts-bedrock/src/libraries/Types.sol";

/// @custom:proxied true
/// @custom:predeploy 0x420000000000000000000000000000000000001A
/// @title L1FeeVaultCGT
/// @notice The L1FeeVaultCGT accumulates the L1 portion of the transaction fees.
contract L1FeeVaultCGT is Initializable, FeeVaultCGT, ISemver {
    /// @notice Semantic version.
    /// @custom:semver 1.5.0-beta.3
    string public constant version = "1.5.0-beta.3";

    /// @notice Constructs the L1FeeVaultCGT contract.
    constructor() {
        initialize({ _recipient: address(0), _minWithdrawalAmount: 0, _withdrawalNetwork: Types.WithdrawalNetwork.L2 });
    }

    /// @notice Initializer.
    /// @param _recipient           Wallet that will receive the fees.
    /// @param _minWithdrawalAmount Minimum balance for withdrawals.
    /// @param _withdrawalNetwork   Network which the recipient will receive fees on.
    function initialize(
        address _recipient,
        uint256 _minWithdrawalAmount,
        Types.WithdrawalNetwork _withdrawalNetwork
    ) public initializer {
        RECIPIENT = _recipient;
        MIN_WITHDRAWAL_AMOUNT = _minWithdrawalAmount;
        WITHDRAWAL_NETWORK = _withdrawalNetwork;

        // Withdraw any existing gas tokens to the sender and zero totalProcessed
        (bool success, ) = _recipient.call{ value: address(this).balance }("");
        if (!success) {
            revert GasTransferInInitializeFailed();
        }
        totalProcessed = 0;
    }
}
