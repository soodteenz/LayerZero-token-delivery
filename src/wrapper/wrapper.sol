//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IHtoken.sol";
import "../interfaces/L0_interfaces.sol";
import "../utils/safeCaller.sol";
import "../delivery/delivery.sol";
import "../utils/errors.sol";


contract Wrapper {
    using safeCaller for bytes;
    // implementation contract of a standard Htoken
    IHtoken immutable HTOKEN;
    // local chain id 
    uint16 immutable CHAIN_ID;
    // the local delivery contract 
    Delivery immutable DELIVERY;
    //map from nativeToken -> chainId = Htoken . in loacal chain. 
    mapping(address => mapping(uint16 => address)) tokenToH;
    // map from Htoken to it's info (native token , native chain)
    mapping(address Htoken => HTinfo) HtokenInfo;


    constructor(address _HtokenImpl, uint16 _chainId, address _delivery) {
        HTOKEN = IHtoken(_HtokenImpl);
        CHAIN_ID = _chainId;
        DELIVERY = Delivery(_delivery);
    }
    /**
     * @dev wrap only a native token in the local chain, holds the native token and mint to the user Htokens
     * @notice rebasing tokens and token with fee on transfer may cause lose of funds 
     * @notice it should be only one Htoken for each native token. 
     * @param token the native token to be wrapped 
     * @param amount the amount of native token to be wrapped .
     * @param to the receipient of Htoken .
     */
    function wrap(address token, uint256 amount, address to) public returns (uint256) {
        if (HtokenInfo[token].nativeChain != 0) revert tokenAlreadyWrapped(HtokenInfo[token]);
        // take the tokens from the user :
        uint balanceWarrperBefore = IHtoken(token).balanceOf(address(this));
        bytes memory _transaferFromParams =
            abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), amount);
        (bool success,) = _transaferFromParams.safeExternalCall(0, 0, token, 0);//no risk for tokens that do not revert on fail.
        if (!success) revert FailedToTransferFrom(msg.sender);
        address Htoken = tokenToH[token][CHAIN_ID];
        if (Htoken == address(0)) {
            (string memory name, string memory symbol) = _setHtokenMetadata(token);
            Htoken = _clone(token, CHAIN_ID, name, symbol, IHtoken(token).decimals()); // deploy an Htoken for this new token.
        }
        uint totalSupply = IHtoken(Htoken).totalSupply();
        // mint the user the token :
        IHtoken(Htoken).mint(to, amount);
        _checkInvariant(token,Htoken,balanceWarrperBefore, totalSupply);
        return amount;
    }
    /**
     * @dev unwrap a Htoke to get the native token.called will get the same amount of Native token.
     * @param token the Htoken to be unwrapped to 
     * @param amount the amount of Htoken to unwrapped
     * @param to the receipient address of native token
     * @notice only can unwrap a token in it's native chain. 
     */
    function unwrap(address token, uint256 amount, address to) public returns (uint256) {
        address Htoken = tokenToH[token][CHAIN_ID];// the token could be in other chains... 
        if (Htoken == address(0)) revert NoNativeToken();
        uint totalSupply = IHtoken(Htoken).totalSupply();
        IHtoken(Htoken).transferFrom(msg.sender, address(this), amount);
        uint256 tokenAmt = IHtoken(Htoken).burn(address(this), IERC20(Htoken).balanceOf(address(this)));
        // send token to the caller :
        bytes memory _transferParams = abi.encodeWithSignature("transfer(address,uint256)", to, tokenAmt);
        uint balanceBefore = IHtoken(token).balanceOf(address(this));
        (bool success,) = _transferParams.safeExternalCall(0, 0, token, 0);
        if (!success) revert FailedToTransferTokens();
        if (balanceBefore - IHtoken(token).balanceOf(address(this)) > totalSupply -IHtoken(Htoken).totalSupply() ) revert BrokenInvariant("token amount sent greater then burned Htoken amount");
        return tokenAmt;
    }

    /**
     * @dev called by the delivery contract to clone a non existing Htoken in this chain, of a native token in forgein chain
     * @param nativeToken the native token to be cloned
     * @param nativeChainId the native chainId of the token to be cloned
     * @param name name of Htoken in src chain 
     * @param symbol symbol of Htoken in src chain
     * @param decimals decimals of Htoken(same as native token) in src chain
     * @return the address of the cloned token. Htoken.
     */
    function clone(address nativeToken, uint16 nativeChainId, string memory name, string memory symbol, uint8 decimals)
        external
        returns (address)
    {   
        if (msg.sender != address(DELIVERY)) revert OnlyValidDelivery();
        if (tokenToH[nativeToken][nativeChainId] != address(0)) return tokenToH[nativeToken][nativeChainId] ;
        if (nativeChainId == CHAIN_ID) revert ChainIdCantBeLocal("only wrapper can clone native ");
        address HT = _clone(nativeToken, nativeChainId, name, symbol, decimals);
        return HT;
    }

    /////////////////////// view function /////////////////////////
    function getHtokenInfo(address Htoken) public view returns (HTinfo memory info) {
        return HtokenInfo[Htoken];
    }
    function getHtoken(address token, uint16 chainId) public view returns(address) {
        return tokenToH[token][chainId];
    }

    function HtokenImplementation() external view returns(address){
        return address(HTOKEN);
    }

    function delivery() external view returns(address){
        return address(DELIVERY);
    }

    ////////////////////// internal function /////////////////////////////

    /**
     * @dev create a clone of a native token and whitelist the new htoken 
     */
    function _clone(address token, uint16 chainId, string memory name, string memory symbol, uint8 decimals)
        internal
        returns (address)
    {
        address Hclone;
        bytes20 addr = bytes20(address(HTOKEN));
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), addr)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            Hclone := create(0, clone, 0x37)
        }
        if (Hclone == address(0)) revert failedToCreateClone();
        IHtoken(Hclone).inialize(address(DELIVERY), token, address(this), chainId, name, symbol, decimals);
        if (IHtoken(Hclone).INITIALIZED() != 1) revert FailedToInitializeClone();
        // whitelist the token in the dilevery contract :
        DELIVERY.whiteList(Hclone,chainId,token);
        // store the new Htoken : 
         tokenToH[token][chainId] = Hclone;
        HtokenInfo[Hclone] = HTinfo(token, chainId);
        return Hclone;
    }

    function _setHtokenMetadata(address token) internal view returns (string memory name, string memory symbol) {
        name = string.concat("Hawk ", IHtoken(token).name());
        symbol = string.concat("h", IHtoken(token).symbol());
    }

    /**
     * @dev check that the given native token by the user is greater of equal the minted Htoken.
     * @param token the native token.
     * @param Htoken the cloned Htoken for the given native token. 
     * @param ts total supply of Htoken before wrapping
     * @param balB balance of address(this) before wrapping
     */
    function _checkInvariant(address token, address Htoken,uint ts,uint balB) internal view {
        if (IERC20(token).balanceOf(address(this))- balB< IERC20(Htoken).totalSupply() -ts) {
            revert BrokenInvariant("total supply greater then wrapper balance");
        }
    }
}
