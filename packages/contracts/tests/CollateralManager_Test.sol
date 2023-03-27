// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Testable } from "./Testable.sol";

import { CollateralEscrowV1 } from "../contracts/escrow/CollateralEscrowV1.sol";
import "../contracts/mock/WethMock.sol";
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../contracts/interfaces/IWETH.sol";

import "./tokens/TestERC20Token.sol";
import "./tokens/TestERC721Token.sol";
import "./tokens/TestERC1155Token.sol";

import "../contracts/mock/TellerV2SolMock.sol";
import "../contracts/CollateralManager.sol";

import "./CollateralManager_Override.sol";
 
contract CollateralManager_Test is Testable {
    CollateralManager_Override collateralManager;
    User private borrower;
   

    TestERC20Token wethMock;
    TestERC721Token erc721Mock;
    TestERC1155Token erc1155Mock;

    TellerV2_Mock tellerV2Mock;
   

    function setUp() public {
        // Deploy implementation
         // Deploy implementation
        CollateralEscrowV1 escrowImplementation = new CollateralEscrowV1_Mock();
        // Deploy beacon contract with implementation
        UpgradeableBeacon escrowBeacon = new UpgradeableBeacon(
            address(escrowImplementation)
        );

        
        wethMock = new TestERC20Token("wrappedETH", "WETH", 1e24, 18);
        erc721Mock = new TestERC721Token("ERC721", "ERC721");
        erc1155Mock = new TestERC1155Token("ERC1155");

        tellerV2Mock = new TellerV2_Mock();
        borrower = new User( );


        // Deploy escrow
      /*  BeaconProxy proxy_ = new BeaconProxy(
            address(escrowBeacon),
            abi.encodeWithSelector(CollateralEscrowV1.initialize.selector, 0)
        );
        escrow = CollateralEscrowV1Mock(address(proxy_));
    */

      //  uint256 borrowerBalance = 50000;
     //   payable(address(borrower)).transfer(borrowerBalance);

        collateralManager = new CollateralManager_Override();


        collateralManager.initialize(address(escrowBeacon), address(tellerV2Mock) );
    } 


    function test_setCollateralEscrowBeacon(  ) public {
        // Deploy implementation
        CollateralEscrowV1 escrowImplementation = new CollateralEscrowV1_Mock();
        // Deploy beacon contract with implementation
        UpgradeableBeacon escrowBeacon = new UpgradeableBeacon(
            address(escrowImplementation)
        );

        

        collateralManager.setCollateralEscrowBeacon(address(escrowBeacon));
        
        //how to test ?
    }


    function test_isBidCollateralBacked() public {
        
    }



    function test_deposit() public  {
        uint256 bidId = 0 ;
        uint256 amount = 1000;
        wethMock.transfer(address(borrower), amount);

        borrower.approveERC20( address(wethMock), address(collateralManager), amount  );
    

        Collateral memory collateral = Collateral({
            _collateralType: CollateralType.ERC20,
            _amount: amount,
            _tokenId: 0, 
            _collateralAddress: address(wethMock)
        });

        tellerV2Mock.setBorrower(address(borrower));

        collateralManager.mock_deposit(bidId, collateral);

         
    }

    function test_deposit_invalid_bid() public  {
        uint256 bidId = 0 ;
        uint256 amount = 1000;
        wethMock.transfer(address(borrower), amount);
        wethMock.approve(address(collateralManager), amount);

        Collateral memory collateral = Collateral({
            _collateralType: CollateralType.ERC20,
            _amount: amount,
            _tokenId: 0, 
            _collateralAddress: address(wethMock)
        });


        tellerV2Mock.setBorrower(address(0));

        vm.expectRevert("Bid does not exist");
        collateralManager.mock_deposit(bidId, collateral);

         
    }


    function test_deployAndDeposit() public {} 

    function test_withdraw() public {}

    function test_commitCollateral() public {}

    function test_liquidateCollateral() public {}

    function test_getCollateralInfo() public {}

    function test_getCollateralAmount() public {}

    function test_getEscrow() public {}


    function test_onERC721Received() public {} 


    function onERC1155Received() public {} 
    


    function test_checkBalances_empty() public {

        Collateral[] memory collateralArray; 

        (bool valid, bool[] memory checks) = collateralManager.checkBalances(
            address(borrower),
            collateralArray
        );

        assertTrue(valid);
    }

    function test_checkBalances_public() public {

        Collateral[] memory collateralArray = new Collateral[](1); 

        collateralArray[0] = Collateral({
            _collateralType: CollateralType.ERC20,
            _amount: 1000,
            _tokenId: 0, 
            _collateralAddress: address(wethMock)
        });
 
 
        (bool valid, bool[] memory checks) = collateralManager.checkBalances(
            address(borrower),
            collateralArray
        );
 

        assertTrue(collateralManager.checkBalancesWasCalled(), "Check balances was not called");
    }

     function test_checkBalances_internal() public {
    
        
        Collateral[] memory collateralArray = new Collateral[](1); 

        collateralArray[0] = Collateral({
            _collateralType: CollateralType.ERC20,
            _amount: 1000,
            _tokenId: 0, 
            _collateralAddress: address(wethMock)
        });
 
 
        (bool valid, bool[] memory checks) = collateralManager._checkBalancesSuper(
            address(borrower),
            collateralArray,
            true 
        );
 
        assertTrue(collateralManager.checkBalanceWasCalled(), "Check balance was not called");
     }



     function test_checkBalance_internal_insufficient_assets() public {

          Collateral memory collateral =  Collateral({
            _collateralType: CollateralType.ERC20,
            _amount: 1000,
            _tokenId: 0, 
            _collateralAddress: address(wethMock)
        });


        bool valid = collateralManager._checkBalanceSuper(
            address(borrower),
            collateral
        );
 

        //need to inject state 

        assertFalse(valid, "check balance super should be invalid");
     }


     function test_checkBalance_internal_sufficient_assets() public {

          Collateral memory collateral =  Collateral({
            _collateralType: CollateralType.ERC20,
            _amount: 1000,
            _tokenId: 0, 
            _collateralAddress: address(wethMock)
        });


        wethMock.transfer(address(borrower),1000);


        bool valid = collateralManager._checkBalanceSuper(
            address(borrower),
            collateral
        );
 

        //need to inject state 

        assertTrue(valid, "check balance super not valid");
     }


    function test_revalidateCollateral() public {

        Collateral[] memory collateralArray; 

        uint256 bidId = 0;

        bool valid =  collateralManager.revalidateCollateral(
            bidId
        );

        assertTrue(valid);
    }

    function test_commit_collateral_single() public {
        uint256 bidId = 0;

        Collateral memory collateral = Collateral({
            _collateralType: CollateralType.ERC20,
            _amount: 1000,
            _tokenId: 0, 
            _collateralAddress: address(wethMock)
        });

        
        collateralManager.commitCollateral(bidId,collateral);
 

    }

    function test_commit_collateral_array() public {
        uint256 bidId = 0;

        Collateral[] memory collateralArray; 

       
        collateralManager.commitCollateral(bidId, collateralArray);


    }
  
}

contract User {
   

    constructor( ) {
    
       
    }



    function approveERC20(address tokenAddress, address to, uint256 amount) public {
        ERC20(tokenAddress).approve(address(to), amount);
    }




  
/*
    function depositToken(
        
        address _collateralAddress,
        uint256 _amount
       
    ) public {
        escrow.depositToken(
         
            _collateralAddress,
            _amount
           
        );
    }

    function withdraw(
        address _collateralAddress,
        uint256 _amount,
        address _recipient
    ) public {
        escrow.withdraw(_collateralAddress, _amount, _recipient);
    }

    

    function approveERC20(address tokenAddress, uint256 amount) public {
        ERC20(tokenAddress).approve(address(escrow), amount);
    }

     function approveERC721(address tokenAddress,uint256 tokenId) public {
        ERC721(tokenAddress).approve(address(escrow), tokenId);
    }

     function approveERC1155(address tokenAddress) public {
        ERC1155(tokenAddress).setApprovalForAll(address(escrow), true);
    }

    function getBalance(address _collateralAddress)
        public
        returns (uint256 amount_)
    {
        (, amount_, , ) = escrow.collateralBalances(_collateralAddress);
    }
*/
    receive() external payable {}

    //receive 721
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external returns (bytes4) {
        return this.onERC721Received.selector;
    }

    //receive 1155
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external returns (bytes4) {
        return this.onERC1155Received.selector;
    }



}


contract CollateralEscrowV1_Mock is CollateralEscrowV1 {
    constructor() CollateralEscrowV1() {}

    
}

contract TellerV2_Mock is TellerV2SolMock {

    address public globalBorrower;

    constructor() TellerV2SolMock() {}

    function setBorrower(address borrower) public {
        globalBorrower = borrower;
    }

    
    function getLoanBorrower(uint256 bidId) public view override returns (address) {
        return address(globalBorrower);
    }
    
}