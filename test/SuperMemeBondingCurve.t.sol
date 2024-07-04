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

    SuperMemeBondingCurve public bondingCurve;
    RevenueCollector public revenueCollector;
    IUniswapFactory public uniswapFactory;

    struct TestScenario {
        address user;
        address user2;
        uint256 amount;
        uint256 iterations;
        uint256 iterations2;

    }

    TestScenario[] testScenarios;

    function setUp() public {
        uniswapFactory = IUniswapFactory(address(0x1));
        bondingCurve = new SuperMemeBondingCurve(
            "SuperMeme",
            "SPR",
            0,
            address(0x1),
            address(0x2)
        );

        // Initialize test scenarios
        testScenarios.push(TestScenario(addr1, addr2, 1_000_000, 5,7));
        testScenarios.push(TestScenario(addr1, addr2, 1_000_000, 20,20));
        testScenarios.push(TestScenario(addr1, addr2, 1_000_000, 30,30));
        testScenarios.push(TestScenario(addr1, addr2, 1_000_000, 40,40));
        testScenarios.push(TestScenario(addr1, addr2, 1_000_000, 10,50));
        testScenarios.push(TestScenario(addr1, addr2, 1_000_000, 10,30));

        vm.deal(addr1, 100 ether);
        vm.deal(addr2, 1000 ether);
    }

    function testScenariosFunc() public {
        
        for (uint256 i = 0; i < testScenarios.length; i++) {
            TestScenario memory scenario = testScenarios[i];
            uint256 totalEthPaidUser1;
            uint256 totalTokensBoughtUser1;

            uint256 totalEthPaidUser2;
            uint256 totalTokensBoughtUser2;

            for (uint256 j = 0; j < scenario.iterations; j++) {
                vm.startPrank(scenario.user);
                uint256 cost = bondingCurve.calculateCost(scenario.amount);
                uint256 tax = (cost * 1000) / 100000;
                bondingCurve.buyTokens{value: cost + tax}(scenario.amount);
                totalEthPaidUser1 += cost + tax;
                totalTokensBoughtUser1 += scenario.amount * 10 ** 18;
                vm.stopPrank();
            }

            console.log(" %s bought %s tokens for %s eth", "user1", totalTokensBoughtUser1 / 10 ** 18, totalEthPaidUser1);

            for (uint256 j = 0; j < scenario.iterations2; j++) {
                vm.startPrank(scenario.user2);
                uint256 cost = bondingCurve.calculateCost(scenario.amount);
                uint256 tax = (cost * 1000) / 100000;
                bondingCurve.buyTokens{value: cost + tax}(scenario.amount);
                totalEthPaidUser2 += cost + tax;
                totalTokensBoughtUser2 += scenario.amount * 10 ** 18;
                vm.stopPrank();
            }

            console.log(" %s bought %s tokens for %s eth", "user2", totalTokensBoughtUser2 / 10 ** 18, totalEthPaidUser2);

            vm.startPrank(scenario.user);
            console.log(" %s decides to refund", "user1");
            console.log("total tokens user1 has", bondingCurve.balanceOf(scenario.user) / 10 ** 18);
            uint256 refundAmount = bondingCurve.calculateTokensRefund(totalEthPaidUser1);
                        console.log("     ");
            console.log("     ");
            vm.stopPrank();
        }
    }


    function testUpdateBalance() public {
        bondingCurve.updateBalance();
    }
}
