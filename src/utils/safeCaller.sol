//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/L0_interfaces.sol";

library safeCaller {
    ///@notice use this to call your contract function while the contract itSelf will be msg.sender. allow u to handle errors
    function safeSelfCall(bytes memory _calldata, uint256 _gas)
        internal
        returns (bool success, bytes memory returnData)
    {
        _gas == 0 ? _gas = gasleft() : _gas;
        // notice there is no need to strict the size of returned data when you call self .
        assembly {
            success := call(_gas, address(), callvalue(), add(_calldata, 0x20), mload(_calldata), 0, 0) // call self with calldata given
            let dataSize := returndatasize() // get the return data size
            mstore(returnData, dataSize) // store the lenght of the data.
            returndatacopy(add(returnData, 0x20), 0, dataSize) // returndatacopy(memory-offset,from,size)
        }
    }

    function safeExternalCall(bytes memory _calldata, uint32 maxDataCopy, uint256 _gas, address callee, uint256 value)
        internal
        returns (bool success, bytes memory returnData)
    {
        // set gas to gasleft() if non was given.
        _gas == 0 ? _gas = gasleft() : _gas;
        assembly {
            success := call(_gas, callee, value, add(_calldata, 0x20), mload(_calldata), 0, 0)
            let returnDataSize := returndatasize()
            // if the returned data > maxDataCopy then return 0 bytes , that's because the data will be corrapted any way and not gonna be decoded
            if gt(returnDataSize, maxDataCopy) { returnDataSize := 0 }

            mstore(returnData, returnDataSize)
            returndatacopy(add(returnData, 0x20), 0, returnDataSize)
        }
    }
}
