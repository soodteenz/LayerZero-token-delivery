// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

import "./IERC20.sol";
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 * each Htoken sould store the source id, where the native token is stored
 * each Htoken sould store the address of the warper contract ,
 * each Htoken should store it's router contract. the router will be deployed in all chains . and only the router can send
 *  messages on behalf of the
 * if the token get sent a chain where the token doesn't have a trusted address, the receiver contract should
 */

interface IHtoken is IERC20 {
    function mint(address to, uint256 amount) external returns (uint256);
    function burn(address from, uint256 amount) external returns (uint256);
    function inialize(
        address delivery,
        address token,
        address warpper,
        uint16 chainId,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) external;

    function INITIALIZED() external view returns (uint8);
}
