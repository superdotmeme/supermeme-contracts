// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/DegenBondingCurveOne.sol";
import "../src/Helpers/RevenueCollector.sol";
import {IUniswapFactory} from "../src/Interfaces/IUniswapFactory.sol";

contract DegenBondingCurveOneTest is Test {
    DegenBondingCurveOne public degenBondingCurveOne;
    RevenueCollector public revenueCollector;

    address owner = address(0x123);
    address addr1 = address(0x456);
    address addr2 = address(0x789);
    address addr3 = address(0x101112);

    address fakeContract = address(0x12123123);

    IUniswapFactory public uniswapFactory;
    IUniswapV2Router02 public uniswapV2Router;
    MockToken public mockToken;


    function setUp() public {
        uniswapV2Router = IUniswapV2Router02(0x5633464856F58Dfa9a358AfAf49841FEE990e30b);
        uniswapFactory = IUniswapFactory(uniswapV2Router.factory());
        bool devLockedTest = false;
        mockToken = new MockToken();
        revenueCollector = new RevenueCollector(address(mockToken), fakeContract, fakeContract);
        vm.startPrank(owner);
        if (devLockedTest) {
            degenBondingCurveOne = new DegenBondingCurveOne(devLockedTest, 100, owner, address(revenueCollector));
        } else {
            
            degenBondingCurveOne = new DegenBondingCurveOne(devLockedTest, 0, owner, address(revenueCollector));
        }
        
        
        vm.stopPrank();
    }

    function testInitialSetup() public {
        assertEq(degenBondingCurveOne.totalEtherCollected(), 0);
        assertEq(degenBondingCurveOne.scaledSupply(), 200_000_000);
        assertEq(degenBondingCurveOne.balanceOf(address(degenBondingCurveOne)), 200_000_000 * 10**18);
    }

    function testCalculateCost() public {
        // Testing for different amounts of tokens to be purchased
        uint256 amount1 = 1_000_000; // 1 million tokens
        uint256 amount2 = 10_000_000; // 10 million tokens
        uint256 amount3 = 100_000_000; // 100 million tokens
        uint256 amount4 = 800_000_000; // 800 million tokens

        uint256 cost1 = degenBondingCurveOne.calculateCost(amount1);
        uint256 cost2 = degenBondingCurveOne.calculateCost(amount2);
        uint256 cost3 = degenBondingCurveOne.calculateCost(amount3);
        uint256 cost4 = degenBondingCurveOne.calculateCost(amount4);

        console.log("Cost for 1 million tokens: ", cost1);
        console.log("Cost for 10 million tokens: ", cost2);
        console.log("Cost for 100 million tokens: ", cost3);
        console.log("Cost for 800 million tokens: ", cost4);

        // Verify the cost values
        assertGt(cost2, cost1, "Cost for 10 million should be greater than cost for 1 million");
        assertGt(cost3, cost2, "Cost for 100 million should be greater than cost for 10 million");
    }

    function testCalculateCostGetPoints() public {
        // Testing for different amounts of tokens to be purchased
        for (uint256 i = 1; i <= 800; i += 5) {
            uint256 amount = i * 1_000_000; // 1 million tokens
            uint256 cost = degenBondingCurveOne.calculateCost(amount);
            //cost per token
            console.log("Cost per token for  ", i, " million tokens: ", cost / amount);
            console.log("Cost for ", i, " million tokens: ", cost);
        }
    }


    function testSellTokensTest()  public {
        vm.startPrank(addr1);
        vm.deal(addr1, 5 ether);

        uint256 begginningBalance = address(addr1).balance;

        uint256 amount = 1_000_000; // 1 million tokens
        uint256 cost = degenBondingCurveOne.calculateCost(amount);
        uint256 tax = cost * 1000 / 100000;
        degenBondingCurveOne.buyTokens{value: cost + tax}(amount);
        uint256 amountToCheck = amount * 10 ** 18;
        console.log("progress");
        assertEq(degenBondingCurveOne.balanceOf(addr1), amountToCheck);
        console.log("progress");
        assertEq(degenBondingCurveOne.totalEtherCollected(), cost );
        console.log("progress");

        uint256 refund = degenBondingCurveOne.calculateRefund(amount);

        degenBondingCurveOne.sellTokens(amount);
        assertEq(degenBondingCurveOne.balanceOf(addr1), 0);
        console.log("progress");

        assertEq(degenBondingCurveOne.totalEtherCollected(), 0);
        uint256 endBalance = address(addr1).balance;
        assertApproxEqAbs(endBalance, begginningBalance - tax * 2,  0.0000001 ether);

        assertEq(address(revenueCollector).balance, tax * 2);


        vm.stopPrank();
    }


 function testFlow() public {
    vm.deal(addr1, 5 ether);
    vm.deal(addr2, 5 ether);

    uint256 beginningBalanceAddr1 = address(addr1).balance;
    uint256 beginningBalanceAddr2 = address(addr2).balance;

    uint256 amount = 1_000_000; // 1 million tokens
    // Buy tokens for address one with a loop
    for (uint256 i = 0; i < 10; i++) {
        vm.startPrank(addr1);
        uint256 cost = degenBondingCurveOne.calculateCost(amount);
        uint256 pricePerToken = cost / amount;
        uint256 tax = cost * 1000 / 100000;
        uint256 beforeBalance = degenBondingCurveOne.balanceOf(addr1);
        degenBondingCurveOne.buyTokens{value: cost + tax}(amount);
        
        uint256 amountToCheck = amount * 10 ** 18;
        assertEq(degenBondingCurveOne.balanceOf(addr1), amountToCheck + beforeBalance);
        console.log("Buyer: addr1, Tokens Bought: %s, Price per Token: %s wei", amount, pricePerToken);
        vm.stopPrank();
    }

    // Buy tokens for address two with a loop
    for (uint256 i = 0; i < 10; i++) {
        vm.startPrank(addr2);
        uint256 cost = degenBondingCurveOne.calculateCost(amount);
        uint256 pricePerToken = cost / amount;
        uint256 tax = cost * 1000 / 100000;
        uint256 beforeBalance = degenBondingCurveOne.balanceOf(addr2);
        degenBondingCurveOne.buyTokens{value: cost + tax}(amount);
        uint256 amountToCheck = amount * 10 ** 18;
        assertEq(degenBondingCurveOne.balanceOf(addr2), amountToCheck + beforeBalance);
        console.log("Buyer: addr2, Tokens Bought: %s, Price per Token: %s wei", amount, pricePerToken);
        vm.stopPrank();
    }

    // Sell tokens for address one with a loop
    vm.startPrank(addr1);
    uint256 beforeBalance = address(addr1).balance;
    uint256 tokensToSell = degenBondingCurveOne.balanceOf(addr1);
    uint256 refund = degenBondingCurveOne.calculateRefund(tokensToSell / 10 ** 18);
    uint256 tax = refund * 1000 / 100000;
    degenBondingCurveOne.sellTokens(tokensToSell / 10 ** 18);
    assertEq(degenBondingCurveOne.balanceOf(addr1), 0);
    uint256 endBalance = address(addr1).balance;
    assertGt(endBalance, beginningBalanceAddr1, "Balance should be greater than the initial balance");
    console.log("Seller: addr1, Tokens Sold: %s, Refund: %s wei", tokensToSell / 10 ** 18, refund - tax);
    console.log("Profit: %s wei", endBalance - beforeBalance);
    vm.stopPrank();
}

function testComplexTestFlow() public {
    // Setup initial balances
    vm.deal(addr1, 10 ether);
    vm.deal(addr2, 8 ether);
    vm.deal(addr3, 12 ether);

    // Store initial balances
    uint256 initialBalanceAddr1 = address(addr1).balance;
    uint256 initialBalanceAddr2 = address(addr2).balance;
    uint256 initialBalanceAddr3 = address(addr3).balance;

    // Define amounts for transactions
    uint256 smallAmount = 500_000; // 500,000 tokens
    uint256 largeAmount = 2_000_000; // 2 million tokens

    // Address 1 buys smallAmount tokens in multiple transactions
    for (uint256 i = 0; i < 5; i++) {
        vm.startPrank(addr1);
        uint256 cost = degenBondingCurveOne.calculateCost(smallAmount);
        uint256 pricePerToken = cost / smallAmount;
        uint256 tax = cost * 1000 / 100000;
        uint256 beforeBalance = degenBondingCurveOne.balanceOf(addr1);
        degenBondingCurveOne.buyTokens{value: cost + tax}(smallAmount);

        uint256 expectedBalance = smallAmount * 10 ** 18;
        assertEq(degenBondingCurveOne.balanceOf(addr1), expectedBalance + beforeBalance);
         uint256 totalSupply = degenBondingCurveOne.totalSupply();
        console.log("Buyer: addr1, Tokens Bought: %s, Price per Token: %s wei", smallAmount, pricePerToken);
        vm.stopPrank();
    }

    // Address 2 buys largeAmount tokens
    vm.startPrank(addr2);
    uint256 cost = degenBondingCurveOne.calculateCost(largeAmount);
    uint256 pricePerToken = cost / largeAmount;
    uint256 tax = cost * 1000 / 100000;
    degenBondingCurveOne.buyTokens{value: cost + tax}(largeAmount);

    uint256 expectedBalance = largeAmount * 10 ** 18;
    assertEq(degenBondingCurveOne.balanceOf(addr2), expectedBalance);
    uint256 totalSupply = degenBondingCurveOne.totalSupply();
    console.log("Buyer: addr2, Tokens Bought: %s, Price per Token: %s wei", largeAmount, pricePerToken);
    console.log("Total Supply:", totalSupply);
        vm.stopPrank();

    // Address 3 buys largeAmount tokens in one go
    vm.startPrank(addr3);
    cost = degenBondingCurveOne.calculateCost(largeAmount);
    pricePerToken = cost / largeAmount;
    tax = cost * 1000 / 100000;
    degenBondingCurveOne.buyTokens{value: cost + tax}(largeAmount);
    assertEq(degenBondingCurveOne.balanceOf(addr3), expectedBalance);
      totalSupply = degenBondingCurveOne.totalSupply();
    console.log("Buyer: addr3, Tokens Bought: %s, Price per Token: %s wei", largeAmount, pricePerToken);
    console.log("Total Supply:", totalSupply);
    vm.stopPrank();

    vm.startPrank(addr1);
    uint256 tokensToSell = degenBondingCurveOne.balanceOf(addr1) ;
    uint256 refund = degenBondingCurveOne.calculateRefund(tokensToSell / 10 ** 18);
    tax = refund * 1000 / 100000;
    degenBondingCurveOne.sellTokens(tokensToSell / 10 ** 18);
    assertEq(degenBondingCurveOne.balanceOf(addr1), 0);
      totalSupply = degenBondingCurveOne.totalSupply();
    console.log("Seller: addr1, Tokens Sold: %s, Refund: %s wei", tokensToSell / 10 ** 18, refund - tax);
    console.log("Total Supply:", totalSupply);
    vm.stopPrank();

    // Address 2 sells all their tokens
    vm.startPrank(addr2);
    tokensToSell = degenBondingCurveOne.balanceOf(addr2);
    refund = degenBondingCurveOne.calculateRefund(tokensToSell / 10 ** 18);
    tax = refund * 1000 / 100000;
    degenBondingCurveOne.sellTokens(tokensToSell / 10 ** 18);
    assertEq(degenBondingCurveOne.balanceOf(addr2), 0);
      totalSupply = degenBondingCurveOne.totalSupply();
    console.log("Seller: addr2, Tokens Sold: %s, Refund: %s wei", tokensToSell / 10 ** 18, refund - tax);
    vm.stopPrank();

    // Assert final balances
    assertGt(address(addr1).balance, initialBalanceAddr1, "Address 1 should have more balance than initial");
    assertGt( initialBalanceAddr2,address(addr2).balance, "Address 2 should have more balance than initial");
    // Concurrent Transactions

    vm.startPrank(addr3);
    uint256 concurrentAmount = 100_000; // 100,000 tokens
    cost = degenBondingCurveOne.calculateCost(concurrentAmount);
    pricePerToken = cost / concurrentAmount;
    tax = cost * 1000 / 100000;

    degenBondingCurveOne.buyTokens{value: cost + tax}(concurrentAmount);
      totalSupply = degenBondingCurveOne.totalSupply();
    console.log( totalSupply, "Buyer: addr3, Tokens Bought: %s, Price per Token: %s wei", concurrentAmount, pricePerToken);
    vm.stopPrank();
    assertEq(degenBondingCurveOne.balanceOf(addr1), 0);
    assertEq(degenBondingCurveOne.balanceOf(addr3), (largeAmount + concurrentAmount) * 10 ** 18);
}


    function testTotalSupplyvsTotalEtherCollected() public {
        vm.deal(addr1, 5 ether);
        for (uint256 i = 0; i < 80; i++) {
            vm.startPrank(addr1);
            uint256 amount = 10_000_000; // 1 million tokens
            uint256 cost = degenBondingCurveOne.calculateCost(amount);
            uint256 tax = (cost * 1000) / 100000;
            degenBondingCurveOne.buyTokens{value: cost + tax}(amount);
            console.log("Total Supply: ", degenBondingCurveOne.totalSupply() / 10 ** 18, "Total Ether Collected: ", degenBondingCurveOne.totalEtherCollected());
            vm.stopPrank();
        }
    }

    function testTotalSupllyvsTotalEtherCollectedDownwards() public {
        vm.deal(addr1, 5 ether);
        for (uint256 i = 0; i < 79; i++) {
            vm.startPrank(addr1);
            uint256 amount = 10_000_000; // 1 million tokens
            uint256 cost = degenBondingCurveOne.calculateCost(amount);
            uint256 tax = (cost * 1000) / 100000;
            degenBondingCurveOne.buyTokens{value: cost + tax}(amount);
            //console.log("Total Supply: ", degenBondingCurveOne.totalSupply() / 10 ** 18, "Total Ether Collected: ", degenBondingCurveOne.totalEtherCollected());
            vm.stopPrank();
        }
        console.log("Total Supply: ", degenBondingCurveOne.totalSupply() / 10 ** 18, "Total Ether Collected: ", degenBondingCurveOne.totalEtherCollected());
        for (uint256 i = 0; i < 79; i++) {
            vm.startPrank(addr1);
            uint256 amount = 10_000_000; // 1 million tokens
            uint256 refund = degenBondingCurveOne.calculateRefund(amount);
            uint256 tax = (refund * 1000) / 100000;
            degenBondingCurveOne.sellTokens(amount);
            console.log("Total Supply: ", degenBondingCurveOne.totalSupply() / 10 ** 18, "Total Ether Collected: ", degenBondingCurveOne.totalEtherCollected());
            vm.stopPrank();
        }
    }

    function testTotalSupplyvsPricePerToken() public {
        vm.deal(addr1, 5 ether);
        for (uint256 i = 0; i < 80; i++) {
            vm.startPrank(addr1);
            uint256 amount = 10_000_000; // 1 million tokens
            uint256 cost = degenBondingCurveOne.calculateCost(amount);
            uint256 tax = (cost * 1000) / 100000;
            degenBondingCurveOne.buyTokens{value: cost + tax}(amount);
            console.log("Total Supply: ", degenBondingCurveOne.totalSupply() / 10 ** 18, "Price per Token: ", cost / amount);
            vm.stopPrank();
        }
    }

        function testTotalSupplyvsPricePerTokenDownwards() public {
        vm.deal(addr1, 5 ether);
        for (uint256 i = 0; i < 79; i++) {
            vm.startPrank(addr1);
            uint256 amount = 10_000_000; // 1 million tokens
            uint256 cost = degenBondingCurveOne.calculateCost(amount);
            uint256 tax = (cost * 1000) / 100000;
            degenBondingCurveOne.buyTokens{value: cost + tax}(amount);
            //console.log("Total Supply: ", degenBondingCurveOne.totalSupply() / 10 ** 18, "Price per Token: ", cost / amount);
            vm.stopPrank();
        }

        console.log("Total Supply: ", degenBondingCurveOne.totalSupply() / 10 ** 18, "Price per Token: ", degenBondingCurveOne.calculateCost(10_000_000) / 10_000_000);

        for (uint256 i = 0; i < 79; i++) {
            vm.startPrank(addr1);
            uint256 amount = 10_000_000; // 1 million tokens
            uint256 refund = degenBondingCurveOne.calculateRefund(amount);
            uint256 tax = (refund * 1000) / 100000;
            degenBondingCurveOne.sellTokens(amount);
            console.log("Total Supply: ", degenBondingCurveOne.totalSupply() / 10 ** 18, "Price per Token: ", refund / amount);
            vm.stopPrank();
        }        
        }

    function testSendToDex() public {
        vm.deal(addr1, 5 ether);
        vm.deal(addr2, 5 ether);
        vm.deal(addr3, 5 ether);

        for (uint256 i = 0; i < 80; i++) {
            vm.startPrank(addr1);
            uint256 amount = 10_000_000; // 1 million tokens
            uint256 cost = degenBondingCurveOne.calculateCost(amount);
            uint256 tax = (cost * 1000) / 100000;
            degenBondingCurveOne.buyTokens{value: cost + tax}(amount);
            vm.stopPrank();
        }

        assertEq(degenBondingCurveOne.bondingCurveCompleted(), true);
        degenBondingCurveOne.sendToDex();
        assertEq(degenBondingCurveOne.balanceOf(address(degenBondingCurveOne)), 0);
        address pair = (
            uniswapFactory.getPair(address(degenBondingCurveOne), uniswapV2Router.WETH())
        );

        assertEq(degenBondingCurveOne.balanceOf(pair), (200_000_000 * 10 ** 18));
        assertEq(degenBondingCurveOne.totalSupply(), 1_000_000_000 * 10 ** 18);

    }

}

