// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/governance/IGovernor.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";
import "./interfaces/IVoteProxyRegistry.sol";

/*
 _________  ________  ___  __    _______   ________           ________  ________  ________  ___          
|\___   ___\\   __  \|\  \|\  \ |\  ___ \ |\   ___  \        |\   __  \|\   __  \|\   __  \|\  \         
\|___ \  \_\ \  \|\  \ \  \/  /|\ \   __/|\ \  \\ \  \       \ \  \|\  \ \  \|\  \ \  \|\  \ \  \        
     \ \  \ \ \  \\\  \ \   ___  \ \  \_|/_\ \  \\ \  \       \ \   ____\ \  \\\  \ \  \\\  \ \  \       
      \ \  \ \ \  \\\  \ \  \\ \  \ \  \_|\ \ \  \\ \  \       \ \  \___|\ \  \\\  \ \  \\\  \ \  \____  
       \ \__\ \ \_______\ \__\\ \__\ \_______\ \__\\ \__\       \ \__\    \ \_______\ \_______\ \_______\
        \|__|  \|_______|\|__| \|__|\|_______|\|__| \|__|        \|__|     \|_______|\|_______|\|_______|

Description:
    This is a mock token pool contract. It is meant to be used for testing purposes only as is a simplified 
    version of the real governance token pool contracts.

*/


contract TokenPool is Ownable {
    /// -----------------------------
    ///         Storage
    /// -----------------------------

    IERC20 public treasuryToken;
    address public proxyFactory;
    address public voteProxyRegistry;

    
    // token --> allowed
    mapping(address => bool) public whiteListTokens;

    // token --> price feed
    mapping(address => address) public tokenToPriceFeed;
    

    /// -----------------------------
    ///         Events
    /// -----------------------------

    event VoteProxyDeployed(address indexed proxyAddress, address _governanceTokenAddress);

    /// -----------------------------
    ///         Error
    /// -----------------------------
    
    error OnlyFactory();

    /// -----------------------------
    ///         Constructor
    /// -----------------------------

    /**
    * @dev Constructor - (N.B. Will likely change a lot during development)   
    * @param _treasuryTokenAddress: address - The address of the treasury token
    * @param _proxyFactory: address - The address of the proxy factory (needed for transfering tokens)
    * @param _voteProxyRegistry: address- The address of the vote proxy registry 
    *                                     (needed for the fund proxy function)
    */
    constructor(address _treasuryTokenAddress, address _proxyFactory, address _voteProxyRegistry){
        treasuryToken = IERC20(_treasuryTokenAddress);
        proxyFactory = _proxyFactory;
        voteProxyRegistry = _voteProxyRegistry;
    }

    /// -----------------------------
    ///         Modifiers
    /// -----------------------------

    modifier onlyFactory() {
        if (msg.sender != proxyFactory){
            revert OnlyFactory();
        }
        _;
    }

    /// -----------------------------
    ///         External
    /// -----------------------------

    /**
    * @dev Allows user to stake GT in return for TSRY 
    * @param _amount: uint - Amount of GT they want to stake
    * @param _token: address - The address of the GT
    */
    function stakeToEarn(uint256 _amount, address _token) external {
        require(_amount > 0, "Amount must be more than 0");
        require(whiteListTokens[_token], "Token not whitelisted");
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        issueTreasury(msg.sender, _amount);
    }

    /**
    * @dev Transfer GT to a proxy by first converting TSRY amount to GT amount.
    * @param _tsryAmount: uint256 - Amount of TSRY to be converted to amount of GT
    * @param _governanceToken: address - The token that needs to be sent
    * @param _user: address - user address needed to find if the proxy is valid in the registry
    * @param _tsryPrice: uint256 - TESTING ONLY sets price of TSRY
    */
    function fundProxy(uint256 _tsryAmount, address _governanceToken, address _user, uint256 _tsryPrice) external  {
        require((IVoteProxyRegistry(voteProxyRegistry).validProxy(_user, msg.sender)), "Not a valid proxy address");
        uint256 totalBalance = IERC20(_governanceToken).balanceOf(address(this));
        uint256 gtAllowance = getUserGTAllowance(_tsryAmount, _governanceToken, _tsryPrice);
        if (gtAllowance > totalBalance) {
            IERC20(_governanceToken).transfer(msg.sender, totalBalance);
        } else {
             IERC20(_governanceToken).transfer(msg.sender, gtAllowance);
        }
        
    }

    /**
    * @dev Adds allowed tokens to mapping as well as its corresponding priceFeed.
    * @param _token: address - Token to be whitelisted
    * @param _priceFeed: address - Pricefeed of token
    */
    function addAllowedTokens(address _token,  address _priceFeed) external onlyOwner {
        whiteListTokens[_token] = true;
        tokenToPriceFeed[_token] = _priceFeed;
        
    }

    /// -----------------------------
    ///         Internal
    /// -----------------------------


    /**
    * @dev Actually issues the treasury tokens to the user
    * @param _recipient: address - The address recipient user
    * @param _amount: uint - Amount of treasury tokens to be issued
    */
    function issueTreasury(address _recipient, uint _amount) internal {
        treasuryToken.transfer(_recipient, _amount);
    }

        
    /// -----------------------------
    ///         Public View
    /// -----------------------------

    /**
    * @dev Returns amount of GT from amount of TSRY (and price).
    * Converts TSRY amount --> GT amount
    * @param _tsryAmount: uint256 - Amount of tsry to covert to GT
    * @param _token: address - which token to get allowance for
    * @param _tsryPrice: uint256 - Price of TSRY (testing  only)
    */
    function getUserGTAllowance(uint256 _tsryAmount, address _token, uint256 _tsryPrice) public view returns (uint256) {
        uint _usdAmountTsry = treasuryValue(_tsryAmount, _tsryPrice);
        require(_usdAmountTsry > 1e36, "Please fund proxy with more than 1 dollars worth of TSRY");
        uint gtAllowance = getGTamount(_usdAmountTsry, _token);
        return gtAllowance;
    }

    /**
    * @dev Calculates corresponding GT from amount of TSRY given.
    * @param _usdAmountTsry: uint256 - Total value in USD (wei) of TSRY given.
    * @param _governanceToken: address - GT needed to get price of
    */
    function getGTamount(uint256 _usdAmountTsry, address _governanceToken) public view returns (uint256) {
        uint256 priceGt = getGTPrice(_governanceToken);
        return (_usdAmountTsry / priceGt);
    }

    /**
    * @dev Gets price from oracle for GT (i.e., Aave/dollars).
    */
    function getGTPrice(address _token) public view returns (uint256) {
        // price feed
        address priceFeedAddress = tokenToPriceFeed[_token];
        AggregatorV3Interface oracle = AggregatorV2V3Interface(priceFeedAddress);
        (, int256 price,,,) = oracle.latestRoundData();
        return uint256(price)* 10**10; 
    }


    /// -----------------------------
    ///         Public Pure
    /// -----------------------------


    /**
    * @dev Testing Only. Calculates value of TSRY given a set price and amount.
    * @param _tsryAmount: uint256 - Amount of tsry (wei)
    * @param _tsryPrice: uint256 - Price in dollars / token (not given as dollars/wei hence * 1e18)
    */
    function treasuryValue(uint256 _tsryAmount, uint256 _tsryPrice) public pure returns (uint256) {
        uint256 usdAmount = (_tsryAmount  * (_tsryPrice * 10**18));
        return usdAmount;
    }

}