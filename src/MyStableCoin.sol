//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20, ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MyStableCoin
 * @author MaxBu
 */
contract MyStableCoin is ERC20, ERC20Burnable, Ownable{
    error MyStableCoin__MustBeMoreThanZero();
    error MyStableCoin__canNotMintToAddressZero();

    constructor() ERC20("MyStableCoin", "MSC") Ownable(msg.sender){}

    function burn(uint256 amount) public override onlyOwner{
        super.burn(amount);
    }

    function mint(address to, uint256 amount) public onlyOwner{
        if(to == address(0)){
            revert MyStableCoin__canNotMintToAddressZero();
        }

        if (amount <= 0) {
            revert MyStableCoin__MustBeMoreThanZero();
        }
        _mint(to, amount);
    }
}