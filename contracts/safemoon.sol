
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./uniswapContracts/IUniswapV2Router01.sol";
import "./uniswapContracts/IUniswapV2Router02.sol";


contract MMMToken is ERC20 {
    //uint public initialSupply = 10000000;
    using SafeMath for uint;
    IUniswapV2Router02  _uniswapRouter = IUniswapV2Router02 (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
   
    uint public _liquidityFee = 5;
    uint public _BurnFee = 5;
    
    address owner;
    
    constructor() ERC20("MoonMeem", "MMM") {
       
        _mint(msg.sender, 100000000);
        owner = msg.sender;
         
 
    }
    function _transfertoken( address receipent, uint amount)  public{
       
        uint liquidityFee = amount.mul(_liquidityFee)/100;
        uint BurnFee = amount.mul(_BurnFee)/100;
        _burn(msg.sender, BurnFee);
         _transfer(msg.sender, address(this), liquidityFee);
         uint contractTokenBalance = address(this).balance;
        //adding  liquidity
        swapAndLiquify(contractTokenBalance);
        _transfer(msg.sender, receipent, amount.sub(liquidityFee).sub(BurnFee));

    }
    function CalculatetotalFee(uint amount) public view returns(uint){
        uint totalFee = amount.mul(_liquidityFee)/100 + amount.mul(_BurnFee)/100;
        return  (totalFee);
    }
    receive() external payable {}
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve the token to tranfeer
         _approve(address(this), address(_uniswapRouter), tokenAmount);

        // add the liquidity
         _uniswapRouter.addLiquidityETH{value: ethAmount}(
                address(this),
                tokenAmount,
                0, 
                0, 
                owner,
                block.timestamp
        );
    }
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapRouter.WETH();

        _approve(address(this), address(_uniswapRouter), tokenAmount);

        
        _uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp
        );
    }
    function swapAndLiquify(uint256 contractTokenBalance) private  {
        
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

       
        uint256 initialBalance = address(this).balance;

        // out of all th tokens in the contract half is converveted to eth to fund the pair token
        swapTokensForEth(half); 

        //This gives us the total eth swaped 
        uint256 newBalance = address(this).balance.sub(initialBalance);

        //this adds the liquidity to the uniswap
        addLiquidity(otherHalf, newBalance);
    }
}