// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FiveHoldings is ERC20, Ownable {

    // ================= TAXAS =================
    uint256 public buyTax = 0;
    uint256 public sellTax = 0;
    uint256 public constant MAX_TAX = 10;

    address public taxWallet;

    mapping(address => bool) public isExcludedFromTax;

    // ================= TRADING CONTROL =================
    bool public tradingEnabled = false;
    address public pancakePair;

    mapping(address => bool) public isExcludedFromLimits;

    // ================= CONSTRUTOR =================
    constructor(
        address _owner,
        address _pair,
        address _taxWallet
    ) ERC20("FiveHoldings", "FIVE") Ownable(_owner) {

        _mint(_owner, 100_000_000 * 10**decimals());

        pancakePair = _pair;
        taxWallet = _taxWallet;

        // exclusões iniciais
        isExcludedFromTax[_owner] = true;
        isExcludedFromTax[_taxWallet] = true;
        isExcludedFromTax[address(this)] = true;

        isExcludedFromLimits[_owner] = true;
        isExcludedFromLimits[_taxWallet] = true;
        isExcludedFromLimits[address(this)] = true;
    }

    // ================= ENABLE TRADING =================
    function enableTrading() external onlyOwner {
        tradingEnabled = true;
    }

    // ================= CONFIG =================
    function setTaxes(uint256 _buy, uint256 _sell) external onlyOwner {
        require(_buy <= MAX_TAX && _sell <= MAX_TAX, "Tax too high");
        buyTax = _buy;
        sellTax = _sell;
    }

    function excludeFromTax(address account, bool value) external onlyOwner {
        isExcludedFromTax[account] = value;
    }

    function excludeFromLimits(address account, bool value) external onlyOwner {
        isExcludedFromLimits[account] = value;
    }

    function setTaxWallet(address wallet) external onlyOwner {
        taxWallet = wallet;
    }

    function setPair(address pair) external onlyOwner {
        pancakePair = pair;
    }

 
function _update(address from, address to, uint256 amount) internal override {

   
    if (from == address(0) || to == address(0)) {
        super._update(from, to, amount);
        return;
    }

  
    if (!tradingEnabled) {
        require(
            isExcludedFromLimits[from] || isExcludedFromLimits[to],
            "Trading not enabled"
        );
    }

    uint256 finalAmount = amount;
    uint256 taxAmount = 0;

    // ===== TAXAS =====
    if (
        !isExcludedFromTax[from] &&
        !isExcludedFromTax[to]
    ) {
        // compra
        if (from == pancakePair && buyTax > 0) {
            taxAmount = (amount * buyTax) / 100;
        }
        // venda
        else if (to == pancakePair && sellTax > 0) {
            taxAmount = (amount * sellTax) / 100;
        }

        if (taxAmount > 0) {
            super._update(from, taxWallet, taxAmount);
            finalAmount -= taxAmount;
        }
    }

    super._update(from, to, finalAmount);
}
    // ================= BURN =================
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}
