//SPDX-Lincese-Identifier: MIT

pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {Engine} from "src/Engine.sol";
import {Deploy} from "script/Deploy.s.sol";
import {ConfigHelper} from "script/ConfigHelper.s.sol";

contract EngineTest is Test {

    Engine engine;
    ConfigHelper configHelper;

    function setup() public {
        //FIRST: deploy the Engine contract
        Deploy deploy = new Deploy();
        (engine, configHelper) = deploy.run();
    }

}