//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./handler.sol";

abstract contract View is handler {
    function estimateFees(uint16 _dstChain, bytes memory _payload, bool _payInZRO)
        external
        view
        returns (uint256 nativeFee, uint256 zroFee)
    {
        return endpoint.estimateFees(_dstChain, address(this), _payload, _payInZRO, _getAdapterParams(_dstChain));
    }

    function isValidDistination(uint16 chainId) external view returns (bool valid) {
        valid = remoteAddress[chainId] != address(0);
    }

    function owner() external view returns (address) {
        return _owner;
    }

    function wrapper() external view returns (address) {
        return address(WRAPPER);
    }

    function localChainId() external view returns (uint16) {
        return LOCAL_CHAIN_ID;
    }

    function lzEndpoint() external view returns (address) {
        return address(endpoint);
    }

    function remoteDelivery(uint16 chainId) external view returns (address) {
        return remoteAddress[chainId];
    }

    function adapterParameters(uint16 chainId) external view returns (bytes memory) {
        return adapterParam[chainId];
    }

    function isHawkToken(address token) public view returns (bool valid) {
        valid = isHToken[token];
    }
}
