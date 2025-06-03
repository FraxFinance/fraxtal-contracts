// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { EIP712 } from "@openzeppelin-5/contracts/utils/cryptography/EIP712.sol";

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ========================= EIP712StoragePad =========================
// ====================================================================
// Used to preserve storage order

// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)
// Travis Moore: https://github.com/FortisFortuna

contract EIP712StoragePad {
    // Old EIP-712 State Variables
    // =============================================
    string private DEPRECATED___nameFallback;
    string private DEPRECATED___versionFallback;

    // Constructor
    // =============================================

    constructor() {}
}
