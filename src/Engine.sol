//SPDX-Liensce-Identifier: MIT
pragma solidity ^0.8.24;

import {MyStableCoin} from "../src/MyStableCoin.sol";

/**
 * @title Engine
 * @author MaxBu
 * @notice 
 */
contract Engine {
    MyStableCoin msc;

    constructor() {
        msc = new MyStableCoin();
    }

    
}