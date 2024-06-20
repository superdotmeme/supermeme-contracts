import "forge-std/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
pragma solidity ^0.8.20;

contract SuperMemeVesting {
    struct VestingSchedule {
        string name;
        mapping(address => uint256) balances;
        mapping(address => uint256) rewards;
        uint256 rewardPerTokenStored;
        uint256 totalSupply;
        uint256 totalRewardAmount;
        mapping(address => uint256) userRewardPerTokenPaid;
        uint256 initialTimestamp;
        uint256 cliffDuration;
        uint256 vestingDuration;
        mapping(address => uint256) initialBalances;
        uint256 TGEUnlockPercentage;
    }

    VestingSchedule[] public vestingSchedules;

    ERC20 public spr_token;
    constructor(address _spr_token) {
        spr_token = ERC20(_spr_token);
    }

    //adminitravie functions

    function addVestingSchedule(
        string memory _name,
        uint256 _cliffDuration,
        uint256 _vestingDuration,
        uint256 _TGEUnlockPercentage
    ) public {
        VestingSchedule storage newVestingSchedule = vestingSchedules.push();
        newVestingSchedule.name = _name;
        newVestingSchedule.initialTimestamp = block.timestamp;
        newVestingSchedule.cliffDuration = _cliffDuration;
        newVestingSchedule.vestingDuration = _vestingDuration;
        newVestingSchedule.TGEUnlockPercentage = _TGEUnlockPercentage;
    }

    function addBalances(
        uint256 scheduleIndex,
        address[] calldata _addresses,
        uint256[] calldata _balances
    ) public {
        VestingSchedule storage schedule = vestingSchedules[scheduleIndex];
        require(_addresses.length == _balances.length, "Invalid input length");
        for (uint256 i = 0; i < _addresses.length; i++) {
            schedule.balances[_addresses[i]] = _balances[i];
            schedule.totalSupply += _balances[i];
            schedule.initialBalances[_addresses[i]] = _balances[i];
            updateReward(scheduleIndex, _addresses[i]);
        }
    }

    //vesting related functions

    function withdrawTokens(uint256 scheduleIndex) public {
        VestingSchedule storage schedule = vestingSchedules[scheduleIndex];
        updateReward(scheduleIndex, msg.sender);
        uint256 reward = schedule.rewards[msg.sender];
        if (reward > 0) {
            schedule.rewards[msg.sender] = 0;
            payable(msg.sender).transfer(reward);
        }
        console.log("handled rewards");

        //change this part when the algorithm is ready
        uint256 balance = schedule.balances[msg.sender];
        uint256 initialBalance = schedule.initialBalances[msg.sender];
        console.log("balance: %d", balance);
        if (balance > 0) {
            uint256 claimablePercentage = getClaimablePercentage(scheduleIndex);
            console.log("claimablePercentage: %d", claimablePercentage);
            uint256 initialBalance = schedule.initialBalances[msg.sender];
            uint256 claimedAmount = initialBalance - balance;
            console.log("claimedAmount: %d", claimedAmount);
            uint256 claimableAmount = (initialBalance * claimablePercentage) /
                100 -
                claimedAmount;
            console.log("claimableAmount: %d", claimableAmount);
            schedule.balances[msg.sender] -= claimableAmount;

            spr_token.transfer(msg.sender, claimableAmount);

            schedule.totalSupply -= claimableAmount;
        }
    }

    function getClaimablePercentage(
        uint256 scheduleIndex
    ) public view returns (uint256) {
        VestingSchedule storage schedule = vestingSchedules[scheduleIndex];
        uint256 totalVestingDuration = schedule.cliffDuration +
            schedule.vestingDuration;
        uint256 timePassed = block.timestamp - schedule.initialTimestamp;
        if (timePassed <= schedule.cliffDuration) {
            console.log("timePassed < schedule.cliffDuration");
            return schedule.TGEUnlockPercentage;
        } else if (timePassed >= totalVestingDuration) {
            return 100;
        } else {
            console.log("timePassed >= schedule.cliffDuration");
            return
                schedule.TGEUnlockPercentage +
                ((timePassed - schedule.cliffDuration) * 100) /
                schedule.vestingDuration;
        }
    }

    //staking related functions

    function updateReward(uint256 scheduleIndex, address account) internal {
        VestingSchedule storage schedule = vestingSchedules[scheduleIndex];
        if (account != address(0)) {
            schedule.rewards[account] = earned(account, scheduleIndex);
            schedule.userRewardPerTokenPaid[account] = schedule
                .rewardPerTokenStored;
        }
    }
    //check the 1*1e18
    function depositRewards() public payable {
        require(msg.value > 0, "Amount should be greater than 0");
        uint256 scheduleLength = vestingSchedules.length;
        for (uint256 i = 0; i < scheduleLength; i++) {
            VestingSchedule storage schedule = vestingSchedules[i];
            schedule.totalRewardAmount += msg.value / scheduleLength;
            vestingSchedules[i].rewardPerTokenStored +=
                (msg.value * 1e18/ scheduleLength) /
                vestingSchedules[i].totalSupply;
        }
    }

    function earned(
        address account,
        uint256 scheduleIndex
    ) public view returns (uint256) {
        VestingSchedule storage schedule = vestingSchedules[scheduleIndex];
        return
            (schedule.balances[account] *
                (schedule.rewardPerTokenStored -
                    schedule.userRewardPerTokenPaid[account])) /
            1e18 +
            schedule.rewards[account];
    }

    function claimReward(uint256 scheduleIndex) public {
        VestingSchedule storage schedule = vestingSchedules[scheduleIndex];
        updateReward(scheduleIndex, msg.sender);
        uint256 reward = schedule.rewards[msg.sender];
        if (reward > 0) {
            schedule.rewards[msg.sender] = 0;
            payable(msg.sender).transfer(reward);
        }
    }

    //view functions
    function getVestingSchedule(
        uint256 scheduleIndex
    ) public view returns (string memory, uint256) {
        VestingSchedule storage schedule = vestingSchedules[scheduleIndex];
        return (schedule.name, schedule.totalSupply);
    }

    function getBalances(
        uint256 scheduleIndex,
        address account
    ) public view returns (uint256) {
        VestingSchedule storage schedule = vestingSchedules[scheduleIndex];
        return schedule.balances[account];
    }

    function getRewardPerToken(
        uint256 scheduleIndex
    ) public view returns (uint256) {
        VestingSchedule storage schedule = vestingSchedules[scheduleIndex];
        return schedule.rewardPerTokenStored;
    }

    function getUserRewardPerTokenPaid(
        uint256 scheduleIndex,
        address account
    ) public view returns (uint256) {
        VestingSchedule storage schedule = vestingSchedules[scheduleIndex];
        return schedule.userRewardPerTokenPaid[account];
    }

    function getTotalRewardAmount(
        uint256 scheduleIndex
    ) public view returns (uint256) {
        VestingSchedule storage schedule = vestingSchedules[scheduleIndex];
        return schedule.totalRewardAmount;
    }

    function getReward(
        uint256 scheduleIndex,
        address account
    ) public view returns (uint256) {
        VestingSchedule storage schedule = vestingSchedules[scheduleIndex];
        return schedule.rewards[account];
    }

    function getRewardPerTokenStored(
        uint256 scheduleIndex
    ) public view returns (uint256) {
        VestingSchedule storage schedule = vestingSchedules[scheduleIndex];
        return schedule.rewardPerTokenStored;
    }

    function getTGEUnlockPercentage(
        uint256 scheduleIndex
    ) public view returns (uint256) {
        VestingSchedule storage schedule = vestingSchedules[scheduleIndex];
        return schedule.TGEUnlockPercentage;
    }
}
