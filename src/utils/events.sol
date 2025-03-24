//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
interface Events{
event Sending(address indexed token,uint16 indexed dstChain,address from , address to,uint amount);
event Received(address indexed nativeToken,uint16 indexed nativeChain,address localHToken);
event StoredPayload(uint16 indexed srcChain,uint64 nonce,bytes32 payloadHash);
event ReversePayload(uint16 indexed srcChain,bytes32 payloadHash );
event Initialized(address indexed nativeToken, address indexed Htoken);}