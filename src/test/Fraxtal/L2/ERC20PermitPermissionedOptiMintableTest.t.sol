//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./BaseTestL2.t.sol";
import { ERC20PermitPermissionedOptiMintable } from "src/contracts/Fraxtal/universal/ERC20PermitPermissionedOptiMintable.sol";

contract ERC20PermitPermissionedOptiMintableTest is BaseTestL2 {
    using stdJson for string;

    address[] public erc20s;

    function setUp() public {
        defaultSetup();

        // add owned erc20s
        erc20s.push(FRAXTAL_L2_FRAX);
        erc20s.push(FRAXTAL_L2_SFRAX);
        erc20s.push(FRAXTAL_L2_FXS);
        erc20s.push(FRAXTAL_L2_FPI);
        erc20s.push(FRAXTAL_L2_FPIS);
        erc20s.push(FRAXTAL_L2_SFRXETH);
        erc20s.push(FRAXTAL_L2_FRXBTC);
    }

    function testFuzz_AddAndRemoveMinter(uint160 _minterUint) public {
        vm.assume(_minterUint != 0);
        address minter = address(_minterUint);

        vm.startPrank(FRAXTAL_L2_FRAXTAL_SAFE);

        // loop through all erc20s
        for (uint256 i = 0; i < erc20s.length; i++) {
            ERC20PermitPermissionedOptiMintable iErc20 = ERC20PermitPermissionedOptiMintable(erc20s[i]);

            assertEq({ a: iErc20.minters(minter), b: false, err: "Minter already added" });

            // add the minter
            iErc20.addMinter(minter);

            assertEq({ a: iErc20.minters(minter), b: true, err: "Minter not added to erc20" });

            // remove the minter
            iErc20.removeMinter(minter);

            assertEq({ a: iErc20.minters(minter), b: false, err: "Minter not removed" });
        }
    }
}
