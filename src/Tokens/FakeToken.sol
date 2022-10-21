// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

/*
 _________  ________  ___  __    _______   ________      
|\___   ___\\   __  \|\  \|\  \ |\  ___ \ |\   ___  \    
\|___ \  \_\ \  \|\  \ \  \/  /|\ \   __/|\ \  \\ \  \   
     \ \  \ \ \  \\\  \ \   ___  \ \  \_|/_\ \  \\ \  \  
      \ \  \ \ \  \\\  \ \  \\ \  \ \  \_|\ \ \  \\ \  \ 
       \ \__\ \ \_______\ \__\\ \__\ \_______\ \__\\ \__\
        \|__|  \|_______|\|__| \|__|\|_______|\|__| \|__|
                                                         
*/

contract FakeToken is ERC20Votes {
    // uint256 public s_maxSupply = 1000000000000000000000000;
    uint256 public s_maxSupply = 1000e18;

    constructor()
        ERC20("FakeToken", "FT")
        ERC20Permit("FakeToken")
    {
        _mint(msg.sender, s_maxSupply);
    }

    // The functions below are overrides required by Solidity.

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal override(ERC20Votes) {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20Votes)
    {
        super._burn(account, amount);
    }
}