// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import { ERC20PermitPermissionedOptiMintable } from "../ERC20PermitPermissionedOptiMintable.sol";

contract Fpi is ERC20PermitPermissionedOptiMintable {
    /// @param _creator_address The contract creator
    /// @param _timelock_address The timelock
    /// @param _bridge Address of the L2 standard bridge
    /// @param _remoteToken Address of the corresponding L1 token
    constructor(
        address _creator_address,
        address _timelock_address,
        address _bridge,
        address _remoteToken
    )
        ERC20PermitPermissionedOptiMintable(
            _creator_address,
            _timelock_address,
            _bridge,
            _remoteToken,
            "Frax Price Index",
            "FPI"
        )
    {}
}
