"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
/* eslint-disable @typescript-eslint/no-empty-function */
require("./setup");
describe('L2Provider', () => {
    describe('getL1GasPrice', () => {
        it('should query the GasPriceOracle contract', () => { });
    });
    describe('estimateL1Gas', () => {
        it('should query the GasPriceOracle contract', () => { });
    });
    describe('estimateL1GasCost', () => {
        it('should multiply the estimated L1 gas cost by the L1 gas price', () => { });
    });
    describe('estimateL2GasCost', () => {
        it('should multiply the estimated L2 gas cost by the L1 gas price', () => { });
    });
    describe('estimateTotalGasCost', () => {
        it('should be the sum of the L1 and L2 gas cost estimates', () => { });
    });
});
