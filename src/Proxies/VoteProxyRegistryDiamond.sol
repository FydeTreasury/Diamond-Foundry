// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

/*
 ________  _______   ________  ___  ________  _________  ________      ___    ___ 
|\   __  \|\  ___ \ |\   ____\|\  \|\   ____\|\___   ___\\   __  \    |\  \  /  /|
\ \  \|\  \ \   __/|\ \  \___|\ \  \ \  \___|\|___ \  \_\ \  \|\  \   \ \  \/  / /
 \ \   _  _\ \  \_|/_\ \  \  __\ \  \ \_____  \   \ \  \ \ \   _  _\   \ \    / / 
  \ \  \\  \\ \  \_|\ \ \  \|\  \ \  \|____|\  \   \ \  \ \ \  \\  \|   \/  /  /  
   \ \__\\ _\\ \_______\ \_______\ \__\____\_\  \   \ \__\ \ \__\\ _\ __/  / /    
    \|__|\|__|\|_______|\|_______|\|__|\_________\   \|__|  \|__|\|__|\___/ /     
                                      \|_________|                   \|___|/      
*/

contract VoteProxyRegistryDiamond is Ownable {

    /// -----------------------------
    ///         Storage
    /// -----------------------------


    // unique user --> proxy address
    mapping(address => address) registry;

    // token address to governor contract
    mapping(address => address) public tokenToGovernor;

    address public proxyFactory;

    /// -----------------------------
    ///         Error
    /// -----------------------------
    
    error OnlyFactory();

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
    * @dev Sets the factory address
    * @param _factory: address - factory
    */
    function addFactory(address _factory) external onlyOwner {
        proxyFactory = _factory;
    }

    /**
    * @dev Adds to the governor token --> governor contract mapping.
    * @param _governanceToken: address - Governance token of DAO
    * @param _governor: bool - Governor contract
    */
    function addGovernor(address _governanceToken, address _governor) external onlyOwner {
        tokenToGovernor[_governanceToken] = _governor;
    }

     /**
    * @dev Checks if a user already has a proxy for that token.
    * @param _user: address - Address of user
    */
    function checkProxy(address _user) external view returns (bool)  {
        return registry[_user] != address(0);
    }



    /**
    * @dev Adds proxy to the registry with proxy details
    * @param _user: address - Address of user
    * @param _proxyAddress: address - Address of proxy
    */
    function registerProxy(address _user, address _proxyAddress) external onlyFactory returns (bool){
        // update record in the registry
        registry[_user] = _proxyAddress;
        return true;
    }

    
    /// -----------------------------
    ///        External View
    /// -----------------------------


    function getProxyAddress(address _user) external view onlyFactory returns (address) {
        return registry[_user];
        
    }

}
