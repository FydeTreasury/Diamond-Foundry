// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import {voteOnProposal} from "./ContractStates.sol";
import "../src/Governance/GovernorAlpha.sol";
import "@openzeppelin/contracts/governance/IGovernor.sol";


///@title This contract aims to test the params at when a proposal is pending and user indicates 
/// they want to vote.

contract TestVoteOnProposal is voteOnProposal {
     

    /** 
    * @dev Voting power is properly self-delegated to Open Zeppelin proxy. 
    */
    function testSelfDelegateOpenZeppelinProxy() public {
        uint balanceOfProxy1 = aaveToken.balanceOf(address(proxyOpenZeppelin));
        uint votingPowerProxy1 = governorContract.getVotes(address(proxyOpenZeppelin), block.number-1);    
        assertEq(balanceOfProxy1, votingPowerProxy1);
    }

    /** 
    * @dev Voting power is properly self-delegated to governor Alpha proxy. 
    */
    function testSelfDelegateGovernorAlphaProxy() public {
        uint balanceOfAlphaProxy = uniToken.balanceOf(address(proxyGovernorAlpha));
        uint votingPowerAlphaProxy = uniToken.getPriorVotes(address(proxyGovernorAlpha), block.number-1);    
        assertEq(balanceOfAlphaProxy, votingPowerAlphaProxy);
    }
    
    /** 
    * @dev Proxy votes correctly on openzeppelin.
    */
    function testProxyVote() public {
        vm.prank(user1);
        proxyOpenZeppelin.proxyVote(1, proposalId);
        vm.prank(deployer);
        bool hasVoted = governorContract.hasVoted(proposalId, address(proxyOpenZeppelin));
        assertTrue(hasVoted);
    }

    /** 
    * @dev Proxy votes correctly on governor alpha.
    */
    function testProxyVoteAlpha() public {
        uint votingPower = uniToken.balanceOf(address(proxyGovernorAlpha));
        vm.prank(user2);
        proxyGovernorAlpha.proxyVote(1, proposalIdAlpha);
        GovernorAlpha.Receipt memory votingReceipt = governorAlpha.getReceipt(proposalIdAlpha, address(proxyGovernorAlpha));
        assertTrue(votingReceipt.hasVoted);
        assertEq(votingReceipt.votes,votingPower);
        assertTrue(votingReceipt.support); // vote was 1 / true
    }

    /** 
    * @dev Alpha governor returns correct state for proposal ID.
    */
    function testAlphaProxyGetState() public {
        uint proposalState = proxyGovernorAlpha.getState(proposalIdAlpha) == IGovernor.ProposalState.Active ? 1 : 999;
        // proposal state is 1 == proposal being active
        assertEq(proposalState, 1);
    }

    /** 
    * @dev Can only fund proxy if proposal is pending.
    */
    function testCantFundProxy() public {
        vm.expectRevert(bytes('Can only fund proxy if proposal is pending'));
        vm.prank(user2);
        proxyGovernorAlpha.fundMe(10e18, proposalIdAlpha, tsryPrice);
    }
    
    /** 
    * @dev Proxy returns correct amount to token pool
    */
    function testProxyReturnsGT() public {
        uint balanceTokenPoolPreVote = aaveToken.balanceOf(address(tokenPool));
        uint balanceProxyPreVote = aaveToken.balanceOf(address(proxyOpenZeppelin));
        
        vm.prank(user1);
        proxyOpenZeppelin.proxyVote(1, proposalId);
        uint balanceTokenPoolPostVote = aaveToken.balanceOf(address(tokenPool));

        // balance of token pool after vote is made is the same as the proxy + token pool
        // before vote is made
        assertEq(balanceTokenPoolPostVote, balanceTokenPoolPreVote + balanceProxyPreVote);
    
    }

    /** 
    * @dev Proxy returns correct amount of TSRY the user
    */
    function testProxyReturnsTsry() public {
        uint balanceUserPreVote = treasuryToken.balanceOf(user1);
        uint balanceProxyPreVote = treasuryToken.balanceOf(address(proxyOpenZeppelin));
        
        vm.prank(user1);
        proxyOpenZeppelin.proxyVote(1, proposalId);
        uint balanceUserPostVote = treasuryToken.balanceOf(user1);

        // balance of user after vote is made is the same as the proxy + user
        // before vote is made
        assertEq(balanceUserPostVote, balanceUserPreVote + balanceProxyPreVote);
    
    }






}