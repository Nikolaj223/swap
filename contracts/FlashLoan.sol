// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20; // Обновлен до 0.8.20 или выше

import {FlashLoanSimpleReceiverBase} from "@aave/core-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol"; 
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol"; 
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract FlashLoanArbitrage is FlashLoanSimpleReceiverBase, ReentrancyGuard {
    using SafeERC20 for IERC20; 

    address payable public owner; 
    ISwapRouter public uniswapRouter; 
    IERC20 public usdt;
    AggregatorV3Interface public ethUsdPriceFeed;
    uint256 public slippageToleranceBps; 
    IERC20 public weth;
    uint24 public constant UNISWAP_POOL_FEE = 500; // Пример Uniswap V3 комиссии пула (0.05%)

    event FlashLoanRequested(address indexed asset, uint256 amount);
    event FlashLoanExecuted(address indexed asset, uint256 amount, uint256 premium, uint256 profit);
    event SwapFailed(string message, address tokenIn, address tokenOut, uint256 amount);
    event Withdrawal(address indexed recipient, address indexed tokenAddress, uint256 amount);
    
   modifier onlyOwner() { 
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor(
        address _uniswapRouter,
        address _provider,
        address _usdt,
        address _ethUsdPriceFeed,
        uint256 _slippageToleranceBps, 
        address _weth
         
    )
        FlashLoanSimpleReceiverBase(IPoolAddressesProvider(_provider))
    {
        require(_uniswapRouter != address(0) && _usdt != address(0) && _ethUsdPriceFeed != address(0) && _weth != address(0), "Addresses cannot be zero");
        require(_slippageToleranceBps <= 10000, "Slippage tolerance cannot exceed 100%");

        owner = payable(msg.sender);
        uniswapRouter = ISwapRouter(_uniswapRouter); 
        usdt = IERC20(_usdt);
        ethUsdPriceFeed = AggregatorV3Interface(_ethUsdPriceFeed);
        slippageToleranceBps = _slippageToleranceBps;
        weth = IERC20(_weth);
    }
    function executeOperation(address asset, uint256 amount, uint256 premium, address initiator, bytes calldata params)
        external
        override
         nonReentrant
        returns (bool)
    {
        
        require(asset == address(weth), "Flash loan asset mismatch: Expected WETH");
        require(msg.sender == address(POOL), "Only Aave Pool can call executeOperation"); 
        require(initiator == owner, "Only owner can initiate flash loan through this contract"); 
        
        uint256 amountOwed = amount + premium; 
        uint256 wethBalanceAfterLoan = weth.balanceOf(address(this));
        require(wethBalanceAfterLoan >= amount, "Flash loan amount not received correctly");

        weth.safeApprove(address(uniswapRouter), amount);

         ISwapRouter.ExactInputSingleParams memory params1 = ISwapRouter.ExactInputSingleParams({
            tokenIn: address(weth),
            tokenOut: address(usdt),
            fee: UNISWAP_POOL_FEE,
            recipient: address(this), 
            deadline: block.timestamp + 300, // 5 минут
            amountIn: amount,
            amountOutMinimum: calculateAmountOutMinimum(amount, slippageToleranceBps), 
            sqrtPriceLimitX96: 0 // Нет лимита цены
        });

        uint256 usdtReceived;
        try uniswapRouter.exactInputSingle(params1) returns (uint256 amountOut) {
            usdtReceived = amountOut;
        } catch {
            emit SwapFailed("WETH -> USDT swap failed", address(weth), address(usdt), amount);
            revert("Swap WETH -> USDT failed");
        }
        require(usdtReceived > 0, "No USDT received from first swap");
        usdt.safeApprove(address(uniswapRouter), usdtReceived); 

         ISwapRouter.ExactInputSingleParams memory params2 = ISwapRouter.ExactInputSingleParams({
            tokenIn: address(usdt),tokenOut: address(weth),
            fee: UNISWAP_POOL_FEE,
            recipient: address(this),
            deadline: block.timestamp + 300, 
            amountIn: usdtReceived,
            amountOutMinimum: calculateAmountOutMinimum(usdtReceived, slippageToleranceBps), 
            sqrtPriceLimitX96: 0 
        });

        uint256 wethReceived;
         try uniswapRouter.exactInputSingle(params2) returns (uint256 amountOut) {
            wethReceived = amountOut;
        } catch {
            emit SwapFailed("USDT -> WETH swap failed", address(usdt), address(weth), usdtReceived);
            revert("Swap USDT -> WETH failed");
        }
        require(wethReceived > 0, "No WETH received from second swap");
        uint256 currentWethBalance = weth.balanceOf(address(this));
        require(currentWethBalance >= amountOwed, "Arbitrage not profitable or insufficient WETH to repay loan");

        uint256 profit = currentWethBalance - amountOwed;
        weth.safeTransfer(address(POOL), amountOwed);

        emit FlashLoanExecuted(asset, amount, premium, profit);

        if (profit > 0) {
           
            weth.safeTransfer(owner, profit);
            emit Withdrawal(owner, address(weth), profit);
        }

        return true;
    }

    function requestFlashLoan(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Amount must be greater than 0");
        bytes memory params = ""; // Дополнительные параметры не используются
        uint16 referralCode = 0; // Реферальный код (обычно 0)
        POOL.flashLoanSimple(address(this), address(weth), _amount, params, referralCode);
        emit FlashLoanRequested(address(weth), _amount);
    }

    function calculateAmountOutMinimum(uint256 amountIn, uint256 slippage)
        internal
        pure
        returns (uint256)
    {
        require(slippage <= 10000, "Slippage exceeds 100%");
        return amountIn * (10000 - slippage) / 10000;
    }
    function getEthUsdPrice() public view returns (uint256) {
        ( , int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        require(price > 0, "ETH price must be positive");
        return uint256(price);
    }

    function withdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH balance to withdraw");
        (bool success, ) = payable(owner).call{value: balance}("");
        require(success, "ETH transfer failed");
        emit Withdrawal(owner, address(0), balance);
    }

    function withdrawWETH() external onlyOwner {
        uint256 balance = weth.balanceOf(address(this));
        require(balance > 0, "No WETH balance to withdraw");
        weth.safeTransfer(owner, balance);
        emit Withdrawal(owner, address(weth), balance);
    }

    function withdrawUSDT() external onlyOwner {
        uint256 balance = usdt.balanceOf(address(this));
        require(balance > 0, "No USDT balance to withdraw");
        usdt.safeTransfer(owner, balance);
        emit Withdrawal(owner, address(usdt), balance);
    }
    receive() external payable {}
}










