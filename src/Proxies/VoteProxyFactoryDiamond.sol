// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


import "../facets/ERC20VotingFacet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ITokenPool.sol";
import "../interfaces/IVoteProxyRegistryDiamond.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../TokenPool.sol";
import "./VoteProxyRegistryDiamond.sol";
import "../facets/DiamondCutFacet.sol";
import "../facets/DiamondLoupeFacet.sol";
import "../facets/OwnershipFacet.sol";
import "../VotingDiamond.sol";
import "../interfaces/IDiamond.sol";

/*
 ________ ________  ________ _________  ________  ________      ___    ___
|\  _____\\   __  \|\   ____\\___   ___\\   __  \|\   __  \    |\  \  /  /|
\ \  \__/\ \  \|\  \ \  \___\|___ \  \_\ \  \|\  \ \  \|\  \   \ \  \/  / /
 \ \   __\\ \   __  \ \  \       \ \  \ \ \  \\\  \ \   _  _\   \ \    / /
  \ \  \_| \ \  \ \  \ \  \____   \ \  \ \ \  \\\  \ \  \\  \|   \/  /  /
   \ \__\   \ \__\ \__\ \_______\  \ \__\ \ \_______\ \__\\ _\ __/  / /
    \|__|    \|__|\|__|\|_______|   \|__|  \|_______|\|__|\|__|\___/ /

*/

contract VoteProxyFactoryDiamond is IDiamond{
    /// -----------------------------
    ///         Storage
    /// -----------------------------

    struct FacetInfo{
        address facetAddress;
        bytes4[] selectors;
    }



    address public treasuryToken;
    address public voteProxyRegistry;

    // facet name to address and selectors
    mapping(string => FacetInfo) facetInfo;

    /// -----------------------------
    ///         Events
    /// -----------------------------

    event VoteProxyDeployed(address indexed proxyAddress);

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

        // deploy standard facets
        DiamondCutFacet cutF = new DiamondCutFacet();
        DiamondLoupeFacet loupeF = new DiamondLoupeFacet();
        OwnershipFacet ownerF = new OwnershipFacet();

        // add address selectors to facetInfo
        facetInfo["DiamondCutFacet"].facetAddress = address(cutF);
        facetInfo["DiamondCutFacet"].selectors.push(cutF.diamondCut.selector);

        facetInfo["DiamondLoupeFacet"].facetAddress = address(loupeF);
        facetInfo["DiamondLoupeFacet"].selectors.push(loupeF.facetAddress.selector);
        facetInfo["DiamondLoupeFacet"].selectors.push(loupeF.facetAddresses.selector);
        facetInfo["DiamondLoupeFacet"].selectors.push(loupeF.facetFunctionSelectors.selector);
        facetInfo["DiamondLoupeFacet"].selectors.push(loupeF.facets.selector);

        facetInfo["OwnershipFacet"].facetAddress = address(ownerF);
        facetInfo["OwnershipFacet"].selectors.push(ownerF.owner.selector);
        facetInfo["OwnershipFacet"].selectors.push(ownerF.transferOwnership.selector);
    }

    /// -----------------------------
    ///         External
    /// -----------------------------


    /**
    * @dev Creates a proxy for a user
    */
    function createERC20VotesProxy() external returns (address) {

        // user only has no proxy
        require(!(IVoteProxyRegistryDiamond(voteProxyRegistry).checkProxy(msg.sender)), "User already has proxy");

        // deploy proxy
        address proxy = deployVotingDiamond(msg.sender);

        IVoteProxyRegistryDiamond(voteProxyRegistry).registerProxy(msg.sender, proxy);
        
        emit VoteProxyDeployed(proxy);
        return proxy;
    }

    function deployVotingDiamond(address _owner) internal returns (address){

        // diamod arguments
        DiamondArgs memory _args = DiamondArgs({
        owner: _owner,
        init: address(0),
        initCalldata: " "
        });


        //build cut struct with initial basic facets
        FacetCut[] memory cut = new FacetCut[](3);

        cut[0] = FacetCut ({
        facetAddress: facetInfo["DiamondCutFacet"].facetAddress,
        action: IDiamond.FacetCutAction.Add,
        functionSelectors: facetInfo["DiamondCutFacet"].selectors
        });

        cut[1] = (
        FacetCut({
        facetAddress: facetInfo["DiamondLoupeFacet"].facetAddress,
        action: IDiamond.FacetCutAction.Add,
        functionSelectors: facetInfo["DiamondLoupeFacet"].selectors
        })
        );

        cut[2] = (
        FacetCut({
        facetAddress: facetInfo["OwnershipFacet"].facetAddress,
        action: IDiamond.FacetCutAction.Add,
        functionSelectors: facetInfo["OwnershipFacet"].selectors
        })
        );

        // deploy diamond
        return address(new VotingDiamond(cut, _args));


    }

}