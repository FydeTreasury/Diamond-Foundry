// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/******************************************************************************\
* Authors: Timo Neumann <timo@fyde.fi>, Rohan Sundar <rohan@fyde.fi>
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
* Abstract Contracts for the shared setup of the tests
/******************************************************************************/

import "../src/interfaces/IDiamondCut.sol";
import "../src/facets/DiamondCutFacet.sol";
import "../src/facets/DiamondLoupeFacet.sol";
import "../src/facets/OwnershipFacet.sol";
import "../src/facets/Test1Facet.sol";
import "../src/facets/Test2Facet.sol";
import "../src/Diamond.sol";
import "./HelperContract.sol";


abstract contract StateDeployDiamond is HelperContract {

    //contract types of facets to be deployed
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;

    //interfaces with Facet ABI connected to diamond address
    IDiamondLoupe ILoupe;
    IDiamondCut ICut;

    string[] facetNames;
    address[] facetAddressList;

    // deploys diamond and connects facets
    function setUp() public virtual {

        //deploy facets
        dCutFacet = new DiamondCutFacet();
        dLoupe = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();
        facetNames = ["DiamondCutFacet", "DiamondLoupeFacet", "OwnershipFacet"];

        // diamod arguments
        DiamondArgs memory _args = DiamondArgs({
        owner: address(this),
        init: address(0),
        initCalldata: " "
        });

        // FacetCut with CutFacet for initialisation
        FacetCut[] memory cut0 = new FacetCut[](1);
        cut0[0] = FacetCut ({
        facetAddress: address(dCutFacet),
        action: IDiamond.FacetCutAction.Add,
        functionSelectors: generateSelectors("DiamondCutFacet")
        });


        // deploy diamond
        diamond = new Diamond(cut0, _args);

        //upgrade diamond with facets

        //build cut struct
        FacetCut[] memory cut = new FacetCut[](2);

        cut[0] = (
        FacetCut({
        facetAddress: address(dLoupe),
        action: FacetCutAction.Add,
        functionSelectors: generateSelectors("DiamondLoupeFacet")
        })
        );

        cut[1] = (
        FacetCut({
        facetAddress: address(ownerF),
        action: FacetCutAction.Add,
        functionSelectors: generateSelectors("OwnershipFacet")
        })
        );

        // initialise interfaces
        ILoupe = IDiamondLoupe(address(diamond));
        ICut = IDiamondCut(address(diamond));

        //upgrade diamond
        ICut.diamondCut(cut, address(0x0), "");

        // get all addresses
        facetAddressList = ILoupe.facetAddresses();
    }


}

// tests proper upgrade of diamond when adding a facet
abstract contract StateAddFacet1 is StateDeployDiamond{

    Test1Facet test1Facet;

    function setUp() public virtual override {
        super.setUp();
        //deploy Test1Facet
        test1Facet = new Test1Facet();

        // get functions selectors but remove first element (supportsInterface)
        bytes4[] memory fromGenSelectors  = removeElement(uint(0), generateSelectors("Test1Facet"));


        // array of functions to add
        FacetCut[] memory facetCut = new FacetCut[](1);
        facetCut[0] =
        FacetCut({
        facetAddress: address(test1Facet),
        action: FacetCutAction.Add,
        functionSelectors: fromGenSelectors
        });

        // add functions to diamond
        ICut.diamondCut(facetCut, address(0x0), "");

    }

}


abstract contract StateAddFacet2 is StateAddFacet1{

    Test2Facet test2Facet;

    function setUp() public virtual override {
        super.setUp();
        //deploy Test1Facet
        test2Facet = new Test2Facet();

        // get functions selectors but remove first element (supportsInterface)
        bytes4[] memory fromGenSelectors  = generateSelectors("Test2Facet");

        // array of functions to add
        FacetCut[] memory facetCut = new FacetCut[](1);
        facetCut[0] =
        FacetCut({
        facetAddress: address(test2Facet),
        action: FacetCutAction.Add,
        functionSelectors: fromGenSelectors
        });

        // add functions to diamond
        ICut.diamondCut(facetCut, address(0x0), "");

    }

}


abstract contract StateCacheBug is StateDeployDiamond {

    Test1Facet test1Facet;

    bytes4 ownerSel = hex'8da5cb5b';
    bytes4[] selectors;

    function setUp() public virtual override {
        super.setUp();
        test1Facet = new Test1Facet();

        selectors.push(hex'19e3b533');
        selectors.push(hex'0716c2ae');
        selectors.push(hex'11046047');
        selectors.push(hex'cf3bbe18');
        selectors.push(hex'24c1d5a7');
        selectors.push(hex'cbb835f6');
        selectors.push(hex'cbb835f7');
        selectors.push(hex'cbb835f8');
        selectors.push(hex'cbb835f9');
        selectors.push(hex'cbb835fa');
        selectors.push(hex'cbb835fb');

        FacetCut[] memory cut = new FacetCut[](1);
        bytes4[] memory selectorsAdd = new bytes4[](11);

        for(uint i = 0; i < selectorsAdd.length; i++){
            selectorsAdd[i] = selectors[i];
        }

        cut[0] = FacetCut({
        facetAddress: address(test1Facet),
        action: FacetCutAction.Add,
        functionSelectors: selectorsAdd
        });

        // add test1Facet to diamond
        ICut.diamondCut(cut, address(0x0), "");

        // Remove selectors from diamond
        bytes4[] memory newSelectors = new bytes4[](3);
        newSelectors[0] = ownerSel;
        newSelectors[1] = selectors[5];
        newSelectors[2] = selectors[10];

        cut[0] = FacetCut({
        facetAddress: address(0x0),
        action: FacetCutAction.Remove,
        functionSelectors: newSelectors
        });

        ICut.diamondCut(cut, address(0x0), "");
    }

}
