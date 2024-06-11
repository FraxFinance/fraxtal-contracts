"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.MultisigMonService = void 0;
const child_process_1 = require("child_process");
const common_ts_1 = require("@eth-optimism/common-ts");
const ethers_1 = require("ethers");
const IGnosisSafe_0_8_19_json_1 = __importDefault(require("../abi/IGnosisSafe.0.8.19.json"));
const OptimismPortal_json_1 = __importDefault(require("../abi/OptimismPortal.json"));
const package_json_1 = require("../../package.json");
class MultisigMonService extends common_ts_1.BaseServiceV2 {
    constructor(options) {
        super({
            version: package_json_1.version,
            name: 'multisig-mon',
            loop: true,
            options: {
                loopIntervalMs: 60000,
                ...options,
            },
            optionsSpec: {
                rpc: {
                    validator: common_ts_1.validators.provider,
                    desc: 'Provider for network to monitor balances on',
                },
                accounts: {
                    validator: common_ts_1.validators.str,
                    desc: 'JSON array of [{ nickname, safeAddress, optimismPortalAddress, vault }] to monitor',
                    public: true,
                },
                onePassServiceToken: {
                    validator: common_ts_1.validators.str,
                    desc: '1Password Service Token',
                },
            },
            metricsSpec: {
                safeNonce: {
                    type: common_ts_1.Gauge,
                    desc: 'Safe nonce',
                    labels: ['address', 'nickname'],
                },
                latestPreSignedPauseNonce: {
                    type: common_ts_1.Gauge,
                    desc: 'Latest pre-signed pause nonce',
                    labels: ['address', 'nickname'],
                },
                pausedState: {
                    type: common_ts_1.Gauge,
                    desc: 'OptimismPortal paused state',
                    labels: ['address', 'nickname'],
                },
                unexpectedRpcErrors: {
                    type: common_ts_1.Counter,
                    desc: 'Number of unexpected RPC errors',
                    labels: ['section', 'name'],
                },
            },
        });
    }
    async init() {
        this.state.accounts = JSON.parse(this.options.accounts);
    }
    async main() {
        for (const account of this.state.accounts) {
            // get the nonce 1pass
            if (this.options.onePassServiceToken) {
                await this.getOnePassNonce(account);
            }
            // get the nonce from deployed safe
            if (account.safeAddress) {
                await this.getSafeNonce(account);
            }
            // get the paused state of the OptimismPortal
            if (account.optimismPortalAddress) {
                await this.getPausedState(account);
            }
        }
    }
    async getPausedState(account) {
        try {
            const optimismPortal = new ethers_1.ethers.Contract(account.optimismPortalAddress, OptimismPortal_json_1.default.abi, this.options.rpc);
            const paused = await optimismPortal.paused();
            this.logger.info(`got paused state`, {
                optimismPortalAddress: account.optimismPortalAddress,
                nickname: account.nickname,
                paused,
            });
            this.metrics.pausedState.set({ address: account.optimismPortalAddress, nickname: account.nickname }, paused ? 1 : 0);
        }
        catch (err) {
            this.logger.error(`got unexpected RPC error`, {
                section: 'pausedState',
                name: 'getPausedState',
                err,
            });
            this.metrics.unexpectedRpcErrors.inc({
                section: 'pausedState',
                name: 'getPausedState',
            });
        }
    }
    async getOnePassNonce(account) {
        try {
            (0, child_process_1.exec)(`OP_SERVICE_ACCOUNT_TOKEN=${this.options.onePassServiceToken} op item list --format json --vault="${account.vault}"`, (error, stdout, stderr) => {
                if (error) {
                    this.logger.error(`got unexpected error from onepass: ${error}`, {
                        section: 'onePassNonce',
                        name: 'getOnePassNonce',
                    });
                    return;
                }
                if (stderr) {
                    this.logger.error(`got unexpected error from onepass`, {
                        section: 'onePassNonce',
                        name: 'getOnePassNonce',
                        stderr,
                    });
                    return;
                }
                const items = JSON.parse(stdout);
                let latestNonce = -1;
                this.logger.debug(`items in vault '${account.vault}':`);
                for (const item of items) {
                    const title = item['title'];
                    this.logger.debug(`- ${title}`);
                    if (title.startsWith('ready-') && title.endsWith('.json')) {
                        const nonce = parseInt(title.substring(6, title.length - 5), 10);
                        if (nonce > latestNonce) {
                            latestNonce = nonce;
                        }
                    }
                }
                this.metrics.latestPreSignedPauseNonce.set({ address: account.safeAddress, nickname: account.nickname }, latestNonce);
                this.logger.debug(`latestNonce: ${latestNonce}`);
            });
        }
        catch (err) {
            this.logger.error(`got unexpected error from onepass`, {
                section: 'onePassNonce',
                name: 'getOnePassNonce',
                err,
            });
            this.metrics.unexpectedRpcErrors.inc({
                section: 'onePassNonce',
                name: 'getOnePassNonce',
            });
        }
    }
    async getSafeNonce(account) {
        try {
            const safeContract = new ethers_1.ethers.Contract(account.safeAddress, IGnosisSafe_0_8_19_json_1.default.abi, this.options.rpc);
            const safeNonce = await safeContract.nonce();
            this.logger.info(`got nonce`, {
                address: account.safeAddress,
                nickname: account.nickname,
                nonce: safeNonce.toString(),
            });
            this.metrics.safeNonce.set({ address: account.safeAddress, nickname: account.nickname }, parseInt(safeNonce.toString(), 10));
        }
        catch (err) {
            this.logger.error(`got unexpected RPC error`, {
                section: 'safeNonce',
                name: 'getSafeNonce',
                err,
            });
            this.metrics.unexpectedRpcErrors.inc({
                section: 'safeNonce',
                name: 'getSafeNonce',
            });
        }
    }
}
exports.MultisigMonService = MultisigMonService;
if (require.main === module) {
    const service = new MultisigMonService();
    service.run();
}
