// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import {IndicateVoteState} from "./ContractStates.sol";
import "../src/interfaces/ITokenPool.sol";
import "../src/TokenPool.sol";
import "../src/Proxies/VoteProxyRegistry.sol";
import "../src/Proxies/VoteProxyFactory.sol";


///@title This contract aims to test the params at when a proposal is pending and user indicates 
/// they want to vote.

contract TestIndicateVote is IndicateVoteState {
     

    /// -----------------------------
    ///           Globals
    /// -----------------------------

    address public randomUser1 = vm.addr(10);
    uint256 public tsryPrice = 10; // worth 10$
    

    /// =======================================
    ///     Vote Proxy Factory and Registry
    /// =======================================

    /** 
    * @dev Only one whitelisted tokens can have proxies
    */
    function testNotWhiteListed() public {
        vm.prank(user1);
        vm.expectRevert(bytes("Token is not whitelisted"));
        voteProxyFactory.createERC20VotesProxy(
            address(fakeToken),
            address(tokenPool),
            false
        );

    }


    /** 
    * @dev Only one proxy can be made token/user
    */
    function testOnlyOneProxy() public {
        vm.startPrank(user1);
        // can create a proxy with another token
        voteProxyFactory.createERC20VotesProxy(
            address(uniToken),
            address(tokenPool),
            true
        );
        
        vm.expectRevert(bytes("User already has proxy associated with this token"));
        // already has proxy for aave so should revert
        voteProxyFactory.createERC20VotesProxy(
            address(aaveToken),
            address(tokenPool),
            false
        );
        vm.stopPrank();
    }



    /// =======================================
    ///              Token Pool
    /// =======================================

        /** 
    * @dev Only valid proxies can call the fundProxy function
    */
    function testOnlyFundTokenPool() public {
        vm.prank(randomUser1);
        // contract not made via the factory and is therefore invalid
        VoteProxyERC20Votes randomContract = new VoteProxyERC20Votes(
            address(aaveToken), 
            address(governorContract), 
            address(tokenPool), 
            randomUser1, 
            address(treasuryToken),
            false);
        // proxy was not made via proxy factory --> not a valid proxy  
        vm.expectRevert('Not a valid proxy address');
        tokenPool.fundProxy(10e18, address(aaveToken), randomUser1, 10);
    }



    /** 
    * @dev Token Pool is funded correctly in case:
    *    1. There is an insufficient amount of GT (some left)
    *    2. No more GT left in the token pool
    */
    function testInsufficientGTTokenPool() public {
        uint tsryFundAmount = 100e18;
        uint tsryPriceHigh = 1000; // 1000dollars

        // checks whether the balance of the proxy is set to the remaining balance of the
        // token pool if there are no more tokens left
        uint initBalanceTokenPool = aaveToken.balanceOf(address(tokenPool)); // ~30e18
        vm.prank(deployer);
        treasuryToken.transfer(user1, 100e18);
        vm.startPrank(user1);
        treasuryToken.approve(address(proxyOpenZeppelin), 100e18);
        proxyOpenZeppelin.fundMe(tsryFundAmount, proposalId ,tsryPriceHigh);
        vm.stopPrank();

        uint expectedGTFromPool = tokenPool.getUserGTAllowance(tsryFundAmount,address(aaveToken),tsryPriceHigh);
        uint aaveBalanceProxy1 = aaveToken.balanceOf(address(proxyOpenZeppelin));
        // amount of GT in the pool is not the expected amount but rather the remainder left in the pool
        assertTrue(aaveBalanceProxy1 == initBalanceTokenPool);
        assertTrue(aaveBalanceProxy1 != expectedGTFromPool);
        
        // now test if another user creates a proxy contract and theres no more GT
        
        // no aave left in token pool
        uint balanceLeft = aaveToken.balanceOf(address(tokenPool));
        assertTrue(balanceLeft == 0);
        
        vm.prank(deployer);
        treasuryToken.transfer(randomUser1, 100e18);
        
        // user creates proxy
        vm.startPrank(randomUser1);
        address addrProxyRandomUser1 = voteProxyFactory.createERC20VotesProxy(
            address(aaveToken),
            address(tokenPool),
            false
        );
        VoteProxyERC20Votes proxyRandomUser1 = VoteProxyERC20Votes(addrProxyRandomUser1);
     
        // tries to fund with some treasury
        // tx is reverted, no more aave left
        treasuryToken.approve(address(proxyRandomUser1), 100e18);
        vm.expectRevert(bytes("Token Pool has no more GT"));
        proxyRandomUser1.fundMe(tsryFundAmount, proposalId, tsryPriceHigh);
        vm.stopPrank();
    }

    /** 
    * @dev Reverting if USD amount of TSRY is too low. 
    */
    function testRevertTsryStakeLow() public {
        // revert if trying to fund proxy with a low amount
        // avoids arithmetic errors / funding with 0 aave
        uint tsryAmount = 100; // 0.0000000000000001 tsry
        uint tsryPriceLow = 1; // 1 dollar 
        vm.startPrank(user1);
        treasuryToken.approve(address(proxyOpenZeppelin), 100e18);
        vm.expectRevert(bytes("Please fund proxy with more than 1 dollars worth of TSRY"));
        proxyOpenZeppelin.fundMe(tsryAmount, proposalId, tsryPriceLow);
        vm.stopPrank();
    }

    /// =======================================
    ///                Vote Proxy
    /// =======================================

    /** 
    * @dev Ownership is correctly set to the user and not the factory.
    */
    function testOwnership() public {
        assertEq(proxyOpenZeppelin.owner(), user1);
    }

    /** 
    * @dev Proxy is correctly funded.
    */
    function testFundMe() public {
        uint tsryFundAmount = 10e18; // 10 TSRY tokens 
        // initial check that only owner can fund proxy
        vm.prank(user2);
        vm.expectRevert(bytes('Ownable: caller is not the owner'));
        proxyOpenZeppelin.fundMe(tsryFundAmount, proposalId ,tsryPrice);
        
        vm.startPrank(user1);
        treasuryToken.approve(address(proxyOpenZeppelin), 100e18);
        proxyOpenZeppelin.fundMe(tsryFundAmount, proposalId, tsryPrice);
        vm.stopPrank();
        uint aaveBalanceProxy1 = aaveToken.balanceOf(address(proxyOpenZeppelin));
        uint gtAllowanceUser1 = tokenPool.getUserGTAllowance(tsryFundAmount, address(aaveToken), tsryPrice);
        uint tsryBalanceProxy1 = treasuryToken.balanceOf(address(proxyOpenZeppelin));
        assertEq(aaveBalanceProxy1, gtAllowanceUser1);
        assertEq(tsryBalanceProxy1, tsryFundAmount);

    }

    /** 
    * @dev Proxy governor Alpha is correctly funded.
    */
    function testFundMeAlpha() public {
        
        uint tsryFundAmount = 10e18; // 10 TSRY tokens 
        vm.startPrank(user2);
        treasuryToken.approve(address(proxyGovernorAlpha), 100e18);
        proxyGovernorAlpha.fundMe(tsryFundAmount, proposalIdAlpha, tsryPrice);
        vm.stopPrank();
        uint aaveBalanceProxy2 = uniToken.balanceOf(address(proxyGovernorAlpha));
        uint gtAllowanceUser2 = tokenPool.getUserGTAllowance(tsryFundAmount, address(uniToken), tsryPrice);
        uint tsryBalanceProxy2 = treasuryToken.balanceOf(address(proxyGovernorAlpha));
        assertEq(aaveBalanceProxy2, gtAllowanceUser2);
        assertEq(tsryBalanceProxy2, tsryFundAmount);
    }

    /** @dev Proxy is correctly funded.
    */
    function testFundMeWrongProposalID() public {
        uint tsryFundAmount = 10e18; // 10 TSRY tokens 
        uint randomProposalID = 1204124; // invalid proposal id
        vm.startPrank(user1);
        treasuryToken.approve(address(proxyOpenZeppelin), 100e18);
        vm.expectRevert(bytes('Governor: unknown proposal id'));
        proxyOpenZeppelin.fundMe(tsryFundAmount, randomProposalID, tsryPrice);
        vm.stopPrank();

    }

    /** 
    * @dev Can defund proxy 
    */
    function testDefundProxy() public {
        uint fundProxyAmount = 10e18;

        uint aaveProxyBalancePreFund = aaveToken.balanceOf(address(tokenPool));
        uint tsryUserBalancePreFund = treasuryToken.balanceOf(user1);

        vm.startPrank(user1);
        treasuryToken.approve(address(proxyOpenZeppelin), 100e18);
        proxyOpenZeppelin.fundMe(fundProxyAmount,proposalId,tsryPrice);
        vm.stopPrank();

        // initally checks that the only the owner can defund their proxy
        vm.prank(user2);
        vm.expectRevert(bytes('Ownable: caller is not the owner'));
        proxyOpenZeppelin.deFundMe();

        vm.prank(user1);
        proxyOpenZeppelin.deFundMe();


        uint aaveProxyBalancePostDeFund = aaveToken.balanceOf(address(tokenPool));
        uint tsryUserBalancePostDeFund = treasuryToken.balanceOf(user1);


        assertEq(aaveProxyBalancePreFund, aaveProxyBalancePostDeFund);
        assertEq(tsryUserBalancePreFund, tsryUserBalancePostDeFund);
    }


    /** 
    * @dev Voting power is properly delegated to another user.
    *      After delegation proxy has no voting rights.
    */
    function testDelegateVote() public {    

        uint stakeAmount = 25e18;           
        vm.prank(deployer);
        aaveToken.transfer(randomUser1, 10e18);
        vm.prank(randomUser1);
        aaveToken.delegate(randomUser1);
        
        // user funds proxy and then delegates to randomUser1
        vm.startPrank(user1);
        treasuryToken.approve(address(proxyOpenZeppelin), 100e18);
        proxyOpenZeppelin.fundMe(stakeAmount, proposalId, tsryPrice);
        uint votingPowerProxyPreDelegate = aaveToken.balanceOf(address(proxyOpenZeppelin));
        proxyOpenZeppelin.delegateVotingRights(randomUser1);
        vm.stopPrank();
        // vm.rollFork(block.number + votingDelay + 1); // roll back to when snapshot is taken
        vm.roll(block.number + votingDelay + 1); // roll back to when snapshot is taken
        uint votingPowerRandom1 = governorContract.getVotes(randomUser1, block.number-1);
        uint votingPowerProxyPostDelegate = governorContract.getVotes(address(proxyOpenZeppelin), block.number-1);

        // proxy no longer has voting rights
        assertTrue(votingPowerProxyPostDelegate == 0);
        //  the proxies previous voting rights + new user has previous voting power 
        assertEq(votingPowerRandom1, votingPowerProxyPreDelegate + 10e18);

    }





}