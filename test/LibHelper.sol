// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


import "solidity-stringutils/strings.sol";
import "../src/interfaces/IDiamond.sol";
import "../src/interfaces/IDiamondLoupe.sol";
import "../lib/forge-std/src/Test.sol";
// HELPER FUNCTIONS

library LibHelper is IDiamond, IDiamondLoupe, Test{
    using strings for *;

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
        Facet[] memory facetList = IDiamondLoupe(diamondAddress).facets();

        uint len = 0;
        for (uint i = 0; i < facetList.length; i++) {
            len += facetList[i].functionSelectors.length;
        }

        uint pos = 0;
        bytes4[] memory selectors = new bytes4[](len);
        for (uint i = 0; i < facetList.length; i++) {
            for (uint j = 0; j < facetList[i].functionSelectors.length; j++) {
                selectors[pos] = facetList[i].functionSelectors[j];
                pos += 1;
            }
        }
        return selectors;
    }

    // implement dummy override functions
    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external override {}
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_) {}
    function facetAddresses() external view returns (address[] memory facetAddresses_) {}
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_) {}
    function facets() external view returns (Facet[] memory facets_) {}

}
