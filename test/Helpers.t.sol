// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/DegenBondingCurveOne.sol";
import "../src/Helpers/RevenueCollector.sol";
import {IUniswapFactory} from "../src/Interfaces/IUniswapFactory.sol";
import {IUniswapV2Router02} from "../src/Interfaces/IUniswapV2Router02.sol";
import {SuperMemeFactory} from "../src/SuperMemeFactory.sol";
import {SuperMemeVesting} from "../src/SuperMemeVesting.sol";
import {MockToken} from "../src/MockToken.sol";


contract DegenBondingCurveOneTest is Test {
    DegenBondingCurveOne public newTokenInstance;
    RevenueCollector public revenueCollector;

    address owner = address(0x123);
    address addr1 = address(0x456);
    address addr2 = address(0x789);
    address addr3 = address(0x101112);

    address fakeContract = address(0x12123123);

    IUniswapFactory public uniswapFactory;
    IUniswapV2Router02 public uniswapV2Router;
    SuperMemeFactory public superMemeFactory;
    SuperMemeVesting public superMemeVesting;
    SuperMemeVesting public superMemeStaking;
    MockToken public mockToken;

    uint256 tokenCreationFee = 0.0003 ether;


    function setUp() public {

        bool devLockedTest = false;
        uint256 amount = 0;

        vm.deal(owner, 1000 ether);

        uniswapV2Router = IUniswapV2Router02(0x5633464856F58Dfa9a358AfAf49841FEE990e30b);
        uniswapFactory = IUniswapFactory(uniswapV2Router.factory());
    
        mockToken = new MockToken();
        superMemeVesting = new SuperMemeVesting(address(mockToken));
        superMemeStaking = new SuperMemeVesting(address(mockToken));
        revenueCollector = new RevenueCollector(address(mockToken), address(superMemeVesting), address(fakeContract));
        superMemeFactory = new SuperMemeFactory(address(revenueCollector));
        vm.startPrank(owner);
        console.log("owner", owner);
        address newToken = (superMemeFactory.createToken{value: tokenCreationFee}(devLockedTest, amount));
        console.log("newToken", newToken);
        address payable newTokenPayable = payable(newToken);
        newTokenInstance = DegenBondingCurveOne(newTokenPayable);

        
        vm.stopPrank();
    }

    function testFinishBondingCurve() public {
        address mock1 = address(0x123456);
        address mock2 = address(0x123457);
        address mock3 = address(0x123458);

        uint256 startBalance = 1000 ether;
        vm.startPrank(mock1);

        uint256 amount = 800000000;

        vm.deal(mock1, startBalance);
        vm.deal(mock2, startBalance);
        vm.deal(mock3, startBalance);

        
        uint256 cost = newTokenInstance.calculateCost(amount);
        uint256 tax = (cost * 1000) / 100000;

        newTokenInstance.buyTokens{value: cost + tax}(amount);

        assertEq(newTokenInstance.balanceOf(mock1), amount * 10 ** 18);
        assertEq(newTokenInstance.bondingCurveCompleted(), true);
        vm.stopPrank();


    }
}