pragma solidity ^0.8.20;

import "./DegenBondingCurveOne.sol";

contract SuperMemeFactory {

    uint256 public createTokenRevenue = 0.0003 ether;
    address public revenueCollector;
    address[] public tokenAddresses;

    constructor(address _revenueCollector) {
        revenueCollector = _revenueCollector;
    }

    function createToken(bool _devLocked, uint256 _amount) public payable returns (address){
        require(msg.value >= createTokenRevenue, "Insufficient funds");
        address devAddress = msg.sender;
        address newToken;
        if (_devLocked){
             newToken = address(new DegenBondingCurveOne(_devLocked, _amount, devAddress, revenueCollector));
            payable(revenueCollector).transfer(createTokenRevenue);
            payable(newToken).transfer(msg.value);
        }
        else {
             newToken =  address(new DegenBondingCurveOne(_devLocked, _amount, devAddress, revenueCollector));
            payable(revenueCollector).transfer(createTokenRevenue);
        }
        tokenAddresses.push(address(newToken));
        return newToken;
    }
    function getTokens() public view returns (address[] memory) {
        return tokenAddresses;
    }
}