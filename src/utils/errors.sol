//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

struct HTinfo {
    address nativeToken;
    uint16 nativeChain;
}

error OnlyWrapper();
error InvalidTokenToWhiteList();
error PayloadExceedsSizeLimit();
error NotValidDistanation();
error NotValidDelivery();
error OnlyWhiteListedTokens();
error InsufficientNativeFee(uint256 FeeRquired);
error NoZroToken();
error FailedToTransferFrom(address from);
error FeeOnTransaferTokensNotAccepted();
error NoNativeToken();
error FailedToTransferTokens();
error FailedToInitializeClone();
error failedToCreateClone();
error BrokenInvariant(string Err);
error ChainIdCantBeLocal(string reason);
error OnlyValidDelivery();
error tokenAlreadyWrapped(HTinfo HtokenInfo );
error TokenExist();
error OnlyLocalTokens(HTinfo Htoken_info);
error NoFailedMsg();
error FailedToMint();
