//SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {Engine} from "../src/Engine.sol";
import {ConfigHelper} from "./ConfigHelper.s.sol";

contract Deploy is Script{
    address public engine;

    constructor() {
    }

    function run() external view returns (Engine, NetConfig memory) {
        ConfigHelper configHelper = new ConfigHelper();
        NetConfig calldata config = configHelper.activeNetConfig;
        engine = new Engine(config);
        return (engine, config);
    }
}