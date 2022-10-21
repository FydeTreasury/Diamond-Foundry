// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

/*

 ___  ________   _________  _______   ________  ________ ________  ________  _______      
|\  \|\   ___  \|\___   ___\\  ___ \ |\   __  \|\  _____\\   __  \|\   ____\|\  ___ \     
\ \  \ \  \\ \  \|___ \  \_\ \   __/|\ \  \|\  \ \  \__/\ \  \|\  \ \  \___|\ \   __/|    
 \ \  \ \  \\ \  \   \ \  \ \ \  \_|/_\ \   _  _\ \   __\\ \   __  \ \  \    \ \  \_|/__  
  \ \  \ \  \\ \  \   \ \  \ \ \  \_|\ \ \  \\  \\ \  \_| \ \  \ \  \ \  \____\ \  \_|\ \ 
   \ \__\ \__\\ \__\   \ \__\ \ \_______\ \__\\ _\\ \__\   \ \__\ \__\ \_______\ \_______\
    \|__|\|__| \|__|    \|__|  \|_______|\|__|\|__|\|__|    \|__|\|__|\|_______|\|_______|


*/


interface IVoteProxyRegistry {
    
    function checkProxy(address, address, bool) external returns(bool);

    function validProxy(address, address) external view returns (bool);
   
    /**
    * @dev
    */
    function registerProxy(address, address, address, bool) external returns (bool);

    /**
    * @dev 
    */
    function getContractDetails(address, address, bool) external returns (address);

    


}