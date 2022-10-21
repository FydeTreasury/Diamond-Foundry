// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


import "./VoteProxyERC20Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ITokenPool.sol";
import "../interfaces/IVoteProxyRegistry.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../TokenPool.sol";
import "./VoteProxyRegistry.sol";
/*
 ________ ________  ________ _________  ________  ________      ___    ___ 
|\  _____\\   __  \|\   ____\\___   ___\\   __  \|\   __  \    |\  \  /  /|
\ \  \__/\ \  \|\  \ \  \___\|___ \  \_\ \  \|\  \ \  \|\  \   \ \  \/  / /
 \ \   __\\ \   __  \ \  \       \ \  \ \ \  \\\  \ \   _  _\   \ \    / / 
  \ \  \_| \ \  \ \  \ \  \____   \ \  \ \ \  \\\  \ \  \\  \|   \/  /  /  
   \ \__\   \ \__\ \__\ \_______\  \ \__\ \ \_______\ \__\\ _\ __/  / /    
    \|__|    \|__|\|__|\|_______|   \|__|  \|_______|\|__|\|__|\___/ /          

*/

contract VoteProxyFactory {
    /// -----------------------------
    ///         Storage
    /// -----------------------------
    
    address public treasuryToken;
    address public voteProxyRegistry;

    /// -----------------------------
    ///         Events
    /// -----------------------------

    event VoteProxyDeployed(address indexed proxyAddress, address governanceTokenAddress);

    /// -----------------------------
    ///         Constructor
    /// -----------------------------

    /**
    * @dev Constructor - (N.B. Will likely change a lot during development)
    * likely will not need treasury token address.
    * possibly add tokenpool address, as there will only be one pool
    */
    constructor(address _treasuryToken, address _voteProxyRegistry) {
        treasuryToken = _treasuryToken;
        voteProxyRegistry = _voteProxyRegistry;
    }

    /// -----------------------------
    ///         External
    /// -----------------------------


    /**
    * @dev Creates a proxy for a user corresponding to one token (DAO). 
    * @param _governanceToken: address - The address of governance token
    * @param _tokenPool: address - The address of the token pool (will most likely be known or mapping of token --> token pool)
    * @param _isGovernorAlpha: bool - Is the governor voting mechanism compounds' Alphas
    */
    function createERC20VotesProxy(
        address _governanceToken,
        address _tokenPool,
        bool _isGovernorAlpha
    ) external returns (address) {

        bool isOnChain = true;

        // user only has one proxy / governance token (DAO) (and that its on chain )
        require(!(IVoteProxyRegistry(voteProxyRegistry).checkProxy(msg.sender, _governanceToken, isOnChain)), "User already has proxy associated with this token");

        require(TokenPool(_tokenPool).whiteListTokens(_governanceToken), "Token is not whitelisted");

        address _governorAddress = VoteProxyRegistry(voteProxyRegistry).tokenToGovernor(_governanceToken);
           
        address proxy =
            address(new VoteProxyERC20Votes(
                _governanceToken, 
                _governorAddress, 
                _tokenPool, 
                msg.sender,
                treasuryToken,
                _isGovernorAlpha
                ));

        IVoteProxyRegistry(voteProxyRegistry).registerProxy(msg.sender, proxy, _governanceToken, isOnChain);
        
        emit VoteProxyDeployed(proxy, _governanceToken);
        return proxy;
    }
}