# Diamond Proxy Template for Foundry
## Description
This is a reference implementation for EIP-2535 Diamonds by [Nick Mudge](www.github.com/mudgen) translated for use in foundry . To learn about other implementations go here: https://github.com/mudgen/diamond

Note: The loupe functions in DiamondLoupeFacet.sol MUST be added to a diamond and are required by the EIP-2535 Diamonds standard.

Note: In this implementation the loupe functions are NOT gas optimized. The facets, facetFunctionSelectors, facetAddresses loupe functions are not meant to be called on-chain and may use too much gas or run out of gas when called in on-chain transactions. In this implementation these functions should be called by off-chain software like websites and Javascript libraries etc., where gas costs do not matter.

## Dependencies
   - Install [foundry](https://book.getfoundry.sh)
   - Install [string-utils](https://github.com/Arachnid/solidity-stringutils)
   - Install [solhint](https://github.com/protofire/solhint)

## Installation Instructions
  - clone the repo 
    ```bash
       $ git clone https://www.github.com/ArcStreetCapital/Diamond-Foundry.git
    ```
  - install all of the dependencies via 
    ```bash
       $ forge install
    ```
## Testing
  To run all of the tests use the command
  ```bash
     $ forge test --ffi --match-path test/DiamondTests.t.sol
  ```
## Deployment
To deploy diamond with standard facets, create .env, start anvil and use command
  ```bash
     $ forge script script/deployDiamond.s.sol:DeployScript --fork-url http://localhost:8545 --broadcast --ffi
  ```
Or deploy to testnet, for example
  ```bash
     $ forge script script/deployDiamond.s.sol:DeployScript --rpc-url $GOERLI_RPC_URL --broadcast --verify -vvvv --ffi

  ```
## Contributing
  Feel free to create issues and contribute by cloning the repo and adding your changes
  to your own branch. 

## Authors
- 👤 Nick Mudge: <nick@perfectabstractions.com>, Github: [mudgen](https://www.github.com/mudgen)
- 👤 Timo Neumann: <timo@fyde.fi>, Github: [Teamo0](https://www.github.com/Teamo0)
- 👤 Rohan Sundar: <rohan@fyde.fi>, Github: [rsundar](https://www.github.com/rsundar)
