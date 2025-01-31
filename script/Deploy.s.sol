//SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {Engine} from "src/Engine.sol";
import {MyStableCoin} from "src/MyStableCoin.sol";
import {ConfigHelper} from "./ConfigHelper.s.sol";

contract Deploy is Script{
    // address public engine;


    function run() external returns (Engine, ConfigHelper) {
        ConfigHelper configHelper = new ConfigHelper();
        (address wETH, address wBTC, address ETHUSDFeed, address BTCUSDFeed) = configHelper.activeNetConfig();
        address[] memory tokens = [wETH, wBTC];
        address[] memory feeds = [ETHUSDFeed, BTCUSDFeed];
        MyStableCoin msc = new MyStableCoin();
        Engine engine = new Engine(tokens, feeds, address(msc));
        return (engine, configHelper);
    }
}