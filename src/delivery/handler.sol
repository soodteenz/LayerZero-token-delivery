//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {safeCaller} from "../utils/safeCaller.sol";
import "../interfaces/L0_interfaces.sol";
import "../wrapper/wrapper.sol";
import "../utils/errors.sol";
import "../utils/events.sol";
abstract contract handler is Events  {
    using safeCaller for bytes;

    // Maximum data to be copied from returndata in an external call
    uint32 constant MAX_RETURN_DATA_COPY = 0;
    //local chain id (layerzero chain id is different from real chain id ) . 
     uint16 immutable LOCAL_CHAIN_ID;
     // the layerzero endpoint in the local chain :
    ILayerZeroEndpoint immutable endpoint;
    mapping(uint16 chainId => address remoteAddress) remoteAddress;
    // mapping that stores the failed self call
    mapping(uint16 chainId => mapping(uint64 nonce => bytes32 hashPayload)) failedMsg;
    // mapping that stores the size payload limit for each chain :
    mapping(uint16 chainId => uint256 size) payloadSizeLimit;
    // mapping that stores the adopterParams for each chain: 
    mapping(uint16 chainId => bytes adapterParam) adapterParam;
    address  _owner;
    // wrapper contract in the local chain. 
    Wrapper  WRAPPER;
    // mapping that stores the whiteListed tokens ;
    mapping (address token => bool ) isHToken;
    //map from the native chain id and the native token address to it's htoken in the local chain. 
    mapping (uint16 chainId =>mapping( address nativeToken => address localTokenAddress)) nativeToLocal;

    modifier onlySelf() {
        if (msg.sender != address(this)) revert("only self call");
        _;
    }
    modifier onlyEndpoint() {
        if (msg.sender != address(endpoint)) revert("only endpoint call");
        _;
    }
    modifier onlyOwner() {
        if (msg.sender != _owner) revert("only owner call");
        _;
    }
    modifier onlyWhitelisted(){
        if (!isHToken[_msgSender()] ) revert OnlyWhiteListedTokens();
        _;
    }
    modifier  onlyWrapper {
        if (_msgSender() != address(WRAPPER)) revert OnlyWrapper();
        _;
    }
    constructor(address _endpoint, uint16 _localChainId) {
        endpoint = ILayerZeroEndpoint(_endpoint);
        _owner = msg.sender;
        LOCAL_CHAIN_ID = _localChainId;
    }
    function SafeReceive(  bytes calldata payload) external onlySelf   {
        (bytes memory funcArg,uint16 nativeChain,address nativeToken,string memory name, string memory symbol,uint8 decimals) = _decodePaylod(payload);
         address localToken =nativeToLocal[nativeChain][nativeToken] ;
        if(localToken== address(0)){
          localToken =  WRAPPER.clone(nativeToken,nativeChain,name,symbol,decimals);
        }
        if (!isHToken[localToken]) revert  OnlyWhiteListedTokens();
        (bool success,) = funcArg.safeExternalCall(0,gasleft(),localToken,0);
        if (!success) revert FailedToMint();
        emit  Received(nativeToken,nativeChain,localToken);
    }
    function lzSend(
        uint16 chainId,
        bytes calldata _payload,
        address payable _refunde,
        address _zroPaymentAddress
     ) internal {
        if(remoteAddress[chainId] == address(0)) revert NotValidDistanation();
        // calculate the path :
        bytes memory path = abi.encodePacked(remoteAddress[chainId], address(this));
        // if the is a size limit check that the payload don't exceed it :
        if (payloadSizeLimit[chainId] != 0) {
            if (_payload.length > payloadSizeLimit[chainId]) revert PayloadExceedsSizeLimit();
        }
        //  avoid stack to deep, copy params to memory . 
        bytes memory adapterParams = _getAdapterParams(chainId);
        // call the endpoint :
        endpoint.send{value: msg.value}(chainId, path, _payload, _refunde, _zroPaymentAddress, adapterParams);
    }


    //////////////// intrnal function ///////////////////////////
    function _decodePaylod(bytes memory _payload) internal pure returns(bytes memory funcArgs,uint16 srcChainId,address token,string memory name,string memory symb,uint8 dec){
            assembly {
                funcArgs := add(_payload,0x20)// set funcArgs pointer to where the actual length of function args stored (skip the first length)
                let length := mload(funcArgs)// get the length of function args 
                srcChainId := mload(add(funcArgs,add(length,2)))
                token := mload(add(funcArgs,add(length,22)))
                name := add(funcArgs,add(length,54))
                symb := add(name,add(32,mload(name)))
                dec := mload(add(symb,add(mload(symb),1)))
            }
    }
    function _storePayload(uint16 chainId,uint64 nonce, bytes32 hashPayload) internal {
        failedMsg[chainId][nonce] = hashPayload;
    }


    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _getAdapterParams(uint16 chainId) internal view returns(bytes memory) {
        return (adapterParam[chainId]);// if non will return bytes(0) which mean use default;
    }
}
