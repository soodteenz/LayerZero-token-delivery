//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./utils/l0_setup.sol";
/*
 local integration test to check the functionlality works as expected ...
 */
contract Interaction is SetUp {
    function test_wrapToken() public {
        uint balanceUser1Before = token1.balanceOf(user1);
        vm.startPrank(user1);
        token1.approve(address(wrapper1),100 ether);
        wrapper1.wrap(address(token1),50 ether,user3);
        // get the htoken info : 
        address htoken1 = wrapper1.getHtoken(address(token1),chainId1);
        // assertion :
        assertEq(Htoken(htoken1).balanceOf(user3) , 50 ether);
        assertEq(token1.balanceOf(address(wrapper1)),50 ether);
        assertEq(token1.balanceOf(user1),balanceUser1Before - 50 ether);
        assertEq(18,Htoken(htoken1).decimals());
        assertEq_string(Htoken(htoken1).name(),"Hawk token one");
        assertEq_string(Htoken(htoken1).symbol(),"HT1");
        // another wraps : 
        vm.stopPrank();
        vm.startPrank(user2);
        token1.approve(address(wrapper1),100 ether);
        wrapper1.wrap(address(token1),100 ether,user1);
        assertEq(100 ether,Htoken(htoken1).balanceOf(user1));
        assertEq(Htoken(htoken1).totalSupply(),150 ether);
        assertEq(token1.balanceOf(address(wrapper1)),150 ether);
    }

    function test_unwrapToken() public {
        // wrap token first .. 
        vm.startPrank(user1);
        wrapper1.wrap(address(token1),1030 ether,user3);
        vm.startPrank(user2);
        wrapper1.wrap(address(token2),2000 ether,user3);
        
        // get Htoken : 
        Htoken  htoken1 = Htoken(wrapper1.getHtoken(address(token1),chainId1));
        Htoken htoken2 = Htoken(wrapper1.getHtoken(address(token2),chainId1));
        assertEq(htoken1.balanceOf(user3),1030 ether);
        assertEq(htoken2.balanceOf(user3),2000 ether);
        assertEq(token1.balanceOf(address(wrapper1)),1030 ether);
        assertEq(token2.balanceOf(address(wrapper1)),2000 ether);
        vm.startPrank(user3);
        uint user3Bal = htoken1.balanceOf(user3);
        //should revert .. 
        vm.expectRevert();
        wrapper1.unwrap(address(token1),user3Bal,user3);
        // approve to avoid revert .. 
        htoken1.approve(address(wrapper1),user3Bal);
        wrapper1.unwrap(address(token1),user3Bal,user3);  
        // assertion : 
        assertEq(token1.balanceOf(address(wrapper1)),0);
        assertEq(token1.balanceOf(user3),1030 ether);
        assertEq(htoken1.balanceOf(user3),0);
        assertEq(htoken1.totalSupply() ,0);
        
    }

    // path chain1 => chain 2
    function test_send() public {
        // wrap token : 
        vm.deal(user1,100 ether);
        vm.startPrank(user1);
        wrapper1.wrap(address(token1),1030 ether,user1);
        Htoken  htoken1 = Htoken(wrapper1.getHtoken(address(token1),chainId1));
        // call estimateTransferFee : 
        (uint nativeFee , uint zroFee) = htoken1.estimateTransferFee(false,chainId2,user3,1000 ether);
        console.log("nativeFee : ",nativeFee);
        assertEq(zroFee,0);
        // send cross chain from user1 transfer to  user3,  
        htoken1.send{value: nativeFee }(chainId2,user3,1000 ether,false);
        Htoken htoken2 = Htoken(wrapper2.getHtoken(address(token1),chainId1));
        uint totalsupply = htoken1.totalSupply() + htoken2.totalSupply();
        uint totalBalance = token1.balanceOf(address(wrapper1));
        // assertion : 
        assertEq_string(htoken2.name(),htoken1.name());
        assertEq_string(htoken2.symbol(),htoken1.symbol());
        assertEq(htoken1.balanceOf(user1),30 ether,"bob change balance not Accurate");
        assertEq(htoken2.balanceOf(user3),1000 ether,"vika balance is not accurate");
        assertEq(totalsupply,totalBalance,"real balance no equal the total supply ");
    }
    
    // path : chain 2 => chain1. 
    function test_sendFrom() public {
        // wrap token : 
        vm.startPrank(user1);
        wrapper2.wrap(address(token1),1000 ether,user1);
        Htoken  htoken1 = Htoken(wrapper2.getHtoken(address(token1),chainId2));
        htoken1.approve(user3,1000 ether);
        (uint nativeFee ,) = htoken1.estimateTransferFee(false,chainId1,user3,999 ether);
        
        vm.deal(user3,nativeFee * 4);
        vm.startPrank(user3);
        htoken1.sendFrom{value: user3.balance}(chainId1,user1,user3,999 ether , false);
        Htoken htoken2 = Htoken(wrapper1.getHtoken(address(token1),chainId2));
        uint totalsupply = htoken1.totalSupply() + htoken2.totalSupply();
        uint totalBalance = token1.balanceOf(address(wrapper2));
         // assertion : 
        assertEq_string(htoken2.name(),htoken1.name());
        assertEq_string(htoken2.symbol(),htoken1.symbol());
        assertEq(user3.balance,nativeFee * 3);
        assertEq(htoken2.balanceOf(user3),999 ether,"dstToken: vika change balance not Accurate");
        assertEq(htoken1.balanceOf(user3),0,"srcToken :  token vika balance is not accurate");
        assertEq(htoken2.balanceOf(user1),0,"dstToken: bob balance is not accurate");
        assertEq(htoken1.balanceOf(user1),1 ether,"srcToken : bob balance is not accurate");
        assertEq(htoken1.allowance(user1,user3),1 ether,"remaining allwance  not accurate");
        assertEq(totalsupply,totalBalance,"real balance no equal the total supply ");
    }

    function test_writeJs() public {
        string memory name  = "kaka";
        vm.writeJson("test1","./L0_refrences/backUp.json",string.concat(".testing.",name,".name"));
        (uint16 chainid,string memory network  )= _getNetwork();
        console.log(network);
        console.log(chainid);
    }

    function _getNetwork() internal view returns(uint16 ,string memory){
        string memory network ;
         uint16 _chainId;
        assembly {
            _chainId := chainid()
        }
        if (_chainId == 32337) network = "local_host";
        else if (_chainId == 11155111) {network = "sepolia";}
        else if (_chainId == 420) network = "optimism";
        else if (_chainId == 421613) network = "arbitrum";
        else if (_chainId == 80001) network = "mumbai";
        else {console.log("network non");}
        console.log("network inside ..",network);
        console.log(_chainId);

       string memory json = vm.readFile("./L0_refrences/refrences.json");
        _chainId = uint16(vm.parseJsonUint(json,string.concat(".testnet.",network,".chainId")));
        return(_chainId,network);
    }
}
