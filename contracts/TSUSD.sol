// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TimeStarterUSD is ERC20 {
    constructor() ERC20("TimeStarter Stable", "TSUSD") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}