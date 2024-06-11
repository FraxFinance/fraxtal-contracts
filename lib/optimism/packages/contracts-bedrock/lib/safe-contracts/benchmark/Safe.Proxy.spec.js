"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
require("@nomiclabs/hardhat-ethers");
const execution_1 = require("../src/utils/execution");
const setup_1 = require("./utils/setup");
const setup_2 = require("../test/utils/setup");
(0, setup_1.benchmark)("Proxy", [{
        name: "creation",
        prepare: async (contracts, _, nonce) => {
            const factory = contracts.additions.factory;
            // We're cheating and passing the factory address as a singleton address to bypass a check that singleton contract exists
            const data = factory.interface.encodeFunctionData("createProxyWithNonce", [factory.address, "0x", 0]);
            return (0, execution_1.buildSafeTransaction)({ to: factory.address, data, safeTxGas: 1000000, nonce });
        },
        fixture: async () => {
            return {
                factory: await (0, setup_2.getFactory)(),
            };
        }
    }]);
(0, setup_1.benchmark)("Proxy", [{
        name: "chain specific creation",
        prepare: async (contracts, _, nonce) => {
            const factory = contracts.additions.factory;
            // We're cheating and passing the factory address as a singleton address to bypass a check that singleton contract exists
            const data = factory.interface.encodeFunctionData("createChainSpecificProxyWithNonce", [factory.address, "0x", 0]);
            return (0, execution_1.buildSafeTransaction)({ to: factory.address, data, safeTxGas: 1000000, nonce });
        },
        fixture: async () => {
            return {
                factory: await (0, setup_2.getFactory)(),
            };
        }
    }]);
