// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../src/interfaces/IDiamondCut.sol";
import "../src/interfaces/IDiamondLoupe.sol";
import "../src/facets/DiamondCutFacet.sol";
import "../src/facets/DiamondLoupeFacet.sol";
import "../src/facets/OwnershipFacet.sol";
import "../src/facets/Test1Facet.sol";
import "../src/facets/Test2Facet.sol";
import "../lib/forge-std/src/Test.sol";
import "../src/Diamond.sol";

import "solidity-stringutils/strings.sol";
import "./LibHelper.sol";


abstract contract StateDeployDiamond is IDiamond, IDiamondLoupe, Test {
    using strings for *;

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
        functionSelectors: LibHelper.generateSelectors("DiamondCutFacet")
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
        functionSelectors: LibHelper.generateSelectors("DiamondLoupeFacet")
        })
        );

        cut[1] = (
        FacetCut({
        facetAddress: address(ownerF),
        action: FacetCutAction.Add,
        functionSelectors: LibHelper.generateSelectors("OwnershipFacet")
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

    // implement dummy override functions
    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external override {}
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_) {}
    function facetAddresses() external view returns (address[] memory facetAddresses_) {}
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_) {}
    function facets() external view returns (Facet[] memory facets_) {}

}

// tests proper upgrade of diamond when adding a facet
abstract contract StateAddFacet1 is StateDeployDiamond{

    Test1Facet test1Facet;

    function setUp() public virtual override {
        super.setUp();
        //deploy Test1Facet
        test1Facet = new Test1Facet();

        // get functions selectors but remove first element (supportsInterface)
        bytes4[] memory fromGenSelectors  = LibHelper.removeElement(uint(0), LibHelper.generateSelectors("Test1Facet"));


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

    bytes4 sel0 = hex'19e3b533'; // fills up slot 1
    bytes4 sel1 = hex'0716c2ae'; // fills up slot 1
    bytes4 sel2 = hex'11046047'; // fills up slot 1
    bytes4 sel3 = hex'cf3bbe18'; // fills up slot 1
    bytes4 sel4 = hex'24c1d5a7'; // fills up slot 1
    bytes4 sel5 = hex'cbb835f6'; // fills up slot 1
    bytes4 sel6 = hex'cbb835f7'; // fills up slot 1
    bytes4 sel7 = hex'cbb835f8'; // fills up slot 2
    bytes4 sel8 = hex'cbb835f9'; // fills up slot 2
    bytes4 sel9 = hex'cbb835fa'; // fills up slot 2
    bytes4 sel10 = hex'cbb835fb'; // fills up slot 2


    function setUp() public virtual override {
        super.setUp();
        test1Facet = new Test1Facet();

        FacetCut[] memory cutTest1 = new FacetCut[](1);
        bytes4[] memory selectors = new bytes4[](11);

        selectors[0] = sel0;
        selectors[1] = sel1;
        selectors[2] = sel2;
        selectors[3] = sel3;
        selectors[4] = sel4;
        selectors[5] = sel5;
        selectors[6] = sel6;
        selectors[7] = sel7;
        selectors[8] = sel8;
        selectors[9] = sel9;
        selectors[10] = sel10;

        cutTest1[0] = FacetCut({
        facetAddress: address(test1Facet),
        action: FacetCutAction.Add,
        functionSelectors: selectors
        });

        // add test1Facet to diamond
        ICut.diamondCut(cutTest1, address(0x0), "");

        // Remove selectors from diamond
        bytes4[] memory newSelectors = new bytes4[](3);
        newSelectors[0] = ownerSel;
        newSelectors[1] = sel5;
        newSelectors[2] = sel10;

        cutTest1[0] = FacetCut({
        facetAddress: address(0x0),
        action: FacetCutAction.Remove,
        functionSelectors: newSelectors
        });

        ICut.diamondCut(cutTest1, address(0x0), "");
    }

}
