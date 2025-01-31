//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";

import {MyStableCoin} from "src/MyStableCoin.sol";

contract MyStableCoinTest is Test {

    MyStableCoin msc;

    function setup() public{
        msc = new MyStableCoin();
    }

    function totalSupplyTest() public view{
        assertEq(msc.totalSupply(), 100e18);
    }
}