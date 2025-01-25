//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyStableCoin is ERC20{

    uint256 public constant INITIAL_SUPPLY = 100e18;

    constructor() ERC20("MyStableCoin", "MSC"){}

    function totalSupply() public pure override returns (uint256) {
        return INITIAL_SUPPLY;
    }
}