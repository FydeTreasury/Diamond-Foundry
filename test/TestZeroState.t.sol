// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import {ZeroState} from "./ContractStates.sol";
import "../src/interfaces/AggregatorV3Interface.sol";


///@title This contract aim to test the params at deployment.
contract TestZeroStateDeployment is ZeroState {
        
    /** 
    * @dev Roles have been correctly assigned.
    */
    function testGovernorRoles() public {
        assertTrue(governorTimelock.hasRole(governorTimelock.PROPOSER_ROLE(), address(governorContract)));
        assertTrue(governorTimelock.hasRole(governorTimelock.EXECUTOR_ROLE(), address(0)));
        assertTrue(!(governorTimelock.hasRole(governorTimelock.PROPOSER_ROLE(), deployer)));
    }

    /** 
    * @dev Token white list checking works.
    */
    function testTokenWhiteList() public {
        assertTrue(tokenPool.whiteListTokens(address(uniToken)));
        assertTrue(tokenPool.whiteListTokens(address(aaveToken)));
        assertTrue(!(tokenPool.whiteListTokens(address(fakeToken))));
    }

    /** 
    * @dev Token pricefeed works.
    */
    function testTokenToPriceFeed() public {
        address tokenToPriceFeed = tokenPool.tokenToPriceFeed(address(aaveToken));
        assertEq(tokenToPriceFeed, address(mockAavePriceFeed));
    }


    /** 
    * @dev Tsry value is correctly calculated using a range of values.
    */
    function testTreasuryValueTokenPool(uint104 tsryPrice, uint104 tsryAmount) public {
        vm.assume(tsryAmount > 0);
        vm.assume(tsryAmount < 10000000);
        vm.assume(tsryPrice > 0);
        vm.assume(tsryPrice < 10000);
        uint256 usdAmount = tokenPool.treasuryValue(tsryAmount, tsryPrice);
        assertTrue(usdAmount == (tsryAmount * (tsryPrice * 10**18)));
    }

    /** 
    * @dev Token Pool returns correct price for a given GT.
    */
    function testGetGTPriceTokenPool() public {
        // AggregatorV3Interface aaveOracle = AggregatorV3Interface(priceFeedAave);
        AggregatorV3Interface aaveOracle = AggregatorV3Interface(address(mockAavePriceFeed));
        (, int256 price,,,) = aaveOracle.latestRoundData();
        uint256 aavePrice = uint256(price)* 10**10;
        uint256 tokenPoolAavePrice = tokenPool.getGTPrice(address(aaveToken));
        assertEq(aavePrice, tokenPoolAavePrice);
    }

    /** 
    * @dev Seeing if the GT allowance is the expected value. 
    */
    function testGetUserGTAllowance(uint256 tsryAmount) public {
        vm.assume(tsryAmount > 1e18);
        vm.assume(tsryAmount < 50e18);
        uint tsryPrice = 10; // 10 dollars 
        uint gtAllowance = tokenPool.getUserGTAllowance(tsryAmount, address(aaveToken), tsryPrice);

        AggregatorV3Interface aaveOracle = AggregatorV3Interface(address(mockAavePriceFeed));
        (, int256 price,,,) = aaveOracle.latestRoundData();
        uint256 aavePrice = uint256(price)* 10**10; 
        // at the time of testing 1AAVE ~= 85$
        // amount of tsry = 100$
        // should get around 1.17 AAVE for 10TSRY
        uint tsryToDollars = (tsryAmount * (tsryPrice * 10**18));
        uint amountOfGt = tsryToDollars / aavePrice;
        assertEq(amountOfGt, gtAllowance);
    }

    /** 
    * @dev Reverting if USD amount of TSRY is too low. 
    */
    function testRevertTsryTooLow() public {
        // revert if trying to fund proxy with a low amount
        // avoids arithmetic errors / funding with 0 aave
        uint tsryAmount = 1e9; // 0.5 tsry
        uint tsryPrice = 1; // 1 dollar 
        vm.expectRevert(bytes("Please fund proxy with more than 1 dollars worth of TSRY"));
        tokenPool.getUserGTAllowance(tsryAmount,  address(aaveToken), tsryPrice);
    }

}