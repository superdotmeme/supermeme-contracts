// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.20;

// import "forge-std/Test.sol";
// import "../src/SuperMemeVesting.sol";
// import "../src/MockToken.sol";


// contract SuperMemeVestingTest is Test {
//     SuperMemeVesting public vestingContract;

//     address public owner = address(0x1);
//     address public user1 = address(0x2);
//     address public user2 = address(0x3);

//     MockToken public spr_token;

//     function setUp() public {
       
//         spr_token = new MockToken();
//         vestingContract = new SuperMemeVesting(address(spr_token));
        
//         spr_token.approve(address(vestingContract), 100000);
//         spr_token.transfer(address(vestingContract), 100000);

//         vestingContract.addVestingSchedule("Test Schedule", 100, 100, 5);
//     }

//     function testAddVestingSchedule() public {
//         (string memory name, uint256 totalSupply) = vestingContract.getVestingSchedule(0);
//         assertEq(name, "Test Schedule");
//         assertEq(totalSupply, 0);
//     }

//     function testAddBalances() public {
//         address[] memory addresses = new address[](2);
//         addresses[0] = user1;
//         addresses[1] = user2;

//         uint256[] memory balances = new uint256[](2);
//         balances[0] = 1000;
//         balances[1] = 2000;

//         vestingContract.addBalances(0, addresses, balances);

//         (string memory name, uint256 totalSupply) = vestingContract.getVestingSchedule(0);
//         assertEq(name, "Test Schedule");
//         assertEq(totalSupply, 3000);

//         uint256 balance1 = vestingContract.getBalances(0, user1);
//         uint256 balance2 = vestingContract.getBalances(0, user2);

//         assertEq(balance1, 1000);
//         assertEq(balance2, 2000);
//     }

//     function testDepositRewards() public {
//         address[] memory addresses = new address[](2);
//         addresses[0] = user1;
//         addresses[1] = user2;

//         uint256[] memory balances = new uint256[](2);
//         balances[0] = 1000;
//         balances[1] = 2000;

//         vestingContract.addBalances(0, addresses, balances);

//         uint256 depositAmount = 3 ether;
//         vestingContract.depositRewards{value: depositAmount}();

//         uint256 totalRewardAmount = vestingContract.getTotalRewardAmount(0);
//         uint256 rewardPerTokenStored = vestingContract.getRewardPerTokenStored(0);
//         assertEq(totalRewardAmount, depositAmount);
//         assertEq(rewardPerTokenStored, depositAmount * 1e18 / 3000);
//     }

//     function testClaimRewardCase1() public {
//         address[] memory addresses = new address[](2);
//         addresses[0] = user1;
//         addresses[1] = user2;

//         uint256[] memory balances = new uint256[](2);
//         balances[0] = 1000;
//         balances[1] = 2000;

//         vestingContract.addBalances(0, addresses, balances);

//         uint256 depositAmount = 3 ether;
//         vestingContract.depositRewards{value: depositAmount}();

//         // Simulate reward accumulation
//         uint256 beforeBalance1 = address(user1).balance;
//         uint256 beforeBalance2 = address(user2).balance;

//         vm.prank(user1);
//         vestingContract.claimReward(0);
//         vm.prank(user2);
//         vestingContract.claimReward(0);

//         uint256 afterBalance1 = address(user1).balance;
//         console.log(afterBalance1);
//         uint256 afterBalance2 = address(user2).balance;
//         console.log(afterBalance2);

//         assertEq(afterBalance1, depositAmount / 3 + beforeBalance1);
//         assertEq(afterBalance2, (depositAmount * 2) / 3 + beforeBalance2);

//         uint256 depositAmount2 = 10 ether;
//         vestingContract.depositRewards{value: depositAmount2}();

//         // Simulate reward accumulation
//         vm.prank(user1);
//         vestingContract.claimReward(0);
//         vm.prank(user2);
//         vestingContract.claimReward(0);

//         uint256 reward1_2 = address(user1).balance;
//         console.log(reward1_2);
//         uint256 reward2_2 = address(user2).balance;
//         console.log(reward2_2);

//         assertEq(reward1_2, (depositAmount / 3) + (depositAmount2 / 3) + beforeBalance1);
//         assertEq(reward2_2, ((depositAmount * 2) / 3) + ((depositAmount2 * 2) / 3) + beforeBalance2);


        
//     }

//     function testClaimRewardCase2() public {
//         address[] memory addresses = new address[](2);
//         addresses[0] = user1;
//         addresses[1] = user2;

//         uint256[] memory balances = new uint256[](2);
//         balances[0] = 1000;
//         balances[1] = 2000;

//         vestingContract.addBalances(0, addresses, balances);

//         uint256 depositAmount = 3 ether;
//         vestingContract.depositRewards{value: depositAmount}();

    
//         uint256 beforeBalance1 = address(user1).balance;
//         uint256 beforeBalance2 = address(user2).balance;


//         vm.prank(user1);
//         vestingContract.claimReward(0);
//         vm.prank(user2);
//         vestingContract.claimReward(0);

//         uint256 afterBalance1 = address(user1).balance;
//         console.log(afterBalance1);
//         uint256 afterBalance2 = address(user2).balance;
//         console.log(afterBalance2);
//         console.log("abuzer twist");

//         assertEq(afterBalance1, depositAmount / 3 + beforeBalance1);
//         assertEq(afterBalance2, (depositAmount * 2) / 3 + beforeBalance2);


//         uint256 depositAmount2 = 10 ether;
//         vestingContract.depositRewards{value: depositAmount2}();

//         // Simulate reward accumulation
//         vm.prank(user1);
//         vestingContract.claimReward(0);
//         vm.prank(user2);
//         vestingContract.claimReward(0);

//         uint256 reward1_2 = address(user1).balance;
//         console.log(reward1_2);
//         uint256 reward2_2 = address(user2).balance;
//         console.log(reward2_2);

//         assertEq(reward1_2, (depositAmount / 3) + (depositAmount2 / 3) + beforeBalance1);
//         assertEq(reward2_2, ((depositAmount * 2) / 3) + ((depositAmount2 * 2) / 3 + beforeBalance2));


//         vm.warp(block.timestamp + 1500000);

//         vm.prank(user1);
//         vestingContract.withdrawTokens(0);

//         uint256 depositAmount3 = 100 ether;
//         vestingContract.depositRewards{value: depositAmount3}();
//         // Simulate reward accumulation
//         vm.prank(user1);
//         vestingContract.claimReward(0);

//         uint256 reward1_3 = address(user1).balance;

//         assertEq(reward1_3, (depositAmount / 3) + (depositAmount2 / 3)  + beforeBalance1);

//         vm.prank(user2);
//         vestingContract.claimReward(0);
//         assertEq(address(user2).balance, ((depositAmount * 2) / 3) + ((depositAmount2 * 2) / 3) + depositAmount3 + beforeBalance2);

//     }

//     function testVestingSchedule() public {
//         uint256 scheduleIndex = 0;
//         uint256 unlockpercentage = vestingContract.getTGEUnlockPercentage(scheduleIndex);
//         uint256 claimable = vestingContract.getClaimablePercentage(scheduleIndex);
//         assertEq(unlockpercentage, 5);
//         assertEq(claimable, 5);
//         uint256 startTestTS = block.timestamp;
//         vm.warp(startTestTS + 50);
//         uint256 claimable2 = vestingContract.getClaimablePercentage(scheduleIndex);
//         assertEq(claimable2, 5);
//         vm.warp(startTestTS + 100);
//         uint256 claimable3 = vestingContract.getClaimablePercentage(scheduleIndex);
//         assertEq(claimable3, 5);
//         vm.warp(startTestTS + 150);
//         uint256 claimable4 = vestingContract.getClaimablePercentage(scheduleIndex);
//         assertEq(claimable4, 55);
//         vm.warp(startTestTS + 200);
//         uint256 claimable5 = vestingContract.getClaimablePercentage(scheduleIndex);
//         assertEq(claimable5, 100);
//         vm.warp(startTestTS + 250);
//         uint256 claimable6 = vestingContract.getClaimablePercentage(scheduleIndex);
//         assertEq(claimable6, 100);
        
//     }

//     function testRewardClaimingWithWarp() public {
//         address[] memory addresses = new address[](2);
//         addresses[0] = user1;
//         addresses[1] = user2;

//         uint256[] memory balances = new uint256[](2);
//         balances[0] = 1000;
//         balances[1] = 2000;

//         vestingContract.addBalances(0, addresses, balances);

//         vm.warp(block.timestamp + 50);
//         uint256 depositAmount = 3 ether;
//         vestingContract.depositRewards{value: depositAmount}();

//         vm.warp(block.timestamp + 50);

//         vm.prank(user1);
//         console.log("sdfsaafsdfa",spr_token.balanceOf(user1));
//         vm.prank(user1);
//         vestingContract.withdrawTokens(0);
//         assertEq(spr_token.balanceOf(user1), 50);

//         vm.warp(block.timestamp + 50);
//         vm.prank(user1);
//         vestingContract.withdrawTokens(0);
//         assertEq(spr_token.balanceOf(user1), 550 );

//         vestingContract.depositRewards{value: depositAmount}();
//         vm.warp(block.timestamp + 50);
//         vm.prank(user1);
//         vestingContract.claimReward(0);
//         assertEq(spr_token.balanceOf(user1), 550);

//         vm.prank(user2);
//         vestingContract.claimReward(0);
//         assertGt(address(user2).balance, address(user1).balance);
//         console.log(address(user2).balance);
//         console.log(address(user1).balance);
        
//     }

//     receive() external payable {}
// }


