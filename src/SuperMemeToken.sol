// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @custom:security-contact mertcan.mutlu@supermeme.com
contract SuperMemeToken is ERC20, ERC20Pausable, Ownable {

    address public seedWallet;
    address public privateSaleWallet;
    address public publicSaleWallet;
    address public teamWallet;
    address public marketingWallet;
    address public developmentWallet;
    address public liquidityWallet;
    address public advisorWallet;
    address public treasuryWallet;
    address public airdropWallet;

    uint256 public constant SEED_ALLOCATION = 90;
    uint256 public constant PRIVATE_SALE_ALLOCATION = 90;
    uint256 public constant PUBLIC_SALE_ALLOCATION = 90;
    uint256 public constant TEAM_ALLOCATION = 150;
    uint256 public constant MARKETING_ALLOCATION = 100;
    uint256 public constant DEVELOPMENT_ALLOCATION = 100;
    uint256 public constant LIQUIDITY_ALLOCATION = 90;
    uint256 public constant ADVISOR_ALLOCATION = 30;
    uint256 public constant TREASURY_ALLOCATION = 200;
    uint256 public constant AIRDROP_ALLOCATION = 30;

    uint256 public maximumCap = 1000000000 * 10 ** decimals();

    constructor(address initialOwner)
        ERC20("SuperMeme", "SPR")
        Ownable(initialOwner)

    {
        _mint(seedWallet, (maximumCap * SEED_ALLOCATION) / 1000);
        _mint(privateSaleWallet, (maximumCap * PRIVATE_SALE_ALLOCATION) / 1000);
        _mint(publicSaleWallet, (maximumCap * PUBLIC_SALE_ALLOCATION) / 1000);
        _mint(teamWallet, (maximumCap * TEAM_ALLOCATION) / 1000);
        _mint(marketingWallet, (maximumCap * MARKETING_ALLOCATION) / 1000);
        _mint(developmentWallet, (maximumCap * DEVELOPMENT_ALLOCATION) / 1000);
        _mint(liquidityWallet, (maximumCap * LIQUIDITY_ALLOCATION) / 1000);
        _mint(advisorWallet, (maximumCap * ADVISOR_ALLOCATION) / 1000);
        _mint(treasuryWallet, (maximumCap * TREASURY_ALLOCATION) / 1000);
        _mint(airdropWallet, (maximumCap * AIRDROP_ALLOCATION) / 1000);

    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // The following functions are overrides required by Solidity.

    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Pausable)
    {
        super._update(from, to, value);
    }

    function setWallets(
        address _seedWallet,
        address _privateSaleWallet,
        address _publicSaleWallet,
        address _teamWallet,
        address _marketingWallet,
        address _developmentWallet,
        address _liquidityWallet,
        address _advisorWallet,
        address _treasuryWallet,
        address _airdropWallet
    ) public onlyOwner {
        seedWallet = _seedWallet;
        privateSaleWallet = _privateSaleWallet;
        publicSaleWallet = _publicSaleWallet;
        teamWallet = _teamWallet;
        marketingWallet = _marketingWallet;
        developmentWallet = _developmentWallet;
        liquidityWallet = _liquidityWallet;
        advisorWallet = _advisorWallet;
        treasuryWallet = _treasuryWallet;
        airdropWallet = _airdropWallet;
    }


}
