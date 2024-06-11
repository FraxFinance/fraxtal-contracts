// SPDX-License-Identifier: ISC
pragma solidity ^0.8.15;

import { stdJson } from "forge-std/StdJson.sol";
import { console } from "frax-std/FraxTest.sol";
import { Frax } from "src/contracts/Fraxtal/universal/vanity/Frax.sol";
import { Fxs } from "src/contracts/Fraxtal/universal/vanity/Fxs.sol";
import { Fpi } from "src/contracts/Fraxtal/universal/vanity/Fpi.sol";
import { Fpis } from "src/contracts/Fraxtal/universal/vanity/Fpis.sol";
import { sfrxETH } from "src/contracts/Fraxtal/universal/vanity/sfrxETH.sol";
import { wfrxETH } from "src/contracts/Fraxtal/universal/vanity/wfrxETH.sol";
import { frxBTC } from "src/contracts/Fraxtal/universal/vanity/frxBTC.sol";
import { sFRAX } from "src/contracts/Fraxtal/universal/vanity/sFrax.sol";
import { Strings } from "@openzeppelin-5/contracts/utils/Strings.sol";
import { FraxchainDeploy } from "src/script/Fraxtal/FraxchainDeploy.s.sol";
import "src/Constants.sol" as Constants;

// FRAX
// =================================
function deployFrax(string memory network) returns (Frax _frax, address _address) {
    if (Strings.equal(network, Constants.FraxtalDeployment.DEVNET)) {
        _frax = new Frax(
            Constants.FraxtalL2Devnet.FRAXCHAIN_ADMIN,
            Constants.FraxtalL2Devnet.FRAXCHAIN_ADMIN,
            Constants.FraxtalL2Devnet.L2_STANDARD_BRIDGE,
            Constants.FraxtalL1Devnet.FRAX_ERC20
        );
    } else if (Strings.equal(network, Constants.FraxtalDeployment.TESTNET)) {
        _frax = new Frax(
            Constants.FraxtalTestnet.FRAXCHAIN_ADMIN,
            Constants.FraxtalTestnet.FRAXCHAIN_ADMIN,
            Constants.FraxtalTestnet.L2_STANDARD_BRIDGE,
            Constants.Holesky.FRAX_ERC20
        );
    } else if (Strings.equal(network, Constants.FraxtalDeployment.MAINNET)) {
        _frax = new Frax(
            Constants.FraxtalMainnet.FRAXCHAIN_ADMIN,
            Constants.FraxtalMainnet.FRAXCHAIN_ADMIN,
            Constants.FraxtalMainnet.L2_STANDARD_BRIDGE,
            Constants.Mainnet.FRAX_ERC20
        );
    } else if (Strings.equal(network, Constants.FraxtalDeployment.TESTNET_SEPOLIA)) {
        _frax = new Frax(
            Constants.FraxtalTestnetSepolia.FRAXCHAIN_ADMIN,
            Constants.FraxtalTestnetSepolia.FRAXCHAIN_ADMIN,
            Constants.FraxtalTestnetSepolia.L2_STANDARD_BRIDGE,
            Constants.Sepolia.FRAX_ERC20
        );
    } else {
        revert("Unsupported network");
    }
    _address = address(_frax);
}

contract DeployFraxchainFrax is FraxchainDeploy {
    function run() external broadcaster returns (Frax _frax, address _address) {
        (_frax, _address) = deployFrax(network);
    }
}

// FXS
// =================================
function deployFxs(string memory network) returns (Fxs _fxs, address _address) {
    if (Strings.equal(network, Constants.FraxtalDeployment.DEVNET)) {
        _fxs = new Fxs(
            Constants.FraxtalL2Devnet.FRAXCHAIN_ADMIN,
            Constants.FraxtalL2Devnet.FRAXCHAIN_ADMIN,
            Constants.FraxtalL2Devnet.L2_STANDARD_BRIDGE,
            Constants.FraxtalL1Devnet.FXS_ERC20
        );
    } else if (Strings.equal(network, Constants.FraxtalDeployment.TESTNET)) {
        _fxs = new Fxs(
            Constants.FraxtalTestnet.FRAXCHAIN_ADMIN,
            Constants.FraxtalTestnet.FRAXCHAIN_ADMIN,
            Constants.FraxtalTestnet.L2_STANDARD_BRIDGE,
            Constants.Holesky.FXS_ERC20
        );
    } else if (Strings.equal(network, Constants.FraxtalDeployment.MAINNET)) {
        _fxs = new Fxs(
            Constants.FraxtalMainnet.FRAXCHAIN_ADMIN,
            Constants.FraxtalMainnet.FRAXCHAIN_ADMIN,
            Constants.FraxtalMainnet.L2_STANDARD_BRIDGE,
            Constants.Mainnet.FXS_ERC20
        );
    } else if (Strings.equal(network, Constants.FraxtalDeployment.TESTNET_SEPOLIA)) {
        _fxs = new Fxs(
            Constants.FraxtalTestnetSepolia.FRAXCHAIN_ADMIN,
            Constants.FraxtalTestnetSepolia.FRAXCHAIN_ADMIN,
            Constants.FraxtalTestnetSepolia.L2_STANDARD_BRIDGE,
            Constants.Sepolia.FXS_ERC20
        );
    } else {
        revert("Unsupported network");
    }
    _address = address(_fxs);
}

contract DeployFraxchainFxs is FraxchainDeploy {
    function run() external broadcaster returns (Fxs _fxs, address _address) {
        (_fxs, _address) = deployFxs(network);
    }
}

// FPI
// =================================
function deployFpi(string memory network) returns (Fpi _fpi, address _address) {
    if (Strings.equal(network, Constants.FraxtalDeployment.DEVNET)) {
        _fpi = new Fpi(
            Constants.FraxtalTestnet.FRAXCHAIN_ADMIN,
            Constants.FraxtalTestnet.FRAXCHAIN_ADMIN,
            Constants.FraxtalTestnet.L2_STANDARD_BRIDGE,
            Constants.FraxtalL1Devnet.FPI_ERC20
        );
    } else if (Strings.equal(network, Constants.FraxtalDeployment.TESTNET)) {
        _fpi = new Fpi(
            Constants.FraxtalTestnet.FRAXCHAIN_ADMIN,
            Constants.FraxtalTestnet.FRAXCHAIN_ADMIN,
            Constants.FraxtalTestnet.L2_STANDARD_BRIDGE,
            Constants.Holesky.FPI_ERC20
        );
    } else if (Strings.equal(network, Constants.FraxtalDeployment.MAINNET)) {
        _fpi = new Fpi(
            Constants.FraxtalMainnet.FRAXCHAIN_ADMIN,
            Constants.FraxtalMainnet.FRAXCHAIN_ADMIN,
            Constants.FraxtalMainnet.L2_STANDARD_BRIDGE,
            Constants.Mainnet.FPI_ERC20
        );
    } else if (Strings.equal(network, Constants.FraxtalDeployment.TESTNET_SEPOLIA)) {
        _fpi = new Fpi(
            Constants.FraxtalTestnetSepolia.FRAXCHAIN_ADMIN,
            Constants.FraxtalTestnetSepolia.FRAXCHAIN_ADMIN,
            Constants.FraxtalTestnetSepolia.L2_STANDARD_BRIDGE,
            Constants.Sepolia.FPI_ERC20
        );
    } else {
        revert("Unsupported network");
    }
    _address = address(_fpi);
}

contract DeployFraxchainFpi is FraxchainDeploy {
    function run() external broadcaster returns (Fpi _fpi, address _address) {
        (_fpi, _address) = deployFpi(network);
    }
}

// FPIS
// =================================
function deployFpis(string memory network) returns (Fpis _fpis, address _address) {
    if (Strings.equal(network, Constants.FraxtalDeployment.DEVNET)) {
        _fpis = new Fpis(
            Constants.FraxtalL2Devnet.FRAXCHAIN_ADMIN,
            Constants.FraxtalL2Devnet.FRAXCHAIN_ADMIN,
            Constants.FraxtalL2Devnet.L2_STANDARD_BRIDGE,
            Constants.FraxtalL1Devnet.FPIS_ERC20
        );
    } else if (Strings.equal(network, Constants.FraxtalDeployment.TESTNET)) {
        _fpis = new Fpis(
            Constants.FraxtalTestnet.FRAXCHAIN_ADMIN,
            Constants.FraxtalTestnet.FRAXCHAIN_ADMIN,
            Constants.FraxtalTestnet.L2_STANDARD_BRIDGE,
            Constants.Holesky.FPIS_ERC20
        );
    } else if (Strings.equal(network, Constants.FraxtalDeployment.MAINNET)) {
        _fpis = new Fpis(
            Constants.FraxtalMainnet.FRAXCHAIN_ADMIN,
            Constants.FraxtalMainnet.FRAXCHAIN_ADMIN,
            Constants.FraxtalMainnet.L2_STANDARD_BRIDGE,
            Constants.Mainnet.FPIS_ERC20
        );
    } else if (Strings.equal(network, Constants.FraxtalDeployment.TESTNET_SEPOLIA)) {
        _fpis = new Fpis(
            Constants.FraxtalTestnetSepolia.FRAXCHAIN_ADMIN,
            Constants.FraxtalTestnetSepolia.FRAXCHAIN_ADMIN,
            Constants.FraxtalTestnetSepolia.L2_STANDARD_BRIDGE,
            Constants.Sepolia.FPIS_ERC20
        );
    } else {
        revert("Unsupported network");
    }
    _address = address(_fpis);
}

contract DeployFraxchainFpis is FraxchainDeploy {
    function run() external broadcaster returns (Fpis _fpis, address _address) {
        (_fpis, _address) = deployFpis(network);
    }
}

// sfrxETH
// =================================
function deploySfrxETH(string memory network) returns (sfrxETH _sfrxETH, address _address) {
    if (Strings.equal(network, Constants.FraxtalDeployment.DEVNET)) {
        _sfrxETH = new sfrxETH(
            Constants.FraxtalL2Devnet.FRAXCHAIN_ADMIN,
            Constants.FraxtalL2Devnet.FRAXCHAIN_ADMIN,
            Constants.FraxtalL2Devnet.L2_STANDARD_BRIDGE,
            Constants.FraxtalL1Devnet.SFRXETH_ERC20
        );
    } else if (Strings.equal(network, Constants.FraxtalDeployment.TESTNET)) {
        _sfrxETH = new sfrxETH(
            Constants.FraxtalTestnet.FRAXCHAIN_ADMIN,
            Constants.FraxtalTestnet.FRAXCHAIN_ADMIN,
            Constants.FraxtalTestnet.L2_STANDARD_BRIDGE,
            Constants.Holesky.SFRXETH_ERC20
        );
    } else if (Strings.equal(network, Constants.FraxtalDeployment.MAINNET)) {
        _sfrxETH = new sfrxETH(
            Constants.FraxtalMainnet.FRAXCHAIN_ADMIN,
            Constants.FraxtalMainnet.FRAXCHAIN_ADMIN,
            Constants.FraxtalMainnet.L2_STANDARD_BRIDGE,
            Constants.Mainnet.SFRXETH_ERC20
        );
    } else if (Strings.equal(network, Constants.FraxtalDeployment.TESTNET_SEPOLIA)) {
        _sfrxETH = new sfrxETH(
            Constants.FraxtalTestnetSepolia.FRAXCHAIN_ADMIN,
            Constants.FraxtalTestnetSepolia.FRAXCHAIN_ADMIN,
            Constants.FraxtalTestnetSepolia.L2_STANDARD_BRIDGE,
            Constants.Sepolia.SFRXETH_ERC20
        );
    } else {
        revert("Unsupported network");
    }
    _address = address(_sfrxETH);
}

contract DeployFraxchainSfrxETH is FraxchainDeploy {
    function run() external broadcaster returns (sfrxETH _sfrxETH, address _address) {
        (_sfrxETH, _address) = deploySfrxETH(network);
    }
}

// wfrxETH
// =================================
function deployWfrxETH(string memory _network) returns (wfrxETH _wfrxETH, address _address) {
    _wfrxETH = new wfrxETH();
    _address = address(_wfrxETH);
}

contract DeployFraxchainWfrxETH is FraxchainDeploy {
    function run() external broadcaster returns (wfrxETH _wfrxETH, address _address) {
        (_wfrxETH, _address) = deployWfrxETH(network);
    }
}

// frxBTC
// =================================
function deployFrxBTC(string memory network) returns (frxBTC _frxBTC, address _address) {
    if (Strings.equal(network, Constants.FraxtalDeployment.DEVNET)) {
        _frxBTC = new frxBTC(
            Constants.FraxtalL2Devnet.FRAXCHAIN_ADMIN,
            Constants.FraxtalL2Devnet.FRAXCHAIN_ADMIN,
            Constants.FraxtalL2Devnet.L2_STANDARD_BRIDGE,
            Constants.FraxtalL1Devnet.FRXBTC_ERC20
        );
    } else if (Strings.equal(network, Constants.FraxtalDeployment.MAINNET)) {
        _frxBTC = new frxBTC(
            Constants.FraxtalMainnet.FRAXCHAIN_ADMIN,
            Constants.FraxtalMainnet.FRAXCHAIN_ADMIN,
            Constants.FraxtalMainnet.L2_STANDARD_BRIDGE,
            Constants.Mainnet.FRXBTC_ERC20
        );
    } else if (Strings.equal(network, Constants.FraxtalDeployment.TESTNET_SEPOLIA)) {
        _frxBTC = new frxBTC(
            Constants.FraxtalTestnetSepolia.FRAXCHAIN_ADMIN,
            Constants.FraxtalTestnetSepolia.FRAXCHAIN_ADMIN,
            Constants.FraxtalTestnetSepolia.L2_STANDARD_BRIDGE,
            Constants.Sepolia.FRXBTC_ERC20
        );
    } else {
        revert("Unsupported network");
    }
    _address = address(_frxBTC);
}

contract DeployFraxchainFrxBTC is FraxchainDeploy {
    function run() external broadcaster returns (frxBTC _frxBTC, address _address) {
        (_frxBTC, _address) = deployFrxBTC(network);
    }
}

// sFRAX
// =================================
function deploySFRAX(string memory network) returns (sFRAX _sFRAX, address _address) {
    if (Strings.equal(network, Constants.FraxtalDeployment.DEVNET)) {
        _sFRAX = new sFRAX(
            Constants.FraxtalL2Devnet.FRAXCHAIN_ADMIN,
            Constants.FraxtalL2Devnet.FRAXCHAIN_ADMIN,
            Constants.FraxtalL2Devnet.L2_STANDARD_BRIDGE,
            Constants.FraxtalL1Devnet.SFRAX_ERC20
        );
    } else if (Strings.equal(network, Constants.FraxtalDeployment.MAINNET)) {
        _sFRAX = new sFRAX(
            Constants.FraxtalMainnet.FRAXCHAIN_ADMIN,
            Constants.FraxtalMainnet.FRAXCHAIN_ADMIN,
            Constants.FraxtalMainnet.L2_STANDARD_BRIDGE,
            Constants.Mainnet.SFRAX_ERC20
        );
    } else if (Strings.equal(network, Constants.FraxtalDeployment.TESTNET_SEPOLIA)) {
        _sFRAX = new sFRAX(
            Constants.FraxtalTestnetSepolia.FRAXCHAIN_ADMIN,
            Constants.FraxtalTestnetSepolia.FRAXCHAIN_ADMIN,
            Constants.FraxtalTestnetSepolia.L2_STANDARD_BRIDGE,
            Constants.Sepolia.SFRAX_ERC20
        );
    } else {
        revert("Unsupported network");
    }
    _address = address(_sFRAX);
}

contract DeployFraxchainSFrax is FraxchainDeploy {
    function run() external broadcaster returns (sFRAX _sFRAX, address _address) {
        (_sFRAX, _address) = deploySFRAX(network);
    }
}

// Everything
// =======================================

contract DeployFraxchainL2ERC20s is FraxchainDeploy {
    function run() external broadcaster returns (string memory) {
        address[8] memory _addresses;
        (, _addresses[0]) = deployFrax(network);
        (, _addresses[1]) = deployFxs(network);
        (, _addresses[2]) = deployFpi(network);
        (, _addresses[3]) = deployFpis(network);
        (, _addresses[4]) = deploySfrxETH(network);
        (, _addresses[5]) = deployWfrxETH(network);
        (, _addresses[6]) = deployFrxBTC(network);
        (, _addresses[7]) = deploySFRAX(network);

        string memory _json = "";
        _json = stdJson.serialize("", "Frax", _addresses[0]);
        _json = stdJson.serialize("", "Fxs", _addresses[1]);
        _json = stdJson.serialize("", "Fpi", _addresses[2]);
        _json = stdJson.serialize("", "Fpis", _addresses[3]);
        _json = stdJson.serialize("", "sfrxETH", _addresses[4]);
        _json = stdJson.serialize("", "wfrxETH", _addresses[5]);
        _json = stdJson.serialize("", "frxBTC", _addresses[6]);
        _json = stdJson.serialize("", "sFRAX", _addresses[7]);

        return _json;
    }
}
