// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
 import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract EnhancedSwap {
    using SafeERC20 for IERC20;
 address payable public owner; 
    
      ISwapRouter private router;
    IERC20 private weth;
    IERC20 private usdt;
    AggregatorV3Interface private ethUsdPriceFeed;

    event Swap(address indexed user, uint256 ethAmount, uint256 usdtAmount);
    event Withdrawal(address indexed user, uint256 amount);

    uint24 public constant UNISWAP_POOL_FEE = 3000; 
    uint256 private constant ETH_DECIMALS_FACTOR = 10**18;
    uint256 private constant CHAINLINK_USD_DECIMALS_FACTOR = 10**8;
    uint256 private constant USDT_DECIMALS_FACTOR = 10**6;
     
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    constructor(address _weth, address _usdt, address _swapRouter, address _ethUsdPriceFeed) {
        require(_weth != address(0) && 
        _usdt != address(0) &&
         _swapRouter != address(0) && 
         _ethUsdPriceFeed != address(0), "Addresses cannot be zero");
        owner = payable(msg.sender);
        weth = IERC20(_weth);
        usdt = IERC20(_usdt);
        
         router = ISwapRouter(_swapRouter);
        ethUsdPriceFeed = AggregatorV3Interface(_ethUsdPriceFeed);
    }

    function getEthPrice() public view returns (uint256) {
        ( , int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        require(price > 0, "Price must be positive");
        return uint256(price);
    }
     function calculateEthValueInUsd(uint256 ethAmount) public view returns (uint256) {
        uint256 ethPrice = getEthPrice(); 

       
        return (ethPrice * ethAmount) / CHAINLINK_USD_DECIMALS_FACTOR;
    }

  
     function swapExactInputSingleHop(uint256 amountInEth, uint256 slippageBasisPoints) external {
        require(amountInEth > 0, "AmountIn must be greater than 0"); // Дополнительная проверка
        require(slippageBasisPoints <= 10000, "Slippage must be <= 10000 (representing 100%)");

        weth.safeTransferFrom(msg.sender, address(this), amountInEth);
        weth.safeApprove(address(router), amountInEth);
        uint256 amountOutMinimum = calculateAmountOutMinimumUsdt(amountInEth, slippageBasisPoints); 
        require(amountOutMinimum > 0, "Calculated amountOutMinimum is zero. Check input or price.");

      
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: address(weth),
            tokenOut: address(usdt),
            fee: UNISWAP_POOL_FEE,
            recipient: address(this), 
            amountIn: amountInEth,
            amountOutMinimum: amountOutMinimum,
            sqrtPriceLimitX96: 0, 
            deadline: block.timestamp + 300 
        });
        uint256 amountOutUsdt = router.exactInputSingle(params);
        require(amountOutUsdt > 0, "Swap failed or returned zero amount"); 

   
        emit Swap(msg.sender, amountInEth, amountOutUsdt);
    }

    
    function calculateAmountOutMinimumUsdt(
        uint256 amountInEthWei, 
        uint256 slippageBasisPoints
    ) public view returns (uint256 amountUsdtMinimum) { 
        require(slippageBasisPoints <= 10000, "Slippage exceeds 100%");

        uint256 ethPriceUsd8Decimals = getEthPrice(); 
        uint256 expectedUsdtAmount = (amountInEthWei * ethPriceUsd8Decimals) / 
    (ETH_DECIMALS_FACTOR * CHAINLINK_USD_DECIMALS_FACTOR / USDT_DECIMALS_FACTOR);
        
        amountUsdtMinimum = expectedUsdtAmount * (10000 - slippageBasisPoints) / 10000;
        return amountUsdtMinimum;
    }

    function withdraw() external onlyOwner { // <--- ИСПРАВЛЕНИЕ: Добавлен onlyOwner
        uint256 balance = usdt.balanceOf(address(this));
        require(balance > 0, "Insufficient balance");
        usdt.safeTransfer(msg.sender, balance); // msg.sender здесь будет владельцем
        emit Withdrawal(msg.sender, balance);
    }
    receive() external payable {}
}

