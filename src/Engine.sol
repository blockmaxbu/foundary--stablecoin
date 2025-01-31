//SPDX-Liensce-Identifier: MIT
pragma solidity ^0.8.24;

// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

import { OracleLib, AggregatorV3Interface } from "./libraries/OracleLib.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { MyStableCoin } from "../src/MyStableCoin.sol";
import { ConfigHelper } from "../script/ConfigHelper.s.sol";

/**
 * @title Engine
 * @author MaxBu
 * @notice uses Chainlink Price Feeds to get the price of the collateral,So we can peg the stablecoin to the collateral
 */
contract Engine {

    error Engine__DespositTansferFailed();
    error Engine__withDrawTansferFailed();
    error Engine__withdrawNotEnoughCollateral();
    error Engine__collateralTypeNotSupport();

    event Engine_user_despoit(address indexed user, uint256 amount, address collateral);
    event Engine_user_withdraw(address indexed user, uint256 amount, address collateral);

    using OracleLib for AggregatorV3Interface;

    /**
     * @dev we will support multiple collaterals, so we should use a mapping/array to store the collaterals
     * otherwise it will be hard to test the code since every collateral has different variables 
     
    address private immutable i_wETH;
    address private immutable i_wBTC;
    address private immutable i_ETHUSDFeed;
    address private immutable i_BTCUSDFeed;
    */
    mapping (address collateralToken => address priceFeed) s_priceFeeds;
    address[] private s_collateralTokens;

    uint256 constant DEC = 10e18;

    mapping (address user => mapping ( address s_collateral => uint256 amount)) s_collaterals;
    mapping (address => uint256) s_mints;
    
    //rate will decide when you put $1 worth of ETH, how much stablecoin you will get
    //for example: if you put $1 worth of ETH and the rate is 0.5, you will get 0.5 stablecoin
    //but bsolidity does not support floating point numbers, so we need to use a large number to represent the rate, for example: 0.5 * 10^18 = 500000000000000000
    uint256 private rate = 5 * 10**17; 

    MyStableCoin private immutable i_msc;

    constructor(address[] memory _collateralTokens, address[] memory _priceFeeds, address _msc) {
        i_msc = MyStableCoin(_msc);
        
    }

    /**
     * @notice desposit wETH/wBTC to the contract
     * @notice _amount use wei as the unit, so it will not match the price.
     */
    function desposit(address collateral, uint256 _amount) external {
        //first: we need to check if the user has enough wETH
        //if the user dont have enough wETH the folowing function revert the transaction
        _desposit(collateral, _amount);
        s_collaterals[msg.sender][collateral] += _amount;

        //second:we need to get the price of the wETH by using the Chainlink Price Feeds
        uint256 currentPrice = getPrice(collateral);

        //third: we need to cauculate the amount of the stablecoin that the user will get
        uint256 amountOfStableCoin = _amount * currentPrice * rate / DEC;

        //fourth: we need to mint the stablecoin to the user
        i_msc.mint(msg.sender, amountOfStableCoin);
        s_mints[msg.sender] += amountOfStableCoin;
        emit Engine_user_despoit(msg.sender, _amount, collateral);
    }

    /**
     * @param collateral the address of the collateral
     * @param _amount the amount of the stablecoin user wants to withdraw, using wei as the unit
     * @notice use revert instead of return false
     */
    function withdraw(address collateral, uint256 _amount) external {
        //first: check if the user has enough collateral to withdraw
        uint256 totalCollateralValue = getTotalCollateralValue(msg.sender);
        if((totalCollateralValue - s_mints[msg.sender]) / totalCollateralValue < rate / DEC){
            revert Engine__withdrawNotEnoughCollateral();
        }

        //second: check if the user has enough collateral with this certain type
        if(getValue(collateral, s_collaterals[msg.sender][collateral]) < _amount){
            revert Engine__withdrawNotEnoughCollateral();
        }

        //third: withdraw the collateral
        uint256 currentPrice = getPrice(collateral);
        uint256 collateralAmount = _amount / currentPrice;
        _withdraw(collateral, collateralAmount);

        s_mints[msg.sender] -= _amount;
        emit Engine_user_withdraw(msg.sender, _amount, collateral);
    }

    /**
     * @param collateral the adress of the collateral
     * @return the price of the collateral by using the Chainlink Price Feedsq
     */
    function getPrice(address collateral) private view returns(uint256){
        address priceFeedAddress = s_priceFeeds[collateral];
        if(priceFeedAddress == address(0)){
            revert Engine__collateralTypeNotSupport();
        }
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddress);
        (, int256 price,,,) = priceFeed.getDataFeedLatestAnswer();
        
        return uint256(price);
    }

    /**
     * @param user the address which you want to get the total value of the collateral
     * @notice get the total value of the collateral that the user has
     */
    function getTotalCollateralValue(address user) public view returns(uint256){
        uint256 ethAmount = s_collaterals[user][TypeOfCollateral.wETH];
        uint256 btcAmount = s_collaterals[user][TypeOfCollateral.wBTC];
        
        uint256 ethValue = getValue(TypeOfCollateral.wETH, ethAmount);
        uint256 btcValue = getValue(TypeOfCollateral.wBTC, btcAmount);
        return ethValue + btcValue;
    }

    /**
     * @param collateral the address of the collateral
     * @param _amount the amount of the collateral user wants to get the value
     */
    function getValue(address collateral, uint256 _amount) public view returns(uint256){
        uint256 currentPrice = getPrice(collateral);
        return _amount * currentPrice;
    }

    function _desposit(address collateral, uint256 _amount) private {
        
        bool success = IERC20(collateral).transferFrom(msg.sender, address(this), _amount);
        if(!success){
            revert Engine__DespositTansferFailed();
        }

    }

    /**
     * @notice withdraw the wETH from the contract
     */
    function _withdraw(address collateral, uint256 _amount) private {

        bool success = IERC20(collateral).transfer(msg.sender, _amount);
        if(!success){
            revert Engine__withDrawTansferFailed();
        }
    }

    


    
}