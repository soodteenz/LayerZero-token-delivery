//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./view.sol";

contract Delivery is View, ILayerZeroReceiver {
    using safeCaller for bytes;
    constructor(address endpoint, uint16 localChainId) handler(endpoint, localChainId) {}

    ////////////////////// write functions //////////////////////
    function Send(uint16 chainId, bytes calldata _payload, address payable _refunde, address _payInZro)
        public
        payable
        onlyWhitelisted
    {   
        lzSend(chainId, _payload, _refunde, _payInZro);
    }

    function lzReceive(uint16 _srcChainId, bytes calldata path, uint64 nonce, bytes calldata _payload)
        external
        onlyEndpoint
    {
        bytes memory _path = path;
        address srcAddress;
        assembly {
            srcAddress := mload(add(_path, 20))
        }
        //  path from non valid delivery should be blocked .
        if (remoteAddress[_srcChainId] == address(0) || remoteAddress[_srcChainId] != srcAddress) {
            revert NotValidDelivery();
        }
        (bool success, ) =abi.encodeWithSelector(this.SafeReceive.selector, _payload).safeSelfCall(gasleft() - 5000);
        if (!success) {
            bytes32 payloadHash =keccak256(_payload);
            _storePayload(_srcChainId,nonce ,payloadHash);
            emit StoredPayload(_srcChainId,nonce,payloadHash);
        }

    }

    // function that reverse the failed payload , and re-mint token to the user in the src chain. 
    function reversePayload(uint16 _srcChainId,uint64 nonce, bytes calldata _payload,address _payInZro) external payable {
        // check that the payload is stored : 
        bytes32 payloadHash = keccak256(_payload);
        if (failedMsg[_srcChainId][nonce] != payloadHash ) revert NoFailedMsg();
        lzSend(_srcChainId,_payload,payable(msg.sender), _payInZro);
        failedMsg[_srcChainId][nonce] == bytes32(0);
        emit ReversePayload(_srcChainId,payloadHash);
    }

    function whiteList(address htoken,uint16 nativeChain,address nativeToken) public onlyWrapper {
        if (isHToken[htoken] || htoken == address(0)) revert InvalidTokenToWhiteList();
        isHToken[htoken] = true;
        nativeToLocal[nativeChain][nativeToken] = htoken;
    }
    
    function setAdapterParams(uint16 chainId, bytes memory adapterParams ) public onlyOwner {
        adapterParam[chainId] = adapterParams;
    }
    /////////////////// config functions (only owner) ////////////////////////

    function addRemoteAddress(uint16 chainId, address remoteAddr) external onlyOwner {
        // check that the chain is valid to this endpoint :
        address uln = endpoint.getSendLibraryAddress(address(this));
        if (IUln(uln).ulnLookup(chainId) == bytes32(0)) revert("chain id does not exist");
        if (chainId == LOCAL_CHAIN_ID) revert("can't be local chain id");
        bool changeRemote = remoteAddress[chainId] == address(0) ? false : true;
        remoteAddress[chainId] = remoteAddr;
        if (changeRemote) {
            // @todo emit change remote address
            return;
        }
        // @todo emit add remote address
    }

    function changeOwner(address newOwner) external onlyOwner {
        if (newOwner == address(0)) return;
        _owner = newOwner;
        //@todo emit new owner .
    }

    function setWraper(address _wrapper) external onlyOwner  {
        if (address(WRAPPER) != address(0)) revert("wrapper already set, can't change it");
        WRAPPER = Wrapper(_wrapper);
        isHToken[_wrapper] = true;// wrapper should be whitelisted , so he can send unwrap messages to the source chain. 
    }
    
    function setConfig(uint16 _version, uint16 _chainId, uint256 _configType, bytes calldata _config)
        external
        onlyOwner
     {
        endpoint.setConfig(_version, _chainId, _configType, _config);
    }

    function setSendVersion(uint16 _version) external onlyOwner {
        endpoint.setSendVersion(_version);
    }

    function setReceiveVersion(uint16 _version) external onlyOwner {
        endpoint.setReceiveVersion(_version);
    }

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external onlyOwner {
        endpoint.forceResumeReceive(_srcChainId, _srcAddress);
    }

    // @remind remove this functions in production....
    /////////////////////// testing function to be removed //////////////////////
    function  test_addRemoteAddress(uint16 chainId, address remoteAddr) external onlyOwner {
        require(chainId != LOCAL_CHAIN_ID,"can't be the local chain "); 
        remoteAddress[chainId] = remoteAddr;
    }
}
