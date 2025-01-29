//SPDX-Liensce-Identifier: MIT
pragma solidity ^0.8.24;


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

    event Engine_user_despoit(address indexed user, uint256 amount, TypeOfCollateral collateralType);
    event Engine_user_withdraw(address indexed user, uint256 amount, TypeOfCollateral collateralType);

    enum TypeOfCollateral {
        wETH,
        wBTC
    }
    
    using OracleLib for AggregatorV3Interface;

    address private immutable i_wETH;
    address private immutable i_wBTC;

    uint256 constant DEC = 10e18;

    mapping (address => mapping ( TypeOfCollateral => uint256 amount)) s_collaterals;
    mapping (address => uint256) s_mints;
    
    //rate will decide when you put $1 worth of ETH, how much stablecoin you will get
    //for example: if you put $1 worth of ETH and the rate is 0.5, you will get 0.5 stablecoin
    //but bsolidity does not support floating point numbers, so we need to use a large number to represent the rate, for example: 0.5 * 10^18 = 500000000000000000
    uint256 private rate = 5 * 10**17; 

    MyStableCoin immutable msc;

    constructor(ConfigHelper.NetConfig memory config) {
        msc = new MyStableCoin();
        i_wETH = config.wETH;
        i_wBTC = config.wBTC;
    }

    /**
     * @notice desposit wETH/wBTC to the contract
     * @notice _amount use wei as the unit, so it will not match the price.
     */
    function desposit(TypeOfCollateral collateralType, uint256 _amount) external {
        //first: we need to check if the user has enough wETH
        //if the user dont have enough wETH the folowing function revert the transaction
        _desposit(collateralType, _amount);
        s_collaterals[msg.sender][collateralType] += _amount;

        //second:we need to get the price of the wETH by using the Chainlink Price Feeds
        uint256 currentPrice = getPrice(collateralType);

        //third: we need to cauculate the amount of the stablecoin that the user will get
        uint256 amountOfStableCoin = _amount * currentPrice * rate / DEC;

        //fourth: we need to mint the stablecoin to the user
        msc.mint(msg.sender, amountOfStableCoin);
        s_mints[msg.sender] += amountOfStableCoin;
        emit Engine_user_despoit(msg.sender, _amount, collateralType);
    }

    /**
     * @param collateralType the type of the collateral
     * @param _amount the amount of the stablecoin user wants to withdraw, using wei as the unit
     * @notice use revert instead of return false
     */
    function withdraw(TypeOfCollateral collateralType, uint256 _amount) external {
        //first: check if the user has enough collateral to withdraw
        uint256 totalCollateralValue = getTotalCollateralValue(msg.sender);
        if((totalCollateralValue - s_mints[msg.sender]) / totalCollateralValue < rate / DEC){
            revert Engine__withdrawNotEnoughCollateral();
        }

        //second: check if the user has enough collateral with this certain type
        if(getValue(collateralType, s_collaterals[msg.sender][collateralType]) < _amount){
            revert Engine__withdrawNotEnoughCollateral();
        }

        //third: withdraw the collateral
        uint256 currentPrice = getPrice(collateralType);
        uint256 collateralAmount = _amount / currentPrice;
        _withdraw(collateralType, collateralAmount);

        s_mints[msg.sender] -= _amount;
        emit Engine_user_withdraw(msg.sender, _amount, collateralType);
    }

    /**
     * @param collateralType the type of the collateral
     * @return the price of the collateral by using the Chainlink Price Feedsq
     */
    function getPrice(TypeOfCollateral collateralType) private pure returns(uint256){
        uint256 price;
        if(collateralType == TypeOfCollateral.wETH){
            price = 3000;
        }else if(collateralType == TypeOfCollateral.wBTC){
            price = 100000;
        }
        return price;
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
     * @param collateralType the type of the collateral
     * @param _amount the amount of the collateral user wants to get the value
     */
    function getValue(TypeOfCollateral collateralType, uint256 _amount) public pure returns(uint256){
        uint256 currentPrice = getPrice(collateralType);
        return _amount * currentPrice;
    }

    function _desposit(TypeOfCollateral collateralType, uint256 _amount) private {
        address collateralAddress;
        if(collateralType == TypeOfCollateral.wETH){
            collateralAddress = i_wETH;
        }else if(collateralType == TypeOfCollateral.wBTC){
            collateralAddress = i_wBTC;
        }
        bool success = IERC20(collateralAddress).transferFrom(msg.sender, address(this), _amount);
        if(!success){
            revert Engine__DespositTansferFailed();
        }

    }

    /**
     * @notice withdraw the wETH from the contract
     */
    function _withdraw(TypeOfCollateral collateralType, uint256 _amount) private {

        address collateralAddress;
        if(collateralType == TypeOfCollateral.wETH){
            collateralAddress = i_wETH;
        }else if(collateralType == TypeOfCollateral.wBTC){
            collateralAddress = i_wBTC;
        }
        bool success = IERC20(collateralAddress).transfer(msg.sender, _amount);
        if(!success){
            revert Engine__withDrawTansferFailed();
        }
    }

    


    
}