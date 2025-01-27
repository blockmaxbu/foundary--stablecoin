//SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";

import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

/**
 * @title ConfigHelper
 * @author MaxBu
 * @notice This contract is used to help the user to set the configuration of the Engine contract,
 *  it will return different config with the different blockchain id 
 */

contract ConfigHelper is Script {

    struct NetConfig {
        address wETH;
        address wBTC;
        address ETHUSDFeed;
        address BTCUSDFeed;
    }

    NetConfig public activeNetConfig;
    uint8 public constant DECIMALS = 8;
    int256 public constant ETH_PRICE = 3000e8;
    int256 public constant BTC_PRICE = 100000e8;


    constructor() {
        if(block.chainid == 1) {
            //mainnet
            activeNetConfig = getMainetEthConfig();
        } else if(block.chainid == 111551110) {
            //testnet
            activeNetConfig = getTestnestEthConfig();
        } else {
            //anvil
            activeNetConfig = getAnvilConfig();
        }
    }

    function getMainetEthConfig() public view returns (NetConfig memory) {
        return NetConfig({
            wETH: address(0),
            wBTC: address(1),
            ETHUSDFeed: address(2),
            BTCUSDFeed: address(3)
        });
    }

    /**
     * @notice we will use https://dashboard.tenderly.co/ to deploy the contract to the testnet
     */
    function getTestnestEthConfig() public pure returns (NetConfig memory) {
        return NetConfig({
            wETH: address(0),
            wBTC: address(1),
            ETHUSDFeed: address(2),
            BTCUSDFeed: address(3)
        });
    }

    function getAnvilConfig() public returns (NetConfig memory) {
        if(activeNetConfig.ETHUSDFeed != address(0)) {
            return activeNetConfig;
        }

        //wo need to mock the eth and btc price feed
        //and mock wrapped token for both btc and eth
        vm.startBroadcast();
        MockV3Aggregator ethFeed = new MockV3Aggregator(DECIMALS, ETH_PRICE);
        ERC20Mock wEthMock = new ERC20Mock();

        MockV3Aggregator btcFeed = new MockV3Aggregator(DECIMALS, BTC_PRICE);
        ERC20Mock wBtcMock = new ERC20Mock();
        vm.stopBroadcast();

        return NetConfig({
            wETH: address(wEthMock),
            wBTC: address(wBtcMock),
            ETHUSDFeed: address(ethFeed),
            BTCUSDFeed: address(btcFeed)
        });


    }
}