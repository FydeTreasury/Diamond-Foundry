// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "forge-std/Test.sol";
import "./mocks/MockV3Aggregator.sol";

import "../../src/Governance/Box.sol";
import "../../src/Governance/GovernorContract.sol";
import "../../src/Governance/GovernorTimeLock.sol";

import "../../src/Governance/GovernorAlpha.sol";
import "../../src/Governance/GovernorAlphaTimelock.sol";

import "../../src/interfaces/ITokenPool.sol";
import "../../src/TokenPool.sol";
import "../../src/Proxies/VoteProxyERC20Votes.sol";
import "../../src/Proxies/VoteProxyFactory.sol";
import "../../src/Proxies/VoteProxyRegistry.sol";

import "../../src/Tokens/Aave.sol";
import "../../src/Tokens/Uni.sol";
import "../../src/Tokens/FakeToken.sol";
import "../../src/Tokens/TreasuryToken.sol";

/*
 ________  _________  ________  _________  _______   ________      
|\   ____\|\___   ___\\   __  \|\___   ___\\  ___ \ |\   ____\     
\ \  \___|\|___ \  \_\ \  \|\  \|___ \  \_\ \   __/|\ \  \___|_    
 \ \_____  \   \ \  \ \ \   __  \   \ \  \ \ \  \_|/_\ \_____  \   
  \|____|\  \   \ \  \ \ \  \ \  \   \ \  \ \ \  \_|\ \|____|\  \  
    ____\_\  \   \ \__\ \ \__\ \__\   \ \__\ \ \_______\____\_\  \ 
   |\_________\   \|__|  \|__|\|__|    \|__|  \|_______|\_________\
   \|_________|                                        \|_________|                                
*/

/// @title ZeroState represent the initial state where all the contracts are deployed.
abstract contract ZeroState is Test {
    // initialise contracts
    Box box;
    Box boxAlpha;
    GovernorContract governorContract;
    GovernanceTimeLock governorTimelock;
    GovernorAlpha governorAlpha;
    GovernorAlphaTimelock timeLockAlpha;

    VoteProxyERC20Votes voteProxyERC20;
    VoteProxyFactory voteProxyFactory;
    VoteProxyRegistry voteProxyRegistry;
    TokenPool tokenPool;
    
    AAVE aaveToken;
    Uni uniToken;
    FakeToken fakeToken;
    TreasuryToken treasuryToken;

    MockV3Aggregator mockAavePriceFeed;
    MockV3Aggregator mockUniPriceFeed;

    // deployer and users
    address public deployer = vm.addr(1);
    address public user1 = vm.addr(2);
    address public user2 = vm.addr(3);

    // variables needed for governance deployment
    uint256 public quorumPercentage = 1;
    uint256 public votingPeriod = 5; // 5 blocks
    uint256 public votingDelay = 4;
    uint256 public minDelay = 1;
    address[] public emptyArray;

    // pricefeed needed for token pool
    address public priceFeedAave = 0x547a514d5e3769680Ce22B2361c10Ea13619e8a9;
    address public priceFeedUni = 0x553303d460EE0afB37EdFf9bE42922D8FF63220e;

    uint8 public DECIMALS = 8;
    int256 public mockAavePrice = 80_00000000; // 80 dollars
    int256 public mockUniPrice = 6_00000000; // 6 dollars 

    // forked environment variables
    uint256 public mainnetFork;
    uint256 public mainnetForkBlock = 15_000_000;


    function setUp() public virtual {
        vm.label(deployer, "Deployer");
        vm.label(user1, "User 1");
        vm.label(user2, "User 2");
        
        // optional block number passed so RPC responses are cached
        // speeds up future test runs
        // mainnetFork = vm.createSelectFork(vm.rpcUrl("mainnet"), mainnetForkBlock);

        // rolls block number back 15. This allows blocks to be moved 
        // later to be at different stages of the proposal lifecycle
        // (only important in forked environments)  
        // vm.rollFork(block.number - 20); 
        vm.roll(100);

        
        vm.startPrank(deployer);
        // deploy tokens 
        aaveToken = new AAVE();
        uniToken = new Uni();
        fakeToken = new FakeToken();
        treasuryToken = new TreasuryToken();

        //deploy mocks
        mockAavePriceFeed = new MockV3Aggregator(DECIMALS, mockAavePrice);
        mockUniPriceFeed = new MockV3Aggregator(DECIMALS, mockUniPrice);

        // Deploy voting contracts
        governorTimelock = new GovernanceTimeLock(
            minDelay,
            emptyArray,
            emptyArray,
            address(0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf)
        );
        governorContract = new GovernorContract(
            aaveToken,
            governorTimelock,
            quorumPercentage,
            votingPeriod,
            votingDelay
        );

        // Deploy Governor Alpha Voting
        timeLockAlpha = new GovernorAlphaTimelock(deployer, 2 days); // 2 days
        governorAlpha = new GovernorAlpha(address(timeLockAlpha), address(uniToken), address(uniToken));

        // contract we want to be governed (value in box will change after voting)
        box = new Box();
        boxAlpha = new Box();
        
        // settings roles for governance contract
        governorTimelock.grantRole(
            governorTimelock.PROPOSER_ROLE(),
            address(governorContract)
        );
        governorTimelock.grantRole(
            governorTimelock.EXECUTOR_ROLE(),
            address(0)
        );
        governorTimelock.revokeRole(
            governorTimelock.TIMELOCK_ADMIN_ROLE(),
            deployer
        );

        // give ownership to timelock (allows timelock to execute functions)
        box.transferOwnership(address(governorTimelock));
        boxAlpha.transferOwnership(address(timeLockAlpha));

        // Deploy proxy factory and token pools
        voteProxyRegistry = new VoteProxyRegistry();
        voteProxyFactory = new VoteProxyFactory(address(treasuryToken), address(voteProxyRegistry));
        tokenPool = new TokenPool(
            address(treasuryToken),
            address(voteProxyFactory),
            address(voteProxyRegistry)
        );

        // add the factory address to the vote registry
        voteProxyRegistry.addFactory(address(voteProxyFactory));
        voteProxyRegistry.addGovernor(address(aaveToken), address(governorContract));
        voteProxyRegistry.addGovernor(address(uniToken), address(governorAlpha));

        
        // add allowed tokens and sets their pricefeed
        tokenPool.addAllowedTokens(address(aaveToken), address(mockAavePriceFeed));
        tokenPool.addAllowedTokens(address(uniToken), address(mockUniPriceFeed));

        // give token pool majority of treasury token
        treasuryToken.transfer(address(tokenPool), (treasuryToken.totalSupply() - 200e18)); // leave tokens for testing
        
        // give each user some governance tokens
        aaveToken.transfer(user1, 30e18);
        uniToken.transfer(user1, 30e18);
        aaveToken.transfer(user2, 45e18);
        uniToken.transfer(user2, 45e18);

        vm.stopPrank();


        /// =================================================
        ///                  Foundry Config
        /// =================================================

        // all labels 
        vm.label(address(aaveToken), "AAVE");
        vm.label(address(uniToken), "UNI");
        vm.label(address(fakeToken), "FT");
        vm.label(address(treasuryToken), "TSRY");
        vm.label(address(governorTimelock), "Govenor TimeLock");
        vm.label(address(governorContract), "Governor Contract");
        vm.label(address(box), "Box Contract");
        vm.label(address(voteProxyFactory), "Vote Proxy Factory");
        vm.label(address(tokenPool), "Token Pool");
        vm.label(address(voteProxyRegistry), "Vote Proxy Registry");
        vm.label(address(timeLockAlpha), "Govenor Alpha TimeLock");
        vm.label(address(governorAlpha), "Governor Alpha Contract");

        // makes constant persist accross rolling fork
        vm.makePersistent(address(governorContract));
        vm.makePersistent(address(aaveToken));
        vm.makePersistent(address(uniToken));
        vm.makePersistent(address(voteProxyRegistry));
        vm.makePersistent(address(voteProxyFactory));
        vm.makePersistent(address(treasuryToken));
        vm.makePersistent(address(tokenPool));
        vm.makePersistent(address(timeLockAlpha));
        vm.makePersistent(address(governorAlpha));
        vm.makePersistent(address(box));
        vm.makePersistent(address(boxAlpha));
        
    }
}

/// @title depositGovernance - state when a user initially deposits his GT in the token pool.
abstract contract depositGovernance is ZeroState {


    function setUp() public virtual override {
        super.setUp();
        // simulate users depositing into token pool
        vm.startPrank(user1);
        aaveToken.approve(address(tokenPool), 100e18);
        tokenPool.stakeToEarn(30e18, address(aaveToken));
        vm.stopPrank();
        vm.startPrank(user2);
        uniToken.approve(address(tokenPool), 100e18);
        tokenPool.stakeToEarn(45e18, address(uniToken));
        vm.stopPrank();
    }
}

/// @title IndicateVoteState - state when user indicates he would like to vote on the proposal.
abstract contract IndicateVoteState is depositGovernance {

    using stdStorage for StdStorage;

    string public proposalDescription = "Proposal #1: Store 5 in the Box!";
    uint256 public newStoreValue = 5;
    bytes[] public encodedFunction;
    address[] public targets;
    uint256[] public values;
    uint public proposalId;

    uint public proposalIdAlpha;
    bytes[] public encodedFunctionAlpha;
    address[] public targetsAlpha;
    uint256[] public valuesAlpha;
    string[] public functionSig;
    
    
    VoteProxyERC20Votes public proxyOpenZeppelin;
    VoteProxyERC20Votes public proxyGovernorAlpha;


    function setUp() public virtual override {
        super.setUp();
        
        vm.startPrank(deployer);
        // proposal for normal governor 
        targets.push(address(box));
        values.push(newStoreValue);
        encodedFunction.push(abi.encodePacked("store(uint256)"));  
        proposalId = governorContract.propose(
            targets,
            values,
            encodedFunction,
            proposalDescription
        );

        // proposal for governor Alpha 
        targetsAlpha.push(address(boxAlpha));
        valuesAlpha.push(5);
        encodedFunctionAlpha.push(abi.encodePacked("store(uint256)")); 
        functionSig.push(string(abi.encodeWithSignature("store(uint256)")));
        proposalIdAlpha = governorAlpha.propose(
            targetsAlpha, 
            valuesAlpha, 
            functionSig,
            encodedFunctionAlpha, 
            proposalDescription);
        vm.stopPrank();

        vm.prank(user1);

        // openzeppelin voting proxy
        address proxy1 = voteProxyFactory.createERC20VotesProxy(
            address(aaveToken),
            address(tokenPool),
            false 
        );
        proxyOpenZeppelin = VoteProxyERC20Votes(proxy1);
        
        // governor alpha voting proxy
        vm.prank(user2);
        address proxy2 = voteProxyFactory.createERC20VotesProxy(
            address(uniToken),
            address(tokenPool),
            true
        );
        proxyGovernorAlpha = VoteProxyERC20Votes(proxy2);
        vm.label(address(proxyOpenZeppelin), "Proxy User 1");
        vm.label(address(proxyGovernorAlpha), "Proxy User 2");

        vm.makePersistent(address(proxyOpenZeppelin));
        vm.makePersistent(address(proxyGovernorAlpha));
    }
}

/// @title voteOnProposal - state when user votes on proposal.
abstract contract voteOnProposal is IndicateVoteState {

    uint votingAmountTsryUser1 = 30e18;
    uint votingAmountTsryUser2 = 10e18;
    uint tsryPrice = 10; // 10$
    
    function setUp() public virtual override {
        super.setUp();
        vm.startPrank(user1);
        treasuryToken.approve(address(proxyOpenZeppelin), 100e18);
        proxyOpenZeppelin.fundMe(votingAmountTsryUser1, proposalId, tsryPrice);
        vm.stopPrank();
        vm.startPrank(user2);
        treasuryToken.approve(address(proxyGovernorAlpha), 100e18);
        proxyGovernorAlpha.fundMe(votingAmountTsryUser2, proposalIdAlpha, tsryPrice);
        vm.stopPrank();
        // vm.rollFork(block.number + votingDelay + 1); // roll to when proposal is active
        vm.roll(block.number + votingDelay + 1); // roll to when proposal is active
    }
}