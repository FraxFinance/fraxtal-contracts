"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const deploy = async function (hre) {
    const { deployments, getNamedAccounts } = hre;
    const { deployer } = await getNamedAccounts();
    const { deploy } = deployments;
    await deploy("TokenCallbackHandler", {
        from: deployer,
        args: [],
        log: true,
        deterministicDeployment: true,
    });
    await deploy("CompatibilityFallbackHandler", {
        from: deployer,
        args: [],
        log: true,
        deterministicDeployment: true,
    });
};
deploy.tags = ["handlers", "l2-suite", "main-suite"];
exports.default = deploy;
