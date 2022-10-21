// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/*
 _________  ________  ___  __    _______   ________      
|\___   ___\\   __  \|\  \|\  \ |\  ___ \ |\   ___  \    
\|___ \  \_\ \  \|\  \ \  \/  /|\ \   __/|\ \  \\ \  \   
     \ \  \ \ \  \\\  \ \   ___  \ \  \_|/_\ \  \\ \  \  
      \ \  \ \ \  \\\  \ \  \\ \  \ \  \_|\ \ \  \\ \  \ 
       \ \__\ \ \_______\ \__\\ \__\ \_______\ \__\\ \__\
        \|__|  \|_______|\|__| \|__|\|_______|\|__| \|__|
                                                         
*/

contract TreasuryToken is ERC20 {

    uint256 public s_maxSupply = 100000e18;

    constructor() ERC20("Treasury", "TSRY") {
        _mint(msg.sender, s_maxSupply);
    }
}