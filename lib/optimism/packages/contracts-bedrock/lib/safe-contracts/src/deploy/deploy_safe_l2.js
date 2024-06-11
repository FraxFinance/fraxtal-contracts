"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const deploy = async function (hre) {
    const { deployments, getNamedAccounts } = hre;
    const { deployer } = await getNamedAccounts();
    const { deploy } = deployments;
    await deploy("SafeL2", {
        from: deployer,
        args: [],
        log: true,
        deterministicDeployment: true,
    });
};
deploy.tags = ["l2", "l2-suite"];
exports.default = deploy;
