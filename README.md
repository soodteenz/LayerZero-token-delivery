![hawk](https://i.pinimg.com/originals/60/d9/8c/60d98cfac2c21a3e94a27503a56843a1.jpg)
# Table of Contents :

- [Table of Contents :](#table-of-contents-)
- [What is an Htoken❓](#what-is-an-htoken)
    - [Key Features:](#key-features)
- [Protocol architecture :](#protocol-architecture-)
- [1. Wrapper contract:](#1-wrapper-contract)
  - [1. key Functions :](#1-key-functions-)
    - [1.1. Wrap Function:](#11-wrap-function)
    - [1.2. clone Function (Restricted to Delivery Contract):](#12-clone-function-restricted-to-delivery-contract)
    - [1.3. unWrap Function:](#13-unwrap-function)
  - [2. key points :](#2-key-points-)
- [2. Htoken contract :](#2-htoken-contract-)
  - [1. key Functions:](#1-key-functions)
    - [1.1. Send Function:](#11-send-function)
    - [1.2. estimateTransferFee Function:](#12-estimatetransferfee-function)
    - [1.3. SendFrom Function:](#13-sendfrom-function)
  - [2. key points :](#2-key-points--1)
- [3. Delivery Contract:](#3-delivery-contract)
  - [1. Functions:](#1-functions)
    - [1.1. Send Function:](#11-send-function-1)
    - [1.2. lzReceive Function:](#12-lzreceive-function)
    - [1.3. reversePayload Function:](#13-reversepayload-function)
    - [1.4. whiteList Function:](#14-whitelist-function)
  - [3. Key Points:](#3-key-points)
  - [run tests :](#run-tests-)
  - [deployment :](#deployment-)
    - [Setup :](#setup-)
    - [deploy :](#deploy-)

# What is an [Htoken](./src/Htoken/Htoken.sol)❓

**Htoken**, short for Hawk Token, represents a revolutionary leap in decentralized finance (DeFi), offering token holders unparalleled cross-chain mobility and advanced functionalities.

At its core, an [Htokens](./src/Htoken/Htoken.sol) is a transformed version of any existing token, referred to as the **native token** Leveraging cutting-edge `layerzero` messaging technology, [Htokens](./src/Htoken/Htoken.sol) introduces a seamless and efficient cross-chain transfer mechanism. With just one transaction, [Htokens](./src/Htoken/Htoken.sol) holders can navigate across different blockchain ecosystems.

### Key Features:

1.  **Cross-Chain Transfer:**

- [Htokens](./src/Htoken/Htoken.sol) harnesses `layerzero` messaging technology to simplify and expedite cross-chain transfers.

2.  **Wrap and Unwrap Mechanism:**

- to transfor a `native token` into an [Htokens](./src/Htoken/Htoken.sol) you should [wrap](./src/wrapper/wrapper.sol) it.
- by wrapping the native token the user will get the same wrapped amount of the Corresponding [Htokens](./src/Htoken/Htoken.sol).
- if there is no corresponding [Htokens](./src/Htoken/Htoken.sol) for this native token. the [wrap](./src/wrapper/wrapper.sol) contract will create one, and mint to the user the Equivalent amount being wrapped .
- Conversely, [Htokens](./src/Htoken/Htoken.sol) holders can [unwrap](./src/wrapper/wrapper.sol) their tokens, converting them back to their native form. This unwrapping process is limited to the native chain where the original token contract resides.

3.  **Full ERC-20 Compatibility:**

- [Htokens](./src/Htoken/Htoken.sol) is designed with full compatibility with the ERC-20 standard. making it easy to integrate into existing DeFi applications and platforms.
- Additionally, [Htokens](./src/Htoken/Htoken.sol) incorporates specialized functions to facilitate cross-chain transfers.

# Protocol architecture :

# 1. [Wrapper](./src/wrapper/wrapper.sol) contract:

- The [Wrapper](./src/wrapper/wrapper.sol) serves as a pivotal component of the protocol, orchestrating the seamless wrapping and unwrapping of native tokens to and from their corresponding [Htokens](./src/Htoken/Htoken.sol) forms.
- The contract facilitates the creation of [Htokens](./src/Htoken/Htoken.sol) when the token being wrapped no exist yet.
- the [Wrapper](./src/wrapper/wrapper.sol) contract will hold the native tokens.

## 1. key Functions :

### 1.1. [Wrap](./src/wrapper/wrapper.sol#L38) Function:

Users initiate the wrapping process by calling the `wrap` function, specifying the native token they wish to convert into an [Htokens](./src/Htoken/Htoken.sol), along with the desired amount. Prior to wrapping, users must approve the [Wrapper](./src/wrapper/wrapper.sol) Contract to spend the specified amount of the native token. Upon receiving approval, the [Wrapper](./src/wrapper/wrapper.sol) Contract performs the following steps:

- Checks for the existence of an [Htokens](./src/Htoken/Htoken.sol) associated with the specified native token.
  - `If an  [Htokens](./src/Htoken/Htoken.sol) exists`, mints an equivalent amount of [Htokens](./src/Htoken/Htoken.sol)s to the user.
  - `If an  [Htokens](./src/Htoken/Htoken.sol) doesn't exists`, creates a new [Htokens](./src/Htoken/Htoken.sol) and registering it with the native token. Only one [Htokens](./src/Htoken/Htoken.sol) can be created per native token. Assigns metadata to the newly created [Htokens](./src/Htoken/Htoken.sol), naming it with an `h` prefix before the native token `symbol` and `hawk` before `name`. For instance, if the native token is named "Circle USD" with the symbol "USDC," the [Htokens](./src/Htoken/Htoken.sol) is named "hawk Circle USD" with the symbol "hUSDC.", mints an equivalent amount of [Htokens](./src/Htoken/Htoken.sol)s to the user.
  ```solidity
    function wrap(address token, uint256 amount, address to) public returns (uint256) {
          if (HtokenInfo[token].nativeChain != 0) revert tokenAlreadyWrapped(HtokenInfo[token]);
          // take the tokens from the user :
          uint balanceWarrperBefore = IHtoken(token).balanceOf(address(this));
          bytes memory _transaferFromParams =
              abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), amount);
          (bool success,) = _transaferFromParams.safeExternalCall(0, 0, token, 0);//no risk for tokens that do not revert on fail.
          if (!success) revert FailedToTransferFrom(msg.sender);
          address [Htokens](./src/Htoken/Htoken.sol) = tokenToH[token][CHAIN_ID];
          if (Htoken == address(0)) {
              (string memory name, string memory symbol) = _setHtokenMetadata(token);
              [Htokens](./src/Htoken/Htoken.sol) = _clone(token, CHAIN_ID, name, symbol, IHtoken(token).decimals()); // deploy an [Htokens](./src/Htoken/Htoken.sol) for this new token.
          }
          uint totalSupply = IHtoken(Htoken).totalSupply();
          // mint the user the token :
          IHtoken(Htoken).mint(to, amount);
          _checkInvariant(token,Htoken,balanceWarrperBefore, totalSupply);
          return amount;
    }
  ```

### 1.2. [clone](./src/wrapper/wrapper.sol#L88) Function (Restricted to Delivery Contract):

- when an [Htokens](./src/Htoken/Htoken.sol) get sent to a another chain where there is not corresponding [Htokens](./src/Htoken/Htoken.sol) to it in this chain. which happend in the first crosschain transfer for a token to a new chain.the [Htokens](./src/Htoken/Htoken.sol) will be created , in the disnaction chain via [clone](./src/wrapper/wrapper.sol#L88) function .
- this function is exclusively callable by the [delivery](./src/delivery/delivery.sol) contract, another contract will explore below . This function enables the [delivery](./src/delivery/delivery.sol) contract to create clones of [Htokens](./src/Htoken/Htoken.sol)s when necessary.
  ```solidity
    function clone(address nativeToken, uint16 nativeChainId, string memory name, string memory symbol, uint8 decimals)
        external
        returns (address)
    {
        if (msg.sender != address(DELIVERY)) revert OnlyValidDelivery();
        if (tokenToH[nativeToken][nativeChainId] != address(0)) return tokenToH[nativeToken][nativeChainId] ;
        if (nativeChainId == CHAIN_ID) revert ChainIdCantBeLocal("only [Wrapper](./src/wrapper/wrapper.sol) can clone native ");
        address HT = _clone(nativeToken, nativeChainId, name, symbol, decimals);
        return HT;
    }
  ```
  > `Notice:` The [Wrapper](./src/wrapper/wrapper.sol) Contract is token-agnostic, supporting the wrapping of any ERC-20 token. However, it does not support ERC-20 tokens with fee-on-transfer mechanisms and rebasing tokens. Wrapping these token types may lead to potential user losses.

### 1.3. [unWrap](./src/wrapper/wrapper.sol#L64) Function:

- When [Htokens](./src/Htoken/Htoken.sol) holders wish to retrieve their native tokens, they can call the [unwrap](./src/wrapper/wrapper.sol#L64) function. This process results in the burning of [Htokens](./src/Htoken/Htoken.sol)s and the subsequent transfer of native tokens back to the user.
- This operation must occur on the native chain where the original token contract resides.

```solidity
   function unwrap(address token, uint256 amount, address to) public returns (uint256) {
       address [Htokens](./src/Htoken/Htoken.sol) = tokenToH[token][CHAIN_ID];// the token could be in other chains...
       if (Htoken == address(0)) revert NoNativeToken();
       uint totalSupply = IHtoken(Htoken).totalSupply();
       IHtoken(Htoken).transferFrom(msg.sender, address(this), amount);
       uint256 tokenAmt = IHtoken(Htoken).burn(address(this), IERC20(Htoken).balanceOf(address(this)));
       // send token to the caller :
       bytes memory _transferParams = abi.encodeWithSignature("transfer(address,uint256)", to, tokenAmt);
       uint balanceBefore = IHtoken(token).balanceOf(address(this));
       (bool success,) = _transferParams.safeExternalCall(0, 0, token, 0);
       if (!success) revert FailedToTransferTokens();
       if (balanceBefore - IHtoken(token).balanceOf(address(this)) > totalSupply -IHtoken(Htoken).totalSupply() ) revert BrokenInvariant("token amount sent greater then burned [Htokens](./src/Htoken/Htoken.sol) amount");
       return tokenAmt;
   }
```

## 2. key points :

- The [Wrapper](./src/wrapper/wrapper.sol) contract should be deployed in each supported chain .
- A native token should have only one [Htokens](./src/Htoken/Htoken.sol).
- the [Wrapper](./src/wrapper/wrapper.sol) contract balance of a native token should be equal or greater then the crosschains supply of the Corresponding [Htokens](./src/Htoken/Htoken.sol).

# 2. [Htoken](./src/Htoken/Htoken.sol) contract :

- introduces enhanced ERC-20 functionalities with additional functions for cross-chain transfers, providing users with a powerful mechanism to send and receive tokens seamlessly across different blockchain networks.

## 1. key Functions:

### 1.1. [Send](./src/Htoken/Htoken.sol#L67) Function:

- The `send` function is like `transfer` function of `erc20` but only for crosschain transfer,it allows users to send and amount of [Htokens](./src/Htoken/Htoken.sol) to an address located on a different chain.

```solidity
  function send(uint16 chainId, address to, uint256 amount, bool _payInZro) external payable {
       // burn token from user :
       _burn(_msgSender(), amount);
       _crossChainTransfer(chainId, to, amount, _payInZro);
       emit Sending(address(this),chainId,msg.sender,to,amount);
   }
```

- To facilitate the cross-chain transfer, users must include a certain amount of native tokens (ETH or the native token of the local chain) as fees. The fee is crucial for covering gas costs in the distination chain. If the provided fee is insufficient, the call will revert; if it exceeds the required amount, users will receive a refund of the surplus.

### 1.2. [estimateTransferFee](./src/Htoken/Htoken.sol#L114) Function:

- To determine the required fee for a cross-chain send, users can utilize the [estimateTransferFee](./src/Htoken/Htoken.sol#L114) function. This function provides an estimate of the native token fee needed for a successful cross-chain transfer, depending on the local chain's native token. The parameters include:

- **Pay in ZRO (Zero Utility Token):** A boolean indicating whether the fee should be paid in the protocol's utility token (ZRO).
- **Destination ChainId:** The unique identifier of the destination blockchain.
- **To Address:** The recipient's address on the destination chain.
- **Amount:** The quantity of [Htokens](./src/Htoken/Htoken.sol)s to be sent.

```solidity
  function estimateTransferFee(bool payInZro, uint16 chainId, address to, uint256 amount)
        public
        view
        returns (uint256 native, uint256 zro)
    {
        bytes memory _functionArgs = abi.encodeWithSelector(this.mint.selector, to, amount);
        _functionArgs = _encode(_functionArgs);
        (native, zro) = DELIVERY.estimateFees(chainId, _functionArgs, payInZro);
    }
```

### 1.3. [SendFrom](./src/Htoken/Htoken.sol#L74) Function:

- Similar to the `send` function, `sendFrom` allows a designated spender to initiate cross-chain transfer like `transferFrom` function of `erc20` but for crosschain transfers. The spender must be approved to spend [Htokens](./src/Htoken/Htoken.sol)s on behalf of the sender through the typical ERC-20 approval process.

```solidity
  function sendFrom(uint16 chainId, address from, address to, uint256 amount, bool _payInZro) external payable {
       burn(from, amount);
       _crossChainTransfer(chainId, to, amount, _payInZro);
       emit Sending(address(this),chainId,from,to,amount);

   }
```

## 2. key points :

- when sending an [Htokens](./src/Htoken/Htoken.sol) to another chain, the [Htokens](./src/Htoken/Htoken.sol) amount to be sent get burned in the source chain, and minted in the distination chain.
- you don't have to worry if the [Htokens](./src/Htoken/Htoken.sol) exist or not in the distination chain. if it doesn't a new one will be deployed.
- for local interaction (in the same chain) [Htokens](./src/Htoken/Htoken.sol) behaves as a normal `ERC20` token.

# 3. [Delivery](./src/delivery/delivery.sol) Contract:

- The **[Delivery](./src/delivery/delivery.sol) Contract** plays a critical role in managing cross-chain communication within the Hawk Token protocol. It handles messages between chains, ensuring the smooth transfer of tokens from one chain to another. and the deployments of [Htokens](./src/Htoken/Htoken.sol) contracts for tokens that do not yet exist in the destination chain.(in the first transfer to a new chain)

## 1. Functions:

### 1.1. [Send](./src/delivery/delivery.sol#L11) Function:

- Initiates the sending process, allowing the Delivery Contract to forward messages to the specified destination chain.
- Callable only by whitelisted [Htokens](./src/Htoken/Htoken.sol)s to ensure security.
  ```solidity
   function Send(uint16 chainId, bytes calldata _payload, address payable _refunde, address _payInZro)
        public
        payable
        onlyWhitelisted
    {
        lzSend(chainId, _payload, _refunde, _payInZro);
    }
  ```

### 1.2. [lzReceive](./src/delivery/delivery.sol#L19) Function:

- Handles the reception of messages from another chain.
- Verifies the validity of the delivery source and processes the payload accordingly.
- If the payload execution fails, stores the payload for potential reversal.

```solidity
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
```

### 1.3. [reversePayload](./src/delivery/delivery.sol#L42) Function:

- when there is a stored payload that's means that the token get burned from _source chain_ but didn't get minted in the distanation.calling this function will reverse a failed tx ,reminting tokens to the user in the source chain again to insure that the user will not lost his tokens if the crosschain transfer fail.

```solidity
  function reversePayload(uint16 _srcChainId,uint64 nonce, bytes calldata _payload,address _payInZro) external payable {
        // check that the payload is stored :
        bytes32 payloadHash = keccak256(_payload);
        if (failedMsg[_srcChainId][nonce] != payloadHash ) revert NoFailedMsg();
        lzSend(_srcChainId,_payload,payable(msg.sender), _payInZro);
        failedMsg[_srcChainId][nonce] == bytes32(0);
        emit ReversePayload(_srcChainId,payloadHash);
    }
```

### 1.4. [whiteList](./src/delivery/delivery.sol#L51) Function:

- Whitelists [Htokens](./src/Htoken/Htoken.sol) contracts, associating them with their native tokens and native chain.
- Automatically whitelists [Htokens](./src/Htoken/Htoken.sol)s created through the [Wrapper](./src/wrapper/wrapper.sol) contract. Only the [Wrapper](./src/wrapper/wrapper.sol) contract can whitelist an [Htokens](./src/Htoken/Htoken.sol).

```solidity
 function whiteList(address [Htokens](./src/Htoken/Htoken.sol),uint16 nativeChain,address nativeToken) public onlyWrapper {
        if (isHToken[htoken] || [Htokens](./src/Htoken/Htoken.sol) == address(0)) revert InvalidTokenToWhiteList();
        isHToken[htoken] = true;
        nativeToLocal[nativeChain][nativeToken] = [Htokens](./src/Htoken/Htoken.sol);
    }
```

## 3. Key Points:

- The [Delivery Contract](./src/delivery/delivery.sol) is responsible for managing cross-chain communication and deploying [Htokens](./src/Htoken/Htoken.sol) contracts in the destination chain where they don't exist yet.
- The `lzReceive` function processes incoming messages and stores failed payloads for potential reversal.
- The `reversePayload` function allows the reversal of failed crosschain action, reminting tokens to users in the source chain that they get burned.
- Whenever an [Htokens](./src/Htoken/Htoken.sol) is created through the [Wrapper](./src/wrapper/wrapper.sol) contract, it automatically gets whitelisted, and only the [Wrapper](./src/wrapper/wrapper.sol) contract can whitelist an [Htokens](./src/Htoken/Htoken.sol).

## run tests :

```sh
 forge test -vvv
```

> `NOTICE` : you have to make sure that [test_addRemoteAddress](./src/delivery/delivery.sol#L109) function uncommented.

## deployment :

### Setup :

- there are three contract that should be deployed in all chains you wanna support.
- the deploment [script](./script/deploy.sol) will deploy and verify the contracts in the running chain. the script is getting the configration and the layerZero endpoint contract in each chain from [refrences.json](./L0_refrences/refrences.json) file.
- before start deployment make sure to :
  - fill .env file (see [.envExample](./.env.example)).
  - store your private key using `cast` under the name of `pk` by running :
    ```sh
    cast wallet import pk --private-key <your private key>
    ```
    this will ask you for a password to encrypt your private key. and you will need to type the password for each transaction broadcast .
  - export the address of the given private key under the name of sender :
    ```sh
      export sender=<address of the given private key>
    ```

### deploy :

now everything is good. let's deploy the contracts to testnets :

- deploy to sepolia :

```sh
 make deploy_sepolia
```

- deploy to mumbai :

```sh
 make deploy_mumbai
```

- deploy to arbitrum :

```sh
  make deploy_arb
```

> if you wanna Simulate the deployment ina fork before actualy deploy it to testnet .. just add `_local` ex :
>
> ```sh
>   make deploy_sepolia_local
> ```

> also make sure you have enough native token for each chain .. for deployment.

- now you have to config the delivery contract in each chain :

  - configurate in sepolia delivery :

    ```sh
      make config_sepolia
    ```

  - configurate mumbai delivery :

    ```sh
    make config_mumbai
    ```

  - configurate arbitrum delivery :

    ```sh
    make config_arb
    ```

- if you have some `chainlink` token Faucet in the sender address you can try to interact with the protocol by running :
  ```sh
    make wrap_and_send
  ```
