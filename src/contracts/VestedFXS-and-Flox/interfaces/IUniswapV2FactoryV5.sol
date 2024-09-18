pragma solidity >=0.5.0;

interface IUniswapV2FactoryV5 {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function globalPause() external view returns (bool);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function createPair(address tokenA, address tokenB, uint256 fee) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function toggleGlobalPause() external;
}
