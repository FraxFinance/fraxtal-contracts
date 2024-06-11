"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const deploy = async function (hre) {
    const { deployments, getNamedAccounts } = hre;
    const { deployer } = await getNamedAccounts();
    const { deploy } = deployments;
    await deploy("SafeProxyFactory", {
        from: deployer,
        args: [],
        log: true,
        deterministicDeployment: true,
    });
};
deploy.tags = ["factory", "l2-suite", "main-suite"];
exports.default = deploy;
