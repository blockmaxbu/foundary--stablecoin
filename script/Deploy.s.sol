//SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {Engine} from "../src/Engine.sol";
import {ConfigHelper} from "./ConfigHelper.s.sol";

contract Deploy is Script{
    // address public engine;


    function run() external returns (Engine, ConfigHelper.NetConfig memory) {
        ConfigHelper configHelper = new ConfigHelper();
        ConfigHelper.NetConfig memory config = configHelper.activeNetConfig;
        Engine engine = new Engine(config);
        return (engine, config);
    }
}