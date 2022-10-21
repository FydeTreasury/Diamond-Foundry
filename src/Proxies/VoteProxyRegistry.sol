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

contract VoteProxyRegistry is Ownable {

    /// -----------------------------
    ///         Storage
    /// -----------------------------

    struct ProxyDetails {
        address proxyAddress;
        address governanceToken;
        bool onChain;
    }

    // unique user --> proxy details
    mapping(address => ProxyDetails[]) registry;

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
    * @param _governanceToken: address - Governance token of DAO
    * @param _isOnChain: bool - If the proxy relates to on vs off chain voting
    */
    function checkProxy(address _user, address _governanceToken, bool _isOnChain) external view returns (bool)  {
        ProxyDetails[] memory proxiesForUser = registry[_user];
        uint proxyListLength = proxiesForUser.length;
        for(uint i; i < proxyListLength;){
            if(proxiesForUser[i].governanceToken == _governanceToken && proxiesForUser[i].onChain == _isOnChain) {
                return true; 
            }
            unchecked{++i;}
        }
        return false;
    }

    /**
    * @dev Checks that proxy is valid.
    * @param _user: address - Address of user
    * @param _proxyAddress: address - Address of proxy
    */
    function validProxy(address _user, address _proxyAddress) external view returns (bool) {
        ProxyDetails[] memory proxiesForUser = registry[_user];
        uint proxyListLength = proxiesForUser.length;
        for(uint i; i < proxyListLength;){
            if(proxiesForUser[i].proxyAddress == _proxyAddress) {
                return true; 
            }
            unchecked{++i;}
        }
        return false;
    }


    /**
    * @dev Adds proxy to the registry with proxy details
    * @param _user: address - Address of user
    * @param _proxyAddress: address - Address of proxy
    * @param _governanceToken: address - Address of governance token
    * @param _onChain: Bool - whether voting mechanism is on or off chain
    */
    function registerProxy(address _user, address _proxyAddress, address _governanceToken, bool _onChain) external onlyFactory returns (bool){
        ProxyDetails memory info = ProxyDetails({
            proxyAddress: _proxyAddress,
            governanceToken: _governanceToken,
            onChain: _onChain
        });
        // update record in the registry
        registry[_user].push(info);
        return true;
    }

    
    /// -----------------------------
    ///        External View
    /// -----------------------------


    function getProxyAddress(address _user, address _governanceToken, bool _isOnChain) external view onlyFactory returns (address) {
        ProxyDetails[] memory proxiesForUser = registry[_user];
        uint proxyListLength = proxiesForUser.length;
        for(uint i; i < proxyListLength;){
            if(proxiesForUser[i].governanceToken == _governanceToken && proxiesForUser[i].onChain == _isOnChain) {
                return (proxiesForUser[i].proxyAddress); 
            }
            unchecked{++i;}
        }
        return address(0);
        
    }

}
