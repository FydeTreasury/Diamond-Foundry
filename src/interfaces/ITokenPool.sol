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


interface ITokenPool {
    
    /**
    * @dev Allows user to stake GT in return for TSRY
    *
    * Param uint - Amount of GT they want to stake
    * Param address - The address of the GT
    */
    function stakeToEarn(uint256, address) external;

    /**
    * @dev Transfer GT to the proxies 
    * Param uint - Amount to be transfered
    * Param address - Address of governance token
    * Param address - Address of the user
    * Param uint256 - TSRY price (testing)
    */
    function fundProxy( uint256, address, address,uint256) external;


}