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


abstract contract StateDeployDiamond is IDiamondCut, IDiamondLoupe, Test {
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
        selectors = new bytes4[]((s.count(delim)));
        for(uint i = 0; i < selectors.length; i++) {
            s.split('"'.toSlice());
            selectors[i] = bytes4(s.split(delim).until('"'.toSlice()).keccak());
            s.split(delim2);

        }
        return selectors;



    }

    // helper to remove index from bytes4[] array
    function removeElement(uint index, bytes4[] memory array) public pure returns (bytes4[] memory){
        bytes4[] memory newarray = new bytes4[](array.length-1);
        uint j = 0;
        for(uint i = 0; i < array.length; i++){
            if (i != index){
                newarray[j] = array[i];
                j += 1;
            }
        }
        return newarray;

    }

    // helper to remove value from bytes4[] array
    function removeElement(bytes4 el, bytes4[] memory array) public pure returns (bytes4[] memory){
        for(uint i = 0; i < array.length; i++){
            if (array[i] == el){
                return removeElement(i, array);
            }
        }
        return array;

    }

    function containsElement(bytes4[] memory array, bytes4 el) public pure returns (bool) {
        for (uint i = 0; i < array.length; i++) {
            if (array[i] == el) {
                return true;
            }
        }

        return false;
    }

    function containsElement(address[] memory array, address el) public pure returns (bool) {
        for (uint i = 0; i < array.length; i++) {
            if (array[i] == el) {
                return true;
            }
        }

        return false;
    }

    function sameMembers(bytes4[] memory array1, bytes4[] memory array2) public pure returns (bool) {
        if (array1.length != array2.length) {
            return false;
        }
        for (uint i = 0; i < array1.length; i++) {
            if (containsElement(array1, array2[i])){
            return true;
            }
        }

        return false;
    }

    function getAllSelectors(address diamondAddress) public view returns (bytes4[] memory){
        Facet[] memory facets = IDiamondLoupe(diamondAddress).facets();

        uint len = 0;
        for (uint i = 0; i < facets.length; i++) {
            len += facets[i].functionSelectors.length;
        }

        uint pos = 0;
        bytes4[] memory selectors = new bytes4[](len);
        for (uint i = 0; i < facets.length; i++) {
            for (uint j = 0; j < facets[i].functionSelectors.length; j++) {
                selectors[pos] = facets[i].functionSelectors[j];
                pos += 1;
            }
        }
        return selectors;
    }





    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external override {}

    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_) {}

    function facetAddresses() external view returns (address[] memory facetAddresses_) {}

    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_) {}

    function facets() external view returns (Facet[] memory facets_) {}

}

// test proper deployment of diamond
contract TestDeployDiamond is StateDeployDiamond {


    // TEST CASES

    function test1HasThreeFacets() public {
        assertEq(ILoupe.facetAddresses().length, 3);
    }


    function test2FacetsHaveCorrectSelectors() public {

        for (uint i = 0; i < ILoupe.facetAddresses().length; i++) {
            bytes4[] memory fromLoupeFacet = ILoupe.facetFunctionSelectors(ILoupe.facetAddresses()[i]);
            bytes4[] memory fromGenSelectors =  generateSelectors(facetNames[i]);
            assertTrue(sameMembers(fromLoupeFacet, fromGenSelectors));
        }
    }


    function test3SelectorsAssociatedWithCorrectFacet() public {
        for (uint i = 0; i < ILoupe.facetAddresses().length; i++) {
            bytes4[] memory fromGenSelectors =  generateSelectors(facetNames[i]);
            for (uint j = 0; i < fromGenSelectors.length; i++) {
                assertEq(ILoupe.facetAddresses()[i], ILoupe.facetAddress(fromGenSelectors[j]));
            }
        }
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

contract TestAddFacet1 is StateAddFacet1{

    function test4AddTest1FacetFunctions() public {

        // check if functions added to diamond
        bytes4[] memory fromLoupeFacet = ILoupe.facetFunctionSelectors(address(test1Facet));
        bytes4[] memory fromGenSelectors  = removeElement(uint(0), generateSelectors("Test1Facet"));
        assertTrue(sameMembers(fromLoupeFacet, fromGenSelectors));

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


contract TestAddFacet2 is StateAddFacet2{

    function test7AddTest2FacetFunctions() public {

        // check if functions added to diamond
        bytes4[] memory fromLoupeFacet = ILoupe.facetFunctionSelectors(address(test2Facet));
        bytes4[] memory fromGenSelectors  = generateSelectors("Test2Facet");
        assertTrue(sameMembers(fromLoupeFacet, fromGenSelectors));

    }


    function test8RemoveSomeTest2FacetFunctions() public {

        bytes4[] memory functionsToKeep = new bytes4[](5);
        functionsToKeep[0] = test2Facet.test2Func1.selector;
        functionsToKeep[1] = test2Facet.test2Func5.selector;
        functionsToKeep[2] = test2Facet.test2Func6.selector;
        functionsToKeep[3] = test2Facet.test2Func19.selector;
        functionsToKeep[4] = test2Facet.test2Func20.selector;

        bytes4[] memory selectors = ILoupe.facetFunctionSelectors(address(test2Facet));
        for (uint i = 0; i<functionsToKeep.length; i++){
            selectors = removeElement(functionsToKeep[i], selectors);
        }


        // array of functions to remove
        FacetCut[] memory facetCut = new FacetCut[](1);
        facetCut[0] =
        FacetCut({
        facetAddress: address(0x0),
        action: FacetCutAction.Remove,
        functionSelectors: selectors
        });

        // add functions to diamond
        ICut.diamondCut(facetCut, address(0x0), "");

        bytes4[] memory fromLoupeFacet = ILoupe.facetFunctionSelectors(address(test2Facet));
        assertTrue(sameMembers(fromLoupeFacet, functionsToKeep));



    }


    function test9RemoveSomeTest1FacetFunctions() public {

        bytes4[] memory functionsToKeep = new bytes4[](3);
        functionsToKeep[0] = test1Facet.test1Func2.selector;
        functionsToKeep[1] = test1Facet.test1Func11.selector;
        functionsToKeep[2] = test1Facet.test1Func12.selector;


        bytes4[] memory selectors = ILoupe.facetFunctionSelectors(address(test1Facet));
        for (uint i = 0; i<functionsToKeep.length; i++){
            selectors = removeElement(functionsToKeep[i], selectors);
        }


        // array of functions to remove
        FacetCut[] memory facetCut = new FacetCut[](1);
        facetCut[0] =
        FacetCut({
        facetAddress: address(0x0),
        action: FacetCutAction.Remove,
        functionSelectors: selectors
        });

        // add functions to diamond
        ICut.diamondCut(facetCut, address(0x0), "");

        bytes4[] memory fromLoupeFacet = ILoupe.facetFunctionSelectors(address(test1Facet));
        assertTrue(sameMembers(fromLoupeFacet, functionsToKeep));



    }

    function test10RemoveAllExceptDiamondCutAndFacetFunction() public {

    bytes4[] memory selectors = getAllSelectors(address(diamond));

    bytes4[] memory functionsToKeep = new bytes4[](2);
    functionsToKeep[0] = DiamondCutFacet.diamondCut.selector;
    functionsToKeep[1] = DiamondLoupeFacet.facets.selector;


    selectors = removeElement(functionsToKeep[0], selectors);
    selectors = removeElement(functionsToKeep[1], selectors);


    // array of functions to remove
    FacetCut[] memory facetCut = new FacetCut[](1);
    facetCut[0] =
    FacetCut({
    facetAddress: address(0x0),
    action: FacetCutAction.Remove,
    functionSelectors: selectors
    });

    // remove functions from diamond
    ICut.diamondCut(facetCut, address(0x0), "");


    Facet[] memory facets = ILoupe.facets();
    bytes4[] memory testselector = new bytes4[](1);

    assertEq(facets.length, 2);

    assertEq(facets[0].facetAddress, address(dCutFacet));

    testselector[0] = functionsToKeep[0];
    assertTrue(sameMembers(facets[0].functionSelectors, testselector));


    assertEq(facets[1].facetAddress, address(dLoupe));
    testselector[0] = functionsToKeep[1];
    assertTrue(sameMembers(facets[1].functionSelectors, testselector));

    }

}
