// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import "forge-std//StdJson.sol";
import "../src/delivery/delivery.sol";
import "../src/wrapper/wrapper.sol";
import "../src/Htoken/Htoken.sol";

contract deploy is Script {
    // deploy the contract on : sepolia , arbi , bsc
    // get the rpc :
    using stdJson for string;
    function setUp() public {}

    // run this script once for each network . 
    function run() public {
        // get the current network name and chain id (chainId of layerzero not the real one, it's stored on json file) 
        (string memory network,uint16 chainid,string memory json) = _getNetwork();

        address endpoint = vm.parseJsonAddress(json, string.concat(".testnet.", network, ".endpoint"));
        
        // start broadcasting .. 
        vm.startBroadcast();
            // deploy delivery contracts : 
            Delivery delivery = new Delivery(endpoint,chainid);
            // deploy Htoken implemantation: 
            Htoken token = new Htoken();
            // deploy Wrapper contract  : 
            Wrapper wrapper = new Wrapper(address(token),chainid,address(delivery));
            console2.log(network);
            string memory deliv = string.concat(".testnet.",network,".delivery");
            string memory wrap = string.concat(".testnet.",network,".wrapper");
            console2.log(deliv,"\n",wrap);
            vm.writeJson(vm.toString(address(delivery)),"./L0_refrences/refrences.json",deliv);
             vm.writeJson(vm.toString(address(wrapper)),"./L0_refrences/refrences.json",wrap);
            vm.stopBroadcast();
              
    }

    string[] networks = ["sepolia","arbitrum","mumbai","optimism"];
    // after full deployment ... run this one time for each network (chain);

    // @todo : set gas limit ....
    function gaslimitConfig() public {

    }
    function config() public {
        vm.startBroadcast();
        (string memory network,uint chainid,string memory json) = _getNetwork();
        // set wrapper : 
        address wrapper = vm.parseJsonAddress(json,string.concat(".testnet.",network,".wrapper"));
        address delivery = vm.parseJsonAddress(json,string.concat(".testnet.",network,".delivery"));
        Delivery(delivery).setWraper(wrapper);
        for(uint i; i< 4;i++){
            // loop through all chains and config all  all deliveries in all chains 
            uint16 chainId = uint16(vm.parseJsonUint(json,string.concat(".testnet.",networks[i],".chainId")));
            if (chainId == chainid) continue; // skip when the chain id is local .. 
            address remoteDelivery;
            try  vm.parseJsonAddress(json,string.concat(".testnet.",networks[i],".delivery")) returns(address add){
               remoteDelivery = add;
            }catch{continue;}
            // skip if now delivery address deployed in this network .
            Delivery(delivery).addRemoteAddress(chainId,remoteDelivery);
        }
    }
    address chainLink  = 0xd14838A68E8AFBAdE5efb411d5871ea0011AFd28;

    function wrapAndSend() public {
        // wrap chain link token :
        vm.startBroadcast();
        (string memory network,uint16 chainid,string memory json) = _getNetwork();
        // set wrapper : 
        address wrapper = vm.parseJsonAddress(json,string.concat(".testnet.",network,".wrapper"));
        uint bal = Htoken(chainLink).balanceOf(msg.sender);// this will be my address . 
        Htoken(chainLink).approve(address(wrapper),bal);
        Wrapper(wrapper).wrap(chainLink,bal,msg.sender);
        address htoken = Wrapper(wrapper).getHtoken(chainLink,chainid);
        // catch the balance before : 
        console2.log("balance in arbitrum before: ",Htoken(htoken).balanceOf(msg.sender));
        // estimate fee : 
        (uint fee,) = Htoken(htoken).estimateTransferFee(false,10161,msg.sender,bal/2);//sepolia chain id : 10161
        // send a cross chain transfer : 
        Htoken(htoken).send{value:fee}(10161,msg.sender,bal/2,false);
        console2.log("balance in arbitrum after: ",Htoken(htoken).balanceOf(msg.sender));

    }

    //////////////////// helper functions ////////////////////////// 

    function _getNetwork() internal view returns(string memory network,uint16 chainid,string memory json){
         uint _chainId;
        assembly {
            _chainId := chainid()
        }
        if (_chainId == 32337) network = "local_host";
        else if (_chainId == 11155111) network = "sepolia";
        else if (_chainId == 420) network = "optimism";
        else if (_chainId == 421613) network = "arbitrum";
        else if (_chainId == 80001) network = "mumbai";

        json = vm.readFile("./L0_refrences/refrences.json");
        chainid = uint16(vm.parseJsonUint(json,string.concat(".testnet.",network,".chainId")));
    }
   
}


