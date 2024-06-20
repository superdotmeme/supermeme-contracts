pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "forge-std/console.sol";
import "./Interfaces/IUniswapV2Router02.sol";
import "./Interfaces/IUniswapV2Pair.sol";

contract DegenBondingCurveOne is ERC20 {
    uint256 public constant MAX_SALE_SUPPLY = 1e9; // 1 billion tokens
    uint256 public constant TOTAL_ETHER = 4 ether;
    uint256 public constant SCALE = 1e18; // Scaling factor
    uint256 public constant A = 234375; // Calculated constant A
    uint256 liquidityThreshold = 200_000_000 * 10 ** 18;
    uint256 public constant scaledLiquidityThreshold = 200_000_000;

    uint256 public totalEtherCollected;
    uint256 public scaledSupply;


    uint256 public denseVolumeAvgTime;
    uint256 public totalRefundedTokens;

    uint256 public contractLifeSpan;
    uint256 public contractBornTime;

    bool public bondingCurveCompleted;
    address public devAddress;
    bool public devLocked;

    uint256 tradeTax = 1000;        
    uint256 tradeTaxDivisor = 100000;

    address public revenueCollector;
    uint256 public totalRevenueCollected;
    uint256 public sendDexRevenue = 0.15 ether;
    uint256 public createTokenRevenue = 0.00028 ether;

    IUniswapV2Router02 public uniswapV2Router;
    IUniswapV2Pair public uniswapV2Pair;

    constructor(bool _devLocked, uint256 _amount, address devAdress, address _revenueCollector) ERC20("BasicBondingCurve", "BBC") public payable {

        revenueCollector = _revenueCollector;
        contractBornTime = block.timestamp;
        contractLifeSpan = 1 weeks;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x5633464856F58Dfa9a358AfAf49841FEE990e30b
        );
        uniswapV2Router = _uniswapV2Router;
        _mint(address(this), liquidityThreshold);
        scaledSupply = scaledLiquidityThreshold;

        if (devLocked) {
            devLock(_amount);
        }
        devLocked = devLocked;
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


    function devLock(uint256 _amount) internal  {
        require(_amount > 0, "Amount must be greater than 0");
        require(_amount <= 100000000, "Amount must be less than 100,000,000");
        require(devLocked == true, "Dev has not locked");
        totalEtherCollected += msg.value;
        scaledSupply += _amount;
        _mint(devAddress, _amount * 10 ** 18);
    }


    function buyTokens(uint256 _amount) external payable {
        require(
            bondingCurveCompleted == false,
            "Bonding curve completed, no more tokens can be bought"
        );
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

        if (scaledSupply >= MAX_SALE_SUPPLY) {
            bondingCurveCompleted = true;
        }
    }

    function sellTokens(uint256 _amount) external {
        require(
            bondingCurveCompleted == false,
            "Bonding curve completed, no refunds allowed"
        );
        uint256 refund = calculateRefund(_amount);
        uint256 tax = (refund * tradeTax ) / tradeTaxDivisor;
        require(
            address(this).balance >= refund,
            "Insufficient Ether in contract"
        );
        require(
            balanceOf(msg.sender) >= _amount * 10 ** 18,
            "Insufficient token balance"
        );
        payTax(tax);
        _burn(msg.sender, _amount * 10 ** 18);
        totalEtherCollected -= refund ;
        scaledSupply -= _amount;
        payable(msg.sender).transfer(refund - tax );

    }

    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20) {
        if (bondingCurveCompleted) {
            super._update(from, to, value);
        } else {
            if (from == devAddress && devLocked) {
                revert("Dev tokens are locked");
            } else if (from == address(this) || from == address(0)) {
                super._update(from, to, value);
            } else if (to == address(this) || to == address(0)) {
                super._update(from, to, value);
            } else {
                revert("Bonding curve not completed, no transfers allowed");
            }
        }
    }

    function sendToDex() public payable {
        require(bondingCurveCompleted, "Bonding curve not completed");
        payTax(sendDexRevenue);
        totalEtherCollected -= sendDexRevenue;
        uint256 _ethAmount = totalEtherCollected;
        uint256 _tokenAmount = liquidityThreshold;
        _approve(address(this), address(uniswapV2Router), _tokenAmount);
        uniswapV2Router.addLiquidityETH{value: _ethAmount}(
            address(this),
            _tokenAmount,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    function payTax(uint256 _tax) internal {
        payable(revenueCollector).transfer(_tax);
        totalRevenueCollected += _tax;
    }





    receive() external payable {}
}
