// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IBalancerPool {
    function getActualSupply() external view returns (uint256);
}
