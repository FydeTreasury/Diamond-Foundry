// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./TestStates.sol";

// test proper deployment of diamond
contract TestDeployDiamond is StateDeployDiamond {


    // TEST CASES

    function test1HasThreeFacets() public {
        assertEq(facetAddressList.length, 3);
    }


    function test2FacetsHaveCorrectSelectors() public {

        for (uint i = 0; i < facetAddressList.length; i++) {
            bytes4[] memory fromLoupeFacet = ILoupe.facetFunctionSelectors(facetAddressList[i]);
            bytes4[] memory fromGenSelectors =  generateSelectors(facetNames[i]);
            assertTrue(sameMembers(fromLoupeFacet, fromGenSelectors));
        }
    }


    function test3SelectorsAssociatedWithCorrectFacet() public {
        for (uint i = 0; i < facetAddressList.length; i++) {
            bytes4[] memory fromGenSelectors =  generateSelectors(facetNames[i]);
            for (uint j = 0; i < fromGenSelectors.length; i++) {
                assertEq(facetAddressList[i], ILoupe.facetAddress(fromGenSelectors[j]));
            }
        }
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


contract TestCacheBug is StateCacheBug {


    function test1CheckSelectorsLength() public {
        bytes4[] memory selectors = ILoupe.facetFunctionSelectors(address(test1Facet));
        console.log("Selectors Length::: ", selectors.length);
        assertEq(selectors.length, 9, "selectors length is not 9");
    }

    function test2CheckSelectors() public {
        bytes4[] memory selectors = ILoupe.facetFunctionSelectors(address(test1Facet));
        bytes4[] memory expectedSelectors = new bytes4[](9);
        expectedSelectors[0] = sel0;
        expectedSelectors[1] = sel1;
        expectedSelectors[2] = sel2;
        expectedSelectors[3] = sel3;
        expectedSelectors[4] = sel4;
        expectedSelectors[5] = sel6;
        expectedSelectors[6] = sel7;
        expectedSelectors[7] = sel8;
        expectedSelectors[8] = sel9;

        sameMembers(selectors, expectedSelectors);
    }

}
