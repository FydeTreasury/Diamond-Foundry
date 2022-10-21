// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../src/interfaces/IDiamondCut.sol";
import "../src/interfaces/IDiamondLoupe.sol";
import "../src/facets/DiamondCutFacet.sol";
import "../src/facets/DiamondLoupeFacet.sol";
import "../src/facets/OwnershipFacet.sol";
import "../src/facets/Test1Facet.sol";
import "../../lib/forge-std/src/Test.sol";
import "../src/Diamond.sol";

import "solidity-stringutils/strings.sol";


contract DiamondDeployer is IDiamondCut, Test {
    using strings for *;

    //contract types of facets to be deployed
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;

    //interfaces with Facet ABI connected to diamond address
    IDiamondLoupe ILoupe;
    IDiamondCut ICut;

    address[] facetAddresses;
    string[] facetNames;

    // deploys diamond and connects facets
    constructor() {

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

        //get facetAddresses
        facetAddresses = DiamondLoupeFacet(address(diamond)).facetAddresses();


    }

    // HELPER FUNCTIONS

    // return array of function selectors for given facet name
    function generateSelectors(string memory _facetName)
    internal
    returns (bytes4[] memory selectors)
    {

        //get string of contract methods
        string[] memory cmd = new string[](4);
        cmd[0] = "forge";
        cmd[1] = "inspect";
        cmd[2] = _facetName;
        cmd[3] = "methods";
        bytes memory res = vm.ffi(cmd);
        string memory st = string(res);

        // extract function signatures and take first 4 bytes of keccak
        strings.slice memory s = st.toSlice();
        strings.slice memory delim = ":".toSlice();
        strings.slice memory delim2 = ",".toSlice();
        bytes4[] memory selectors = new bytes4[]((s.count(delim)));
        for(uint i = 0; i < selectors.length; i++) {
            s.split('"'.toSlice());
            selectors[i] = bytes4(s.split(delim).until('"'.toSlice()).keccak());
            s.split(delim2);

        }
        return selectors;



    }

    // helper to remove index from bytes4[] array
    function removeIndex(uint index, bytes4[] memory array) public pure returns (bytes4[] memory){
        for(uint i = index; i < array.length-1; i++){
            array[i] = array[i+1];
        }
        delete array[array.length - 1];
        return array;
    }


    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {}

}

// test proper deployment of diamond
contract TestDeployment is DiamondDeployer {


    // TEST CASES

    function test1HasThreeFacets() public {
        assertEq(facetAddresses.length, 3);
    }


    function test2FacetsHaveCorrectSelectors() public {

        for (uint i = 0; i < facetAddresses.length; i++) {
            bytes4[] memory fromLoupeFacet = ILoupe.facetFunctionSelectors(facetAddresses[i]);
            bytes4[] memory fromGenSelectors =  generateSelectors(facetNames[i]);
            assertEq(abi.encode(fromLoupeFacet), abi.encode(fromGenSelectors));
        }
    }


    function test3SelectorsAssociatedWithCorrectFacet() public {
        for (uint i = 0; i < facetAddresses.length; i++) {
            assertEq(facetAddresses[i], ILoupe.facetAddress(generateSelectors(facetNames[i])[0]));
        }
    }

}

// tests proper upgrade of diamond when adding a facet
contract TestUpgrade is DiamondDeployer{

    Test1Facet test1Facet;

    constructor() {
        //deploy Test1Facet
        test1Facet = new Test1Facet();

        // get functions selectors but remove first element (supportsInterface)
        bytes4[] memory fromGenSelectors  = removeIndex(0, generateSelectors("Test1Facet"));

        // array of functions to add
        FacetCut[] memory cutTest1 = new FacetCut[](1);
        cutTest1[0] =
        FacetCut({
        facetAddress: address(test1Facet),
        action: FacetCutAction.Add,
        functionSelectors: fromGenSelectors
        });

        // add functions to diamond
        ICut.diamondCut(cutTest1, address(0x0), "");

    }

    function test4AddTest1FacetFunctions() public {

        // check if functions added to diamond
        bytes4[] memory fromLoupeFacet = ILoupe.facetFunctionSelectors(address(test1Facet));
        bytes4[] memory fromGenSelectors  = removeIndex(0, generateSelectors("Test1Facet"));
        assertEq(abi.encode(fromLoupeFacet), abi.encode(fromGenSelectors));

    }


    function test5CanCallTest1FacetFunction() public {

         // try to call function on new Facet
        Test1Facet(address(diamond)).test1Func10();
    }

    function test6ReplaceSupportsInterfaceFunction() public {

        // get supportsInterface selector from positon 0
        bytes4[] memory fromGenSelectors =  new bytes4[](1);
        fromGenSelectors[0] = generateSelectors("Test1Facet")[0];

        // struct to replace function
        FacetCut[] memory cutTest1 = new FacetCut[](1);
        cutTest1[0] =
        FacetCut({
        facetAddress: address(test1Facet),
        action: FacetCutAction.Replace,
        functionSelectors: fromGenSelectors
        });

        // replace function by function on Test1 facet
        ICut.diamondCut(cutTest1, address(0x0), "");

        // check supportsInterface method connected to test1Facet
        assertEq(address(test1Facet), ILoupe.facetAddress(fromGenSelectors[0]));

    }

}
