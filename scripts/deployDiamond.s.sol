// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Authors: Timo Neumann <timo@fyde.fi>, Rohan Sundar <rohan@fyde.fi>
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535

* Script to deploy template diamond with Cut, Loupe and Ownership facet
/******************************************************************************/

import "forge-std/Script.sol";
import "../src/Diamond.sol";
import "../src/facets/DiamondCutFacet.sol";
import "../src/facets/DiamondLoupeFacet.sol";
import "../src/facets/OwnershipFacet.sol";
import "../src/upgradeInitializers/DiamondInit.sol";
import "../test/HelperContract.sol";


contract DeployScript is Script, HelperContract {
    function run() external {

        //read env variables and choose EOA for transaction signing
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.envAddress("PUBLIC_KEY");

        vm.startBroadcast(deployerPrivateKey);

        //deploy facets and init contract
        DiamondCutFacet dCutF = new DiamondCutFacet();
        DiamondLoupeFacet dLoupeF = new DiamondLoupeFacet();
        OwnershipFacet ownerF = new OwnershipFacet();

        DiamondInit diamondInit = new DiamondInit();


        // diamod arguments
        DiamondArgs memory _args = DiamondArgs({
        owner: deployerAddress,
        init: address(diamondInit),
        initCalldata: abi.encodeWithSignature("init()")
        });

        // FacetCut array which contains the three standard facets to be added
        FacetCut[] memory cut = new FacetCut[](3);

        cut[0] = FacetCut ({
        facetAddress: address(dCutF),
        action: IDiamond.FacetCutAction.Add,
        functionSelectors: generateSelectors("DiamondCutFacet")
        });

        cut[1] = (
        FacetCut({
        facetAddress: address(dLoupeF),
        action: FacetCutAction.Add,
        functionSelectors: generateSelectors("DiamondLoupeFacet")
        })
        );

        cut[2] = (
        FacetCut({
        facetAddress: address(ownerF),
        action: FacetCutAction.Add,
        functionSelectors: generateSelectors("OwnershipFacet")
        })
        );


        // deploy diamond
        Diamond diamond = new Diamond(cut, _args);

        vm.stopBroadcast();
    }
}

