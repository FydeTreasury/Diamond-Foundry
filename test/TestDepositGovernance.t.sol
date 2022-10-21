// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import {depositGovernance} from "./ContractStates.sol";


///@title This contract aim to test the params at deployment.
contract TestDepositGovernance is depositGovernance {
        
    /** 
    * @dev Basic staking works (1:1).
    */
    function testStakeToEarn() public {
        uint256 tsryBalanceUser1 = treasuryToken.balanceOf(user1);
        uint256 aaveBalancePool = aaveToken.balanceOf(address(tokenPool));
        assertEq(aaveBalancePool, tsryBalanceUser1);
        uint256 tsryBalanceUser2 = treasuryToken.balanceOf(user2);
        uint256 uniBalancePool = uniToken.balanceOf(address(tokenPool));
        assertEq(uniBalancePool, tsryBalanceUser2);
    }
     
}
