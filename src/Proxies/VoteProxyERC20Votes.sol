
// SPDX-License-Identifier: MIT


pragma solidity ^0.8.15;

import "@openzeppelin/contracts/governance/IGovernor.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/governance/utils/IVotes.sol";
import "../interfaces/ITokenPool.sol";
import "../Proxies/VoteProxyFactory.sol";


/*

 _______   ________  ________   _______  ________          ___      ___ ________  _________  _______   ________      
|\  ___ \ |\   __  \|\   ____\ /  ___  \|\   __  \        |\  \    /  /|\   __  \|\___   ___\\  ___ \ |\   ____\     
\ \   __/|\ \  \|\  \ \  \___|/__/|_/  /\ \  \|\  \       \ \  \  /  / | \  \|\  \|___ \  \_\ \   __/|\ \  \___|_    
 \ \  \_|/_\ \   _  _\ \  \   |__|//  / /\ \  \\\  \       \ \  \/  / / \ \  \\\  \   \ \  \ \ \  \_|/_\ \_____  \   
  \ \  \_|\ \ \  \\  \\ \  \____  /  /_/__\ \  \\\  \       \ \    / /   \ \  \\\  \   \ \  \ \ \  \_|\ \|____|\  \  
   \ \_______\ \__\\ _\\ \_______\\________\ \_______\       \ \__/ /     \ \_______\   \ \__\ \ \_______\____\_\  \ 
    \|_______|\|__|\|__|\|_______|\|_______|\|_______|        \|__|/       \|_______|    \|__|  \|_______|\_________\
                                                                                                         \|_________|
*/

contract VoteProxyERC20Votes is Ownable{

    /// -----------------------------
    ///         Storage
    /// -----------------------------

    address public governanceToken;
    address public treasuryToken;
    address public governor;
    address public tokenPool;
    address public proxyFactory;
    bool public isGovernorAlpha;

    /// -----------------------------
    ///         Events
    /// -----------------------------

    /**
    * @dev Emitted when a user votes.
    */
    event VoteCasted(uint256 proposalID, uint vote);

    /**
    * @dev Emitted when a user delegates voting power.
    */
    event VoteDelegated(address delegate);

    /// -----------------------------
    ///         Constructor
    /// -----------------------------

    /**
    * @dev Constructor for the VoteProxyERC20 contract 
    *   - Immediately self delegates voting power  
    *   - Sets owner of the contract to the user
    *   - Sets proxy factory as msg.sender 
    * TODO:
    *    1. The treasury token address will be a fixed address
    *    2. Token pool will be fixed address
    * @param _governanceToken: address - The address of the governance token
    * @param _governor: address - The address of the governor contract for the DAO
    * @param _tokenPool: address - The address of the token pool contract that the token came from
    * @param _user: address - Address of the end user  
    * @param _treasuryToken: address - Tresaury token address
    */

    constructor(
        address _governanceToken,
        address _governor,
        address _tokenPool,
        address _user,
        address _treasuryToken,
        bool _isGovernorAlpha) {
        transferOwnership(_user);
        governanceToken = _governanceToken;
        governor = _governor;
        tokenPool = _tokenPool;
        proxyFactory = msg.sender;
        treasuryToken = _treasuryToken;
        isGovernorAlpha = _isGovernorAlpha;
    }

    /// -----------------------------
    ///         External
    /// -----------------------------

    /**
    * @dev Vote with amount of governance token stored in contract. 
    *    - Sends TSRY back to the user.
    *    - Sends back all GT to token pool.
    * @param _vote: uint8 - Vote (0,1,2)
    *   Against: 0
    *   For: 1
    *   Abstain: 2
    * @param _proposalID: uint256 - Specific proposal
    */
    function proxyVote(uint8 _vote, uint256 _proposalID) external onlyOwner {
        if(isGovernorAlpha) {
            require(_vote == 0 || _vote == 1, "Governor Alpha only accepts bool type voting (0 or 1)");
            _vote == 1 ? IGovernorAlpha(governor).castVote(_proposalID, true) : IGovernorAlpha(governor).castVote(_proposalID, false);
        } else {
            IGovernor(governor).castVote(_proposalID, _vote);
        }
        deFundMe();
        emit VoteCasted(_proposalID, _vote);
    }

    /**
    * @dev (for now you can only fully defund) - Avoids conversion from GT --> TSRY
    *     - Sends back all GT to token pool.
    *     - Sends back TSRY to user
    */
    function deFundMe() public onlyOwner {
        IERC20(governanceToken).transfer(tokenPool, IERC20(governanceToken).balanceOf(address(this)));
        IERC20(treasuryToken).transfer(msg.sender, IERC20(treasuryToken).balanceOf(address(this)));
    }

    /**
    * @dev Stakes treasury and makes an external call to the voteproxyfactory
    * in order to fund this contract with the corresponding amount of governance token
    * @param _stakeAmount: uint - Amount user has to deposit into this contract
    * @param _tsryPrice: uint - for testing, the price of tsry.
    */
    function fundMe(uint256 _stakeAmount, uint _proposalID ,uint256 _tsryPrice) external onlyOwner {
        // Amount is calculated from the price of TSRY to GT.
        // If TSRY is worth 1$ and GT is worth 2$ --> 2 TSRY == 1 GT
        // User calls contract with 10 TSRY, only 5 GT gets transferred to proxy
        // This gets reflected in the UI (i.e. user will be able to see how much GT they are entitled to vote with)
        // This value also gets checked against the amount of GT currently in the pool. If the value is more than the balanceOF GT
        // in the pool, then the proxy only gets the remaining amount of GT sent.
        // E.g User wants to vote with 10 TSRY worth of GT, there is only 3 GT remaining in the pool. Proxy only receives 3 GT.
        // This also gets reflected in the UI (the amount of GT they are entitled too also gets affected by amount of GT in the pool).
        // Should be able to query the token pool to get this information.

        require(getState(_proposalID) == IGovernor.ProposalState.Pending, 'Can only fund proxy if proposal is pending');
        
        uint256 totalBalancePool = IERC20(governanceToken).balanceOf(tokenPool);
        // checks pool has more than 0 GT, does this check before proxy is funded to avoid chain of external calls
        require(totalBalancePool > 0, "Token Pool has no more GT");
        require (_stakeAmount > 0, "Please fund with more TSRY ");
        
        // remember to approve this address 

        bool transferSuccess = IERC20(treasuryToken).transferFrom(msg.sender, address(this), _stakeAmount);
        require(transferSuccess, 'TSRY stake trasnfer was not successful');
        
        // call for factory to send correct amount of governance token
        ITokenPool(tokenPool).fundProxy(_stakeAmount, governanceToken, msg.sender, _tsryPrice);

        IVotes(governanceToken).delegate(address(this));
    }

    /**
    * @dev Delegates voting power of this contract to another address.
    * @param _delegate: address - Address of delegate.
    */
    function delegateVotingRights(address _delegate) external onlyOwner {
        IVotes(governanceToken).delegate(_delegate);
        emit VoteDelegated(_delegate);
    }

    /// -----------------------------
    ///         View
    /// -----------------------------

    /**
    * @dev Retrieves current state of the proposal  
    * @return ProposalState - The state of the proposal
    *    Pending: 0
    *    Active: 1
    *    Canceled: 2
    *    Defeated: 3 
    *    Succeeded: 4
    *    Queued: 5
    *    Expired: 6
    *    Executed: 7
    */
    function getState(uint _proposalID) public view returns (IGovernor.ProposalState) {
        return IGovernor(governor).state(_proposalID);
    }

}

interface IGovernorAlpha {
    function castVote(uint, bool) external;
}