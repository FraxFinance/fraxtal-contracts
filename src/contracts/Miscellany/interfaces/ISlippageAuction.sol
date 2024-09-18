// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ISlippageAuction {
    /// @notice Detail information behind an auction
    /// @notice Auction information
    /// @param amountListed Amount of sellToken placed for auction
    /// @param amountLeft Amount of sellToken remaining to buy
    /// @param amountExcessBuy Amount of any additional TOKEN_BUY sent to contract during auction
    /// @param amountExcessSell Amount of any additional TOKEN_SELL sent to contract during auction
    /// @param tokenBuyReceived Amount of tokenBuy that came in from sales
    /// @param priceLast Price of the last sale, in tokenBuy amount per tokenSell (amount of tokenBuy to purchase 1e18 tokenSell)
    /// @param priceMin Minimum price of 1e18 tokenSell, in tokenBuy
    /// @param priceDecay Price decay, (wei per second), using PRECISION
    /// @param priceSlippage Slippage fraction. E.g (0.01 * PRECISION) = 1%
    /// @param lastBuyTime Time of the last sale
    /// @param expiry UNIX timestamp when the auction ends
    /// @param active If the auction is active
    struct Detail {
        uint128 amountListed;
        uint128 amountLeft;
        uint128 amountExcessBuy;
        uint128 amountExcessSell;
        uint128 tokenBuyReceived;
        uint128 priceLast;
        uint128 priceMin;
        uint64 priceDecay;
        uint64 priceSlippage;
        uint32 lastBuyTime;
        uint32 expiry;
        bool active;
    }

    /// @notice Parameters for starting an auction
    /// @dev Sender must have an allowance on tokenSell
    /// @param amountListed Amount of tokenSell being sold
    /// @param priceStart Starting price of 1e18 tokenSell, in tokenBuy
    /// @param priceMin Minimum price of 1e18 tokenSell, in tokenBuy
    /// @param priceDecay Price decay, (wei per second), using PRECISION
    /// @param priceSlippage Slippage fraction. E.g (0.01 * PRECISION) = 1%
    /// @param expiry UNIX timestamp when the auction ends
    struct StartAuctionParams {
        uint128 amountListed;
        uint128 priceStart;
        uint128 priceMin;
        uint64 priceDecay;
        uint64 priceSlippage;
        uint32 expiry;
    }

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function PRECISION() external view returns (uint256);

    function TOKEN_BUY() external view returns (address);

    function TOKEN_SELL() external view returns (address);

    function acceptTransferTimelock() external;

    function details(
        uint256
    )
        external
        view
        returns (
            uint128 amountListed,
            uint128 amountLeft,
            uint128 amountExcessBuy,
            uint128 amountExcessSell,
            uint128 tokenBuyReceived,
            uint128 priceLast,
            uint128 priceMin,
            uint64 priceDecay,
            uint64 priceSlippage,
            uint32 lastBuyTime,
            uint32 expiry,
            bool active
        );

    function detailsLength() external view returns (uint256 _length);

    function factory() external pure returns (address);

    function getAmountIn(uint256 amountOut, address tokenOut) external view returns (uint256 amountIn);

    function getAmountIn(uint256, uint256, uint256) external pure returns (uint256);

    function getAmountIn(
        uint256 amountOut
    ) external view returns (uint256 amountIn, uint256 _slippagePerTokenSell, uint256 _postPriceSlippage);

    function getAmountInMax()
        external
        view
        returns (uint256 amountIn, uint256 _slippagePerTokenSell, uint256 _postPriceSlippage);

    function getAmountOut(uint256, uint256, uint256) external pure returns (uint256);

    function getAmountOut(
        uint256 amountIn,
        bool _revertOnOverAmountLeft
    ) external view returns (uint256 amountOut, uint256 _slippagePerTokenSell, uint256 _postPriceSlippage);

    function getAmountOut(uint256 amountIn, address tokenIn) external view returns (uint256 amountOut);

    function getDetailStruct(uint256 _auctionNumber) external view returns (Detail memory);

    function getLatestAuction() external view returns (Detail memory _latestAuction);

    function getPreSlippagePrice() external view returns (uint256);

    function getPreSlippagePrice(Detail memory _detail) external view returns (uint256 _price);

    function getReserves() external pure returns (uint112, uint112, uint32);

    function initialize(address, address) external pure;

    function kLast() external pure returns (uint256);

    function name() external view returns (string memory);

    function pendingTimelockAddress() external view returns (address);

    function price0CumulativeLast() external pure returns (uint256);

    function price1CumulativeLast() external pure returns (uint256);

    function renounceTimelock() external;

    function skim(address) external pure;

    function startAuction(StartAuctionParams memory _params) external returns (uint256 _auctionNumber);

    function stopAuction() external returns (uint256 tokenBuyReceived, uint256 tokenSellRemaining);

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes memory data) external;

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory _amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] memory path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory _amounts);

    function sync() external pure;

    function timelockAddress() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function transferTimelock(address _newTimelock) external;

    function version() external pure returns (uint256 _major, uint256 _minor, uint256 _patch);
}
