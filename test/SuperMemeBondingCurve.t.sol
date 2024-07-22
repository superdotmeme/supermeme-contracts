// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/SuperMemeBondingCurve.sol";
import "../src/Helpers/RevenueCollector.sol";
import {IUniswapFactory} from "../src/Interfaces/IUniswapFactory.sol";

contract SuperMemeBondingCurveTest is Test {
    address owner = address(0x123);
    address addr1 = address(0x456);
    address addr2 = address(0x789);
    address addr3 = address(0x101112);

    address fakeContract = address(0x12123123);

    uint256 public dummyBuyAmount = 10000;

    SuperMemeBondingCurve public bondingCurve;
    RevenueCollector public revenueCollector;
    IUniswapFactory public uniswapFactory;
    address[] users = new address[](1100);

    struct TestScenario {
        address user;
        address user2;
        uint256 amount;
        uint256 iterations;
        uint256 iterations2;
    }

    function setUp() public {
        uniswapFactory = IUniswapFactory(address(0x1));
        bondingCurve = new SuperMemeBondingCurve(
            "SuperMeme",
            "SPR",
            0,
            address(0x1),
            address(0x2)
        );

        for (uint256 i = 0; i < 1005; i++) {
            address account1 = makeAddr(vm.toString(i));
            users[i] = account1;
            vm.deal(account1, 1000 ether);
        }

        vm.deal(addr1, 1000 ether);
    }
    function testBuyTokens() public {
        vm.startPrank(addr1);
        uint256 cost = bondingCurve.calculateCost(dummyBuyAmount);
        uint256 tax = (cost * 1000) / 100000;
        bondingCurve.buyTokens{value: cost + tax}(dummyBuyAmount);
        assertEq(bondingCurve.balanceOf(addr1), dummyBuyAmount * 10 ** 18);
        vm.stopPrank();
    }
    function testBuyTokens1000user() public {
        vm.startPrank(addr1);
        for (uint256 i = 0; i < 2; i++) {
            uint256 cost = bondingCurve.calculateCost(dummyBuyAmount);
            uint256 tax = (cost * 1000) / 100000;
            bondingCurve.buyTokens{value: cost + tax}(dummyBuyAmount);
            //assertEq(bondingCurve.balanceOf(addr1), dummyBuyAmount * 10 ** 18);
        }
        vm.stopPrank();
        for (uint256 i = 0; i < 800; i++) {
            vm.startPrank(users[i]);
            uint256 cost = bondingCurve.calculateCost(dummyBuyAmount);
            uint256 tax = (cost * 1000) / 100000;
            bondingCurve.buyTokens{value: cost + tax}(dummyBuyAmount);
            assertEq(
                bondingCurve.balanceOf(users[i]),
                dummyBuyAmount * 10 ** 18
            );
            vm.stopPrank();
        }
        vm.startPrank(addr1);
        for (uint256 i = 0; i < 1; i++) {
            uint256 cost = bondingCurve.calculateCost(dummyBuyAmount);
            uint256 tax = (cost * 1000) / 100000;
            bondingCurve.buyTokens{value: cost + tax}(dummyBuyAmount);
            //assertEq(bondingCurve.balanceOf(addr1), dummyBuyAmount * 10 ** 18);
        }
        vm.stopPrank();
        for (uint256 i = 0; i < 200; i++) {
            vm.startPrank(users[i]);
            uint256 cost = bondingCurve.calculateCost(dummyBuyAmount);
            uint256 tax = (cost * 1000) / 100000;
            bondingCurve.buyTokens{value: cost + tax}(dummyBuyAmount);
            vm.stopPrank();
        }
        vm.startPrank(addr1);
        for (uint256 i = 0; i < 2; i++) {
            uint256 cost = bondingCurve.calculateCost(dummyBuyAmount);
            uint256 tax = (cost * 1000) / 100000;
            bondingCurve.buyTokens{value: cost + tax}(dummyBuyAmount);
            //assertEq(bondingCurve.balanceOf(addr1), dummyBuyAmount * 10 ** 18);
        }
        vm.stopPrank();

        //user1 refunds
        vm.startPrank(addr1);
        bondingCurve.refund();
        vm.stopPrank();
    }

    function testRefund() public {
        vm.startPrank(addr1);
        uint256 etherBalanceBefore = address(addr1).balance;
        uint256 cost = bondingCurve.calculateCost(dummyBuyAmount);
        uint256 tax = (cost * 1000) / 100000;
        bondingCurve.buyTokens{value: cost + tax}(dummyBuyAmount);
        assertEq(bondingCurve.balanceOf(addr1), dummyBuyAmount * 10 ** 18);
        bondingCurve.refund();
        uint256 etherBalanceAfter = address(addr1).balance;
        assertEq(address(bondingCurve).balance, 0);
        assertApproxEqAbs(
            etherBalanceAfter,
            etherBalanceBefore - tax - (tax * 9) / 10,
            0.00001 ether
        );
        vm.stopPrank();
    }
}
