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

    uint256 public scaledSupply;

    address public revenueCollector;
    uint256 public totalRevenueCollected;
    uint256 public contractBornTime;
    uint256 public totalRefundedTokens;
    uint256 public totalEtherCollected;

    uint256 public tradeTax = 1000;
    uint256 public tradeTaxDivisor = 100000;

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

    mapping(address => UserData) public userData;

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

    function calculateCost(uint256 amount) public view returns (uint256) {
        uint256 currentSupply = scaledSupply;
        uint256 newSupply = currentSupply + amount;
        uint256 cost = ((((A * ((newSupply ** 3) - (currentSupply ** 3))) *
            10 ** 5) / (3 * SCALE)) * 40000) / 77500;
        // console.log("Cost inside the contract: ", cost);
        return cost;
    }

    function calculateRefund(uint256 _amount) public view returns (uint256) {
        uint256 currentSupply = scaledSupply;
        uint256 newSupply = currentSupply - _amount;
        uint256 refund = ((((A * ((currentSupply ** 3) - (newSupply ** 3))) *
            10 ** 5) / (3 * SCALE)) * 40000) / 77500;
        return refund;
    }

    function calculateTokensRefund(
        uint256 _refund
    ) public view returns (uint256) {
        uint256 currentSupply = scaledSupply;
        uint256 supplyDifference = (_refund * 77500 * 3 * SCALE) /
            (40000 * A * 10 ** 5);
        uint256 newSupplyCubed = currentSupply ** 3 - supplyDifference;
        uint256 newSupply = cubeRoot(newSupplyCubed);
        uint256 _amount = currentSupply - newSupply;
        console.log("Refunding %s amount of tokens to the curve for %s eth at total supply", _amount , _refund, currentSupply);
        console.log("Amount of tokens to be redistrubted", balanceOf(address(msg.sender)) / 10 **18 - _amount);
        return _amount;
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

    function buyTokens(uint256 _amount) external payable {
        uint256 cost = calculateCost(_amount);
        uint256 tax = (cost * tradeTax) / tradeTaxDivisor;
        require(
            scaledSupply + _amount <= MAX_SALE_SUPPLY,
            "Exceeds maximum supply"
        );
        require(msg.value >= cost + tax, "Insufficient Ether sent");
        
        payTax(tax);
        totalEtherCollected += msg.value - tax;
        scaledSupply += _amount;
        _mint(msg.sender, _amount * 10 ** 18);

        emit tokensBought(_amount, cost, address(this), msg.sender);
    }
    function payTax(uint256 _tax) internal {
        payable(revenueCollector).transfer(_tax);
        totalRevenueCollected += _tax;
    }
    mapping (address => uint256) public shitshow;
    function updateBalance() public {
        for (uint256 i = 0; i < 10000; i++) {
        shitshow[msg.sender] +=1;
        }
    }
    
}
