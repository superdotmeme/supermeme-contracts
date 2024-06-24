pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../SuperMemeVesting.sol";
//import degenbondingcurveone
import "../MockToken.sol";


contract RevenueCollector {

    MockToken public mockToken;
    SuperMemeVesting public superMemeVesting;
    address public superMemeStaking;

    uint256 public sprBalance;
    uint256 public totalEtherCollected;



    constructor(address _mockToken, address _superMemeVesting, address _superMemeStaking) {
        mockToken = MockToken(_mockToken);
        superMemeVesting = SuperMemeVesting(payable(_superMemeVesting));
        superMemeStaking = _superMemeStaking;

    }

    receive() external payable {}


    function distrubuteRevenue() public payable {
        uint256 vestingBalance = mockToken.balanceOf(address(superMemeVesting));
        uint256 stakingBalance = mockToken.balanceOf(superMemeStaking);
        uint256 totalSupply = mockToken.totalSupply();
        uint256 amountToDistribute = address(this).balance;
        uint256 totalVesting = (vestingBalance * amountToDistribute) / totalSupply;
        uint256 totalStaking = (stakingBalance * amountToDistribute) / totalSupply;

        payable(address(superMemeVesting)).transfer(totalVesting);
        payable(address(superMemeStaking)).transfer(totalStaking);

    }
}

