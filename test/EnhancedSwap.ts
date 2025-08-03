
import { expect } from "chai";
import { ethers } from "hardhat";
import { EnhancedSwap, IERC20 } from "../typechain-types";

describe("EnhancedSwap with Real Contracts (Sepolia)", function () {

  it("Should allow owner to withdraw USDT", async function () {
    const [owner] = await ethers.getSigners();

    const WETH_ADDRESS = "0xD0dF82dE051244f04BfF3A8bB1f62E1cD39eED92";
    const USDT_ADDRESS = "0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0";
    const SWAP_ROUTER_ADDRESS = "0x94cC0AaC535CCDB3C01d6787D6413C739ae12bc4";
    const ETH_USD_PRICE_FEED = "0x694AA1769357215DE4FAC081bf1f309aDC325306";

  
    const EnhancedSwapFactory = await ethers.getContractFactory("EnhancedSwap");
    const enhancedSwap = (await EnhancedSwapFactory.deploy(
      WETH_ADDRESS,
      USDT_ADDRESS,
      SWAP_ROUTER_ADDRESS,
      ETH_USD_PRICE_FEED
    )) as EnhancedSwap;
    await enhancedSwap.waitForDeployment();
    const enhancedSwapAddress = await enhancedSwap.getAddress();
    console.log("EnhancedSwap deployed to:", enhancedSwapAddress);

   
    const usdt = (await ethers.getContractAt("IERC20", USDT_ADDRESS)) as IERC20;

    const depositAmount = ethers.parseUnits("10", 6); // 10 USDT (6 decimals)

    console.log(`Owner's USDT balance before deposit: ${ethers.formatUnits(await usdt.balanceOf(owner.address), 6)}`);
    console.log(`Sending ${ethers.formatUnits(depositAmount, 6)} USDT from owner to EnhancedSwap contract...`);
    await usdt.connect(owner).transfer(enhancedSwapAddress, depositAmount);
    console.log("USDT sent to EnhancedSwap contract.");

    // Проверки и вызов withdraw
    const initialContractBalance = await usdt.balanceOf(enhancedSwapAddress);
    console.log(`EnhancedSwap contract's initial USDT balance: ${ethers.formatUnits(initialContractBalance, 6)}`);
    expect(initialContractBalance).to.be.gte(depositAmount, "Contract has insufficient USDT after deposit");

    const initialOwnerBalance = await usdt.balanceOf(owner.address);
    console.log(`Owner's USDT balance before withdrawal: ${ethers.formatUnits(initialOwnerBalance, 6)}`);

    console.log("Calling withdraw() from EnhancedSwap contract...");
    await enhancedSwap.connect(owner).withdraw();
    console.log("Withdrawal successful.");

    const finalOwnerBalance = await usdt.balanceOf(owner.address);
    const finalContractBalance = await usdt.balanceOf(enhancedSwapAddress);
    console.log(`Owner's USDT balance after withdrawal: ${ethers.formatUnits(finalOwnerBalance, 6)}`);
    console.log(`EnhancedSwap contract's final USDT balance: ${ethers.formatUnits(finalContractBalance, 6)}`);

    expect(finalOwnerBalance).to.be.gt(initialOwnerBalance, "Withdrawal failed: Owner's balance did not increase");
    expect(finalContractBalance).to.equal(0, "Withdrawal failed: Contract balance not zeroed out");
  });
});
