// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";

import "@mangrovedao/hardhat-test-solidity/test.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../TellerV2MarketForwarder.sol";
import "../TellerV2Context.sol";
import { Testable } from "./Testable.sol";
import { LenderCommitmentForwarder } from "../LenderCommitmentForwarder.sol";


import {
    Collateral,
    CollateralType
} from "../interfaces/escrow/ICollateralEscrowV1.sol";
 
import { User } from "./Test_Helpers.sol";

import "../mock/MarketRegistryMock.sol";
 

 /* 
 add tests for each token type 

 add test for conversion of collateral type -- simple 

 */

contract LenderCommitmentForwarder_Test is Testable, LenderCommitmentForwarder {
    LenderCommitmentForwarderTest_TellerV2Mock private tellerV2Mock;
    MarketRegistryMock mockMarketRegistry;

    LenderCommitmentUser private marketOwner;
    LenderCommitmentUser private lender;
    LenderCommitmentUser private borrower;

    address tokenAddress;
    uint256 marketId;
    uint256 maxAmount;

    address collateralTokenAddress;
    uint256 maxPrincipalPerCollateralAmount;
    CommitmentCollateralType collateralTokenType;
    uint256 collateralTokenId;

    uint32 maxLoanDuration;
    uint16 minInterestRate;
    uint32 expiration;

    bool acceptBidWasCalled;
    bool submitBidWasCalled;
    bool submitBidWithCollateralWasCalled;
    uint256 requiredCollateralAmount;

    constructor()
        LenderCommitmentForwarder(
            address(new LenderCommitmentForwarderTest_TellerV2Mock()), ///_protocolAddress
            address(new MarketRegistryMock(address(0)))
        )
    {}

    function setup_beforeAll() public {
        tellerV2Mock = LenderCommitmentForwarderTest_TellerV2Mock(
            address(getTellerV2())
        );
        mockMarketRegistry = MarketRegistryMock(address(getMarketRegistry()));

        marketOwner = new LenderCommitmentUser(address(tellerV2Mock), (this));
        borrower = new LenderCommitmentUser(address(tellerV2Mock), (this));
        lender = new LenderCommitmentUser(address(tellerV2Mock), (this));
        tellerV2Mock.__setMarketOwner(marketOwner);

        mockMarketRegistry.setMarketOwner(address(marketOwner));

        tokenAddress = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
        marketId = 2;
        maxAmount = 100000000000000000000;
        maxLoanDuration = 2480000;
        minInterestRate = 3000;
        expiration = uint32(block.timestamp) + uint32(64000);

        collateralTokenAddress = address(
            0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174
        );
        maxPrincipalPerCollateralAmount = 1 * PRINCIPAL_PER_COLLATERAL_EXPANSION_FACTOR;
        collateralTokenType = CommitmentCollateralType.ERC20;

        marketOwner.setTrustedMarketForwarder(marketId, address(this));
        lender.approveMarketForwarder(marketId, address(this));

        delete acceptBidWasCalled;
        delete submitBidWasCalled;
        delete submitBidWithCollateralWasCalled;
        delete requiredCollateralAmount;

        delete commitmentCount;
    }

    function updateCommitment_before() public {


        Commitment memory _commitment = Commitment({

            marketId:marketId,
            principalTokenAddress: tokenAddress,
            maxPrincipal: maxAmount,
            collateralTokenAddress: collateralTokenAddress,
            collateralTokenId: collateralTokenId,
            maxPrincipalPerCollateralAmount: maxPrincipalPerCollateralAmount,
            collateralTokenType: collateralTokenType,
            maxDuration: maxLoanDuration,
            minInterestRate: minInterestRate,
            expiration: expiration,
            borrower: address(0),
            lender: address(lender)

        });


        uint256 commitmentId = lender._createCommitment(
            _commitment
        );
 
    }

    function updateCommitment_test() public {
        uint256 commitmentId = 0;

        Commitment memory existingCommitment = lenderMarketCommitments[
            commitmentId
        ];

        Test.eq(
            address(lender),
            existingCommitment.lender,
            "Not the owner of created commitment"
        );

        lender._updateCommitment(
            commitmentId,
            existingCommitment
        );
    }


     function deleteCommitment_before() public {


        Commitment memory _commitment = Commitment({

            marketId:marketId,
            principalTokenAddress: tokenAddress,
            maxPrincipal: maxAmount,
            collateralTokenAddress: collateralTokenAddress,
            collateralTokenId: collateralTokenId,
            maxPrincipalPerCollateralAmount: maxPrincipalPerCollateralAmount,
            collateralTokenType: collateralTokenType,
            maxDuration: maxLoanDuration,
            minInterestRate: minInterestRate,
            expiration: expiration,
            borrower: address(0),
            lender: address(lender)

        });

        uint256 commitmentId = lender._createCommitment(
         _commitment
        );
 
    }

    function deleteCommitment_test() public {

         uint256 commitmentId = 0;

        
        Test.eq(
            lenderMarketCommitments[commitmentId].lender,
            address(lender), 
            "Not the owner of created commitment"
        );

        lender._deleteCommitment(commitmentId);

        
        Test.eq(
            lenderMarketCommitments[commitmentId].lender,
            address(0),
            "The commitment was not deleted"
        );
       
    }




    function acceptCommitment_before() public {
        
        Commitment memory _commitment = Commitment({

            marketId:marketId,
            principalTokenAddress: tokenAddress,
            maxPrincipal: maxAmount,
            collateralTokenAddress: collateralTokenAddress,
            collateralTokenId: collateralTokenId,
            maxPrincipalPerCollateralAmount: maxPrincipalPerCollateralAmount,
            collateralTokenType: collateralTokenType,
            maxDuration: maxLoanDuration,
            minInterestRate: minInterestRate,
            expiration: expiration,
            borrower: address(0),
            lender: address(lender)

        });

        lender._createCommitment(
          _commitment
        );
    }

    function acceptCommitment_test() public {
        uint256 commitmentId = 0;

        Commitment storage commitment = lenderMarketCommitments[commitmentId];

        Test.eq(
            acceptBidWasCalled,
            false,
            "Expect accept bid not called before exercise"
        );

        uint256 bidId = marketOwner._acceptCommitment(
            commitmentId,
          
            maxAmount - 100, //principal 
            maxAmount, //collateralAmount
            0  //collateralTokenId
            
        );

        Test.eq(
            acceptBidWasCalled,
            true,
            "Expect accept bid called after exercise"
        );

        Test.eq(
            commitment.maxPrincipal == 100,
            true,
            "Commitment max principal was not decremented"
        );

        bidId = marketOwner._acceptCommitment(
            commitmentId,
          
            100, //principalAmount
            100, //collateralAmount
            0  //collateralTokenId
            
        );
 

        Test.eq(commitment.maxPrincipal == 0, true, "commitment not accepted");

        bool acceptCommitTwiceFails;

        try marketOwner._acceptCommitment(
            commitmentId,
         
            100, //principalAmount
            100, //collateralAmount
            0  //collateralTokenId
             
             ){

        }catch{
                acceptCommitTwiceFails = true;
        }

        Test.eq(acceptCommitTwiceFails, true, "Should fail when accepting commit twice");

    
    }

    function acceptCommitmentFailsWithInsufficientCollateral_test() public {
            
         Commitment memory _commitment = Commitment({

            marketId:marketId,
            principalTokenAddress: tokenAddress,
            maxPrincipal: maxAmount,
            collateralTokenAddress: collateralTokenAddress,
            collateralTokenId: collateralTokenId,
            maxPrincipalPerCollateralAmount: maxPrincipalPerCollateralAmount,
            collateralTokenType: collateralTokenType,
            maxDuration: maxLoanDuration,
            minInterestRate: minInterestRate,
            expiration: expiration,
            borrower: address(0),
            lender: address(lender)

        });

        lender._createCommitment(
          _commitment
        );

        uint256 commitmentId = 0;

        Commitment storage commitment = lenderMarketCommitments[commitmentId];

        requiredCollateralAmount = maxAmount + 1;

        bool failedToAcceptCommitment; 

        try marketOwner._acceptCommitment(
            commitmentId,
            
            maxAmount - 100, //principal 
            maxAmount, //collateralAmount
            0  //collateralTokenId
            
        ) {

        }catch{
            failedToAcceptCommitment = true;           
        }

        Test.eq(
            failedToAcceptCommitment,
            true,
            "Should fail to accept commitment with insufficient collateral"
        );

       
 
     }




    function decrementCommitment_test() public {

           Commitment memory _commitment = Commitment({

            marketId:marketId,
            principalTokenAddress: tokenAddress,
            maxPrincipal: maxAmount,
            collateralTokenAddress: collateralTokenAddress,
            collateralTokenId: collateralTokenId,
            maxPrincipalPerCollateralAmount: maxPrincipalPerCollateralAmount,
            collateralTokenType: collateralTokenType,
            maxDuration: maxLoanDuration,
            minInterestRate: minInterestRate,
            expiration: expiration,
            borrower: address(0),
            lender: address(lender)

        });


        lender._createCommitment(
           _commitment
        );


        uint256 commitmentId = 0;
        uint256 _decrementAmount = 22;

        Commitment storage commitment = lenderMarketCommitments[commitmentId];

      
        _decrementCommitment(
            commitmentId,
            _decrementAmount
        );

       

        Test.eq(
            commitment.maxPrincipal == maxAmount - _decrementAmount,
            true,
            "Commitment max principal was not decremented"
        );

        
       
    
    }





    function getRequiredCollateral_test() public {

        //For each 1 ETH collateral, can withdraw loan of 2000 USDC
        Test.eq(
            super.getRequiredCollateral(2 * 10**9,5 * 10**8 * PRINCIPAL_PER_COLLATERAL_EXPANSION_FACTOR),
            10**18, //requires 1 ETH 
            "Unexpected result for getRequiredCollateral"
        );

       
        //For each 2000 usdc collateral, can withdraw loan of 1 eth
        Test.eq(
            super.getRequiredCollateral(10**18,2 * 10**7),
            2 * 10**9, //requires 2000 USDC 
            "Unexpected result for getRequiredCollateral"
        );

       //For each 2000 usdc collateral, can withdraw loan of 1 eth -- smallest possible loan is 10**10 wei principal 
         Test.eq(
            super.getRequiredCollateral(10**10,2 * 10**7),
            2 * 10**1,  
            "Unexpected result for getRequiredCollateral"
        );

    }

    /*
        Overrider methods for exercise 
    */

    function _submitBid(CreateLoanArgs memory, address)
        internal
        override
        returns (uint256 bidId)
    {
        submitBidWasCalled = true;
        return 1;
    }

    function _submitBidWithCollateral(
        CreateLoanArgs memory,
        Collateral[] memory,
        address
    ) internal override returns (uint256 bidId) {
        submitBidWithCollateralWasCalled = true;
        return 1;
    }

    function _acceptBid(uint256, address) internal override returns (bool) {
        acceptBidWasCalled = true;

        Test.eq(
            submitBidWithCollateralWasCalled,
            true,
            "Submit bid must be called before accept bid"
        );

        return true;
    }


    function getRequiredCollateral(uint256, uint256) public view override returns (uint256) {
        
        return requiredCollateralAmount;
    }
}

contract LenderCommitmentUser is User {
    LenderCommitmentForwarder public immutable commitmentForwarder;

    constructor(
        address _tellerV2,
        LenderCommitmentForwarder _commitmentForwarder
    ) User(_tellerV2) {
        commitmentForwarder = _commitmentForwarder;
    }

     

    function _createCommitment(
         LenderCommitmentForwarder.Commitment calldata _commitment
    ) public returns (uint256) {
        return
            commitmentForwarder.createCommitment(
              _commitment
            );
    }

    function _updateCommitment(
        uint256 commitmentId,
        LenderCommitmentForwarder.Commitment calldata _commitment
    ) public {
        commitmentForwarder.updateCommitment(
            commitmentId,
            _commitment
        );
    }

    function _acceptCommitment(
        uint256 commitmentId,   
        uint256 principal,
        uint256 collateralAmount,
        uint256 collateralTokenId  
    ) public returns (uint256) {
        return
            commitmentForwarder.acceptCommitment(
                commitmentId,  
                principal,
                collateralAmount,
                collateralTokenId  
            );
    }

    function _deleteCommitment(
        uint256 _commitmentId
    ) public {
        commitmentForwarder.deleteCommitment(_commitmentId);
                
    }
}

//Move to a helper file !
contract LenderCommitmentForwarderTest_TellerV2Mock is TellerV2Context {
    constructor() TellerV2Context(address(0)) {}

    function __setMarketOwner(User _marketOwner) external {
        marketRegistry = IMarketRegistry(
            address(new MarketRegistryMock(address(_marketOwner)))
        );
    }

    function getSenderForMarket(uint256 _marketId)
        external
        view
        returns (address)
    {
        return _msgSenderForMarket(_marketId);
    }

    function getDataForMarket(uint256 _marketId)
        external
        view
        returns (bytes calldata)
    {
        return _msgDataForMarket(_marketId);
    }
}

 