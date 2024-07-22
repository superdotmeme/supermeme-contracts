pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "forge-std/console.sol";
import "./Interfaces/IUniswapV2Router02.sol";
import "./Interfaces/IUniswapV2Pair.sol";
import "./Interfaces/IUniswapFactory.sol";
import "./Helpers/RevenueCollector.sol";

contract SuperMemeBondingCurve is ERC20 {
    uint256 public constant MAX_SALE_SUPPLY = 1e9; // 1 billion tokens
    uint256 public constant TOTAL_ETHER = 4 ether;
    uint256 public constant SCALE = 1e18; // Scaling factor
    uint256 public constant A = 234375; // Calculated constant A
    uint256 liquidityThreshold = 200_000_000 * 10 ** 18;
    uint256 public constant scaledLiquidityThreshold = 200_000_000;
    uint256 public constant buyPointScale = 10000;

    uint256 public scaledSupply;

    address public revenueCollector;
    uint256 public totalRevenueCollected;
    uint256 public contractBornTime;
    uint256 public totalRefundedTokens;
    uint256 public totalEtherCollected;

    uint256 public tradeTax = 1000;
    uint256 public tradeTaxDivisor = 100000;

    bool public bondingCurveCompleted;

    event SentToDex(uint256 ethAmount, uint256 tokenAmount, uint256 timestamp);

    event tokensBought(
        uint256 indexed amount,
        uint256 cost,
        address indexed _tokenAddress,
        address indexed _buyer
    );
    event tokensRefunded(
        uint256 indexed amount,
        uint256 refund,
        address indexed _tokenAddress,
        address indexed _seller
    );
    struct UserData {
        uint256 buyTime;
        uint256 buyAmount;
        uint256 paidEth;
        uint256 refundTime;
    }

    uint256 public buyCount;
    mapping (uint256 => address) public buyIndex;
    mapping (uint256 => uint256) public buyCost;
    mapping (uint256 => bool) public isRefund;
    mapping (uint256 => uint256) public cumulativeEthCollected;
    mapping (address => uint256[]) public userBuysPoints;
    mapping (address => uint256[]) public userBuyPointsEthPaid;
    mapping (address => uint256[]) public userBuyPointPercentages;
    mapping (address => uint256) public totalEthPaidUser;
    mapping (address => uint256) public userBalanceScaled;


    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _amount,
        address devAdress,
        address _revenueCollector
    ) public payable ERC20(_name, _symbol) {
        revenueCollector = _revenueCollector;
        contractBornTime = block.timestamp;
        _mint(address(this), liquidityThreshold);
        scaledSupply = scaledLiquidityThreshold;
    }
    function buyTokens(uint256 _amount) external payable {
        uint256 cost = calculateCost(_amount);
        uint256 tax = (cost * tradeTax) / tradeTaxDivisor;
        require(
            scaledSupply + _amount <= MAX_SALE_SUPPLY,
            "Exceeds maximum supply"
        );
        require(msg.value >= cost + tax, "Insufficient Ether sent");
        payTax(tax);

        buyIndex[buyCount] = msg.sender;
        buyCost[buyCount] = cost;
        userBuysPoints[msg.sender].push(buyCount);
        userBuyPointsEthPaid[msg.sender].push(msg.value - tax);
        buyCount += 1;

        totalEthPaidUser[msg.sender] += msg.value - tax;
        totalEtherCollected += msg.value - tax;
        cumulativeEthCollected[buyCount] += msg.value - tax;
        console.log("before calculateUserBuyPointPercentages");
        calculateUserBuyPointPercentages();

        scaledSupply += _amount;
        _mint(msg.sender, _amount * 10 ** 18);
        userBalanceScaled[msg.sender] += _amount;
  
        emit tokensBought(_amount, cost, address(this), msg.sender);
    }
    function calculateUserBuyPointPercentages() internal {
        uint256[] memory userBuyPoints = userBuysPoints[msg.sender];
        for (uint256 i = 0; i < userBuyPoints.length; i++) {
            uint256 buyPoint = userBuyPoints[i];
            uint256 cost = buyCost[buyPoint];
            uint256 percentage = cost * buyPointScale / totalEthPaidUser[msg.sender];
            userBuyPointPercentages[msg.sender].push(percentage);
        }
    }
    function refund() public {
        require(
            bondingCurveCompleted == false,
            "Bonding curve completed, no refunds allowed"
        );

        (uint256 toTheCurve,uint256 toBeDistributed) = calculateTokensRefund();
 
        require(
            balanceOf(msg.sender) >= (toTheCurve + toBeDistributed),
            "Insufficient token balance"
        );
        uint256 amountToBeRefundedEth = totalEthPaidUser[msg.sender];
        require(
            address(this).balance >= amountToBeRefundedEth ,
            "Insufficient Ether in contract"
        );
        payTax(amountToBeRefundedEth * tradeTax / tradeTaxDivisor);
        _burn(msg.sender, toTheCurve);
        _transfer(msg.sender, address(this), toBeDistributed);
        uint256[] memory userBuyPoints = userBuysPoints[msg.sender];
        for (uint256 i = 0; i < userBuyPoints.length; i++) {
            uint256 buyPoint = userBuyPoints[i];
            uint256 ethPaidByOtherUsersInBetween = cumulativeEthCollected[buyCount] - cumulativeEthCollected[buyPoint];
            for (uint256 j = buyCount -1;j >= buyPoint; j--) {
                if(buyIndex[j] == address(0)) {
                    break;
                } else if (j == buyPoint) {
                    break;
                } else if (buyIndex[j] == msg.sender) {
                    continue;
                } else {
                    uint256 refundAmountForInstance = userBuyPointPercentages[msg.sender][i] * toBeDistributed / buyPointScale;
                    uint256 refundAmountForUser = buyCost[j] * refundAmountForInstance / ethPaidByOtherUsersInBetween;
                    _transfer(address(this), buyIndex[j], refundAmountForUser);
                }
            }
        }

        //transfer the remaining eth to the user
        payable(msg.sender).transfer(amountToBeRefundedEth - amountToBeRefundedEth * tradeTax / tradeTaxDivisor);
    }
    function payTax(uint256 _tax) internal {
        payable(revenueCollector).transfer(_tax);
        totalRevenueCollected += _tax;
    }

        function calculateCost(uint256 amount) public view returns (uint256) {
        uint256 currentSupply = scaledSupply;
        uint256 newSupply = currentSupply + amount;
        uint256 cost = ((((A * ((newSupply ** 3) - (currentSupply ** 3))) *
            10 ** 5) / (3 * SCALE)) * 40000) / 77500;
        // console.log("Cost inside the contract: ", cost);
        return cost;
    }
    function calculateTokensRefund()
        public view returns (uint256, uint256) {
        uint256 userBalance = userBalanceScaled[msg.sender];
        uint256 currentSupply = scaledSupply;
        uint256 totalEthPaidUserVar = totalEthPaidUser[msg.sender];
        uint256 supplyDifference = (totalEthPaidUserVar * 77500 * 3 * SCALE) /
            (40000 * A * 10 ** 5);
        uint256 newSupplyCubed = currentSupply ** 3 - supplyDifference;
        uint256 newSupply = cubeRoot(newSupplyCubed);
        uint256 _amount = currentSupply - newSupply;
        uint256 amountToBeRedistributed = userBalance - _amount;
        return (_amount * 10 ** 18, amountToBeRedistributed * 10 ** 18);
    }
    function cubeRoot(uint256 x) internal pure returns (uint256) {
        uint256 z = (x + 1) / 3;
        uint256 y = x;
        while (z < y) {
            y = z;      
            z = (x / (z * z) + 2 * z) / 3;
        }
        return y;
    }


}
