//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {LZEndpointMock}from "../mocks/endpointMock.sol";
import {ERC20} from "../../src/Htoken/ERC20.sol";
import "../../src/delivery/delivery.sol";
import "../../src/Htoken/Htoken.sol";
import "../../src/wrapper/wrapper.sol";
contract token is ERC20 {
    constructor(string memory name ,string memory symbol){
        _name = name;
        _symbol = symbol;
    }

    function decimals() public pure returns(uint8) {
        return 18;
    }
    function mint(address to, uint amount) public {
        _mint(to,amount);
    }

}
contract SetUp is Test {
    LZEndpointMock endpoint1;
    LZEndpointMock endpoint2;
    token token1;
    token token2;
    Htoken htoken;
    Delivery delivery1;
    Delivery delivery2;
    Wrapper wrapper1;
    Wrapper wrapper2; 
    address user1 = makeAddr("bob");
    address user2 = makeAddr("alice");
    address user3 = makeAddr("vika");
    uint16 chainId1;
    uint16 chainId2;
    function setUp() public virtual {
        // set the chainIds 
        chainId1 = 101;
        chainId2 = 102;
        // deploy all the contracts : 
        endpoint1 = new LZEndpointMock(chainId1);
        endpoint2 = new LZEndpointMock(chainId2);
        token1 = new token("token one","T1");
        token2 = new token("token two","T2");
        deployProtocol();
        // mint tokens to users :
        token1.mint(user1,1000000 ether );
        token1.mint(user2,1000000 ether );
        token2.mint(user2,1000000 ether);
        vm.startPrank(user1);
        token1.approve(address(wrapper1),type(uint).max);
        token2.approve(address(wrapper1),type(uint).max);
        token1.approve(address(wrapper2),type(uint).max);
        token2.approve(address(wrapper2),type(uint).max);
        vm.startPrank(user2);
        token1.approve(address(wrapper1),type(uint).max);
        token2.approve(address(wrapper1),type(uint).max);
        token1.approve(address(wrapper2),type(uint).max);
        token2.approve(address(wrapper2),type(uint).max);
        vm.label(address(wrapper1),"wrapper1");
        vm.label(address(wrapper2),"wrapper2");
        vm.label(address(endpoint1),"endpoint1");
        vm.label(address(endpoint2),"endpoint2");
        vm.label(address(token1),"token1");
        vm.label(address(token2),"token2");
        vm.label(address(htoken),"Htoken");



    }
    // deploy the delivery : 
    function deployProtocol () internal {
        // deploy delivery : 
        delivery1 = new Delivery(address(endpoint1),chainId1);
        delivery2 = new Delivery(address(endpoint2),chainId2);
        setDestination(address(delivery1),1);
        setDestination(address(delivery2),2);
        delivery1.setAdapterParams(chainId2,abi.encodePacked(uint16(1),uint(2000000)));
        delivery2.setAdapterParams(chainId1,abi.encodePacked(uint16(1),uint(2000000)));

        // deploy token : 
        htoken = new Htoken();
        // deploy Wrapper :
        wrapper1 = new Wrapper(address(htoken),chainId1,address(delivery1));
        wrapper2 = new Wrapper(address(htoken),chainId2,address(delivery2));
        // set up Wrapper for each delivery : 
        delivery1.setWraper(address(wrapper1));
        delivery2.setWraper(address(wrapper2));
        // set remote delivery addresses .. : 
        delivery1.test_addRemoteAddress(chainId2,address(delivery2));
        delivery2.test_addRemoteAddress(chainId1,address(delivery1));

    }
    // function that sets the destination endpoint in the source enpoint : 
    function setDestination(address sourceAddr , uint8 endpoint) internal  {
        if (endpoint == 1){
            endpoint2.setDestLzEndpoint(sourceAddr,address(endpoint1));
        }else if (endpoint ==2) {
            endpoint1.setDestLzEndpoint(sourceAddr,address(endpoint2));
        }else {
            console.log("ERROR: not valid distination or source address");
            revert();
        }
    }

    function assertEq_string(string memory str1,string memory str2)internal {
        assertEq(keccak256(bytes(str1)) ,keccak256(bytes(str2)),"strings not equal");
    }
}