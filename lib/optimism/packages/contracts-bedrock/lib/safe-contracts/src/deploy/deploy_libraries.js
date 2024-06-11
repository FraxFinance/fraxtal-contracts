"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const deploy = async function (hre) {
    const { deployments, hardhatArguments, getNamedAccounts } = hre;
    const { deployer } = await getNamedAccounts();
    const { deploy } = deployments;
    await deploy("CreateCall", {
        from: deployer,
        args: [],
        log: true,
        deterministicDeployment: true,
    });
    await deploy("MultiSend", {
        from: deployer,
        args: [],
        log: true,
        deterministicDeployment: true,
    });
    await deploy("MultiSendCallOnly", {
        from: deployer,
        args: [],
        log: true,
        deterministicDeployment: true,
    });
    await deploy("SignMessageLib", {
        from: deployer,
        args: [],
        log: true,
        deterministicDeployment: true,
    });
};
deploy.tags = ["libraries", "l2-suite", "main-suite"];
exports.default = deploy;
