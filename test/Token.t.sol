// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {Test, console} from "forge-std/Test.sol";
import {Token} from "../src/Token.sol";
import {DeployToken} from "../script/DeployToken.s.sol";


contract TokenTest is Test {
    Token token;

    address public constant USER_ONE = address(1);
    address public constant USER_TWO = address(2);
    address public constant USER_THREE = address(3);

    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    uint256 public constant VALUE_TO_MINT = 1e18;

    error Token_NotOwner();

    function setUp() public {
        DeployToken deployer = new DeployToken();
        token = deployer.run();
        vm.deal(USER_ONE, STARTING_USER_BALANCE);
        vm.deal(USER_TWO, STARTING_USER_BALANCE);
        console.log("Owner at deployment", token.owner());
    }

     // _mint
    function testOnlyOwnerCanMintFail() public {
        vm.expectRevert();
        vm.startPrank(USER_ONE);
        token._mint(USER_TWO, STARTING_USER_BALANCE);
    }

    function testOnlyOwnerCanMintPass() public {
        vm.startPrank(token.owner());
        token._mint(USER_TWO, STARTING_USER_BALANCE);
        console.log("USER_TWO token balance", token.balanceOf(USER_TWO));
        assertEq(token.balanceOf(USER_TWO), STARTING_USER_BALANCE);
    }

    function testCanNotmintToZroAddress() public {
        vm.startPrank(token.owner());
        vm.expectRevert();
        token._mint(address(0), STARTING_USER_BALANCE);
    }

    //transfer
    function testTransfer() public {
        vm.startPrank(token.owner());
        console.log("Before transfer balances");
        token._mint(USER_ONE, VALUE_TO_MINT);
        console.log("Balacne User One", token.balanceOf(USER_ONE));
        console.log("balance User Two", token.balanceOf(USER_TWO));
        uint256 value = token.balanceOf(USER_ONE);
        vm.stopPrank();
        vm.startPrank(USER_ONE);
        token.transfer(USER_TWO, value);
        console.log("After transfer balances");
        console.log("Balacne User One", token.balanceOf(USER_ONE));
        console.log("balance User Two", token.balanceOf(USER_TWO));

        assertEq(value, token.balanceOf(USER_TWO));
    }

    function testCanNotTranferToZeroAddress() public {
        vm.startPrank(token.owner());
        token._mint(USER_ONE, VALUE_TO_MINT);
        console.log("Before transfer balances");
        uint256 value = token.balanceOf(USER_ONE);
        console.log("Balacne User One", value);
        vm.stopPrank();
        vm.startPrank(USER_ONE);
        vm.expectRevert();
        token.transfer(address(0), value);
    }

   
    function testApprove() public {
        vm.startPrank(token.owner());
        token._mint(USER_ONE, VALUE_TO_MINT);
        console.log("Balance of User One", token.balanceOf(USER_ONE));
        uint256 allowance = 1e18;
        vm.startPrank(USER_ONE);
        token.approve(USER_TWO, allowance);
        assertEq(token.allowance(USER_ONE, USER_TWO), allowance);
    }

    
    //transferFrom
    function testTransferFrom() public {
        vm.startPrank(token.owner());
        token._mint(USER_ONE, VALUE_TO_MINT);
        console.log("Balance of User one", token.balanceOf(USER_ONE));
        vm.stopPrank();
        uint256 allowance = 1e18;
        vm.startPrank(USER_ONE);
        token.approve(USER_TWO, allowance);
        vm.stopPrank();
        vm.startPrank(USER_TWO);
        console.log(
            "Before transfer balance of USER_THREE",
            token.balanceOf(USER_THREE)
        );
        token.transferFrom(USER_ONE, USER_THREE, allowance);
        console.log(
            "After transfer balance of USER_THREE",
            token.balanceOf(USER_THREE)
        );
        assertEq(token.balanceOf(USER_THREE), allowance);
    }

      //burn
    function testBurn() public {
        vm.startPrank(token.owner());
        token._mint(USER_ONE, VALUE_TO_MINT);
        vm.stopPrank();
        console.log("Before Burn");
        uint256 userOneBalanceBeforeBurn = token.balanceOf(USER_ONE);
        uint256 totalSupplyBeforeBurn = token.s_totalSupply();
        console.log("userOneBalanceBeforeBurn", userOneBalanceBeforeBurn);
        console.log("totalSupplyBeforeBurn", totalSupplyBeforeBurn);
        vm.startPrank(USER_ONE);
        token.burn(userOneBalanceBeforeBurn);

        console.log("After Burn");
        uint256 userOneBalanceAfterBurn = token.balanceOf(USER_ONE);
        uint256 totalSupplyAfterBurn = token.s_totalSupply();
        console.log("userOneBalanceAfterBurn", userOneBalanceAfterBurn);
        console.log("totalSupplyAfterBurn", totalSupplyAfterBurn);
        assertEq(totalSupplyAfterBurn, 0);
        assertEq(userOneBalanceAfterBurn, 0);
    }

    function testBurnZeroFunds() public {
        vm.startPrank(token.owner());
        token._mint(USER_ONE, VALUE_TO_MINT);
        vm.startPrank(USER_ONE);
        vm.expectRevert(bytes("You can't burn zero funds"));
        token.burn(0);
    }

    function testBurnMoreThanBalance() public {
        vm.startPrank(token.owner());
        token._mint(USER_ONE, VALUE_TO_MINT);
        vm.startPrank(USER_ONE);
        uint256 valueBurn = VALUE_TO_MINT + 1e19;
        vm.expectRevert(bytes("You don't have enough balance!!"));
        token.burn(valueBurn);
    }

    //mintForSale
    function testMintForSaleFail()public{
        vm.expectRevert();
       address sale = makeAddr("sale");
       vm.startPrank(USER_ONE);
       token.mintForSale(sale);
    }

    function testMintForSaleZeroAddressFail()public{
          vm.startPrank(token.owner());
        address sale = address(0);
        vm.expectRevert();
        token.mintForSale(sale);

    }

    function testMintForSalePass()public{
        vm.startPrank(token.owner());
        address sale = makeAddr("sale");
        token.mintForSale(sale);
        assertEq(token.balanceOf(sale),token.s_AllocationForForSale());
    }

    //mintForLiquidityAndReserve
    function testMintForLiquidityAndReserveFail() public {
        vm.expectRevert();
        address LiquidityAndReserve = address(7);
        vm.startPrank(USER_ONE); // should revert here
        token.mintForLiquidityAndReserve(LiquidityAndReserve);
    }

     function testMintForLiquidityAndReserveZeroAddressFail()public{
          vm.startPrank(token.owner());
        address liquidity = address(0);
        vm.expectRevert();
        token.mintForLiquidityAndReserve(liquidity);

    }

    function testMintForLiquidityAndReservePass() public {
        vm.startPrank(token.owner());
        address LiquidityAndReserve = address(7);
        token.mintForLiquidityAndReserve(LiquidityAndReserve);
        assertEq(
            token.balanceOf(LiquidityAndReserve),
            token.s_AllocationForForLiquidityAndReserve()
        );
    }

    // mintForPartnershipAndAcquisition
    function testMintForPartnershipAndAcquisitionFail() public {
        vm.expectRevert();
        address PartnershipAndAcquisition = address(8); //any random address
        vm.startPrank(USER_ONE); // should revert here
        token.mintForPartnershipAndAcquisition(PartnershipAndAcquisition);
    }

      function testMintForPartnershipAndAcquisitionZeroAddressFail()public{
          vm.startPrank(token.owner());
        address partnershipAndAcquisition = address(0);
        vm.expectRevert();
        token.mintForPartnershipAndAcquisition(partnershipAndAcquisition);

    }

    function testMintForPartnershipAndAcquisitionPass() public {
        vm.startPrank(token.owner());
        address PartnershipAndAcquisition = address(8);
        token.mintForPartnershipAndAcquisition(PartnershipAndAcquisition);
        assertEq(
            token.balanceOf(PartnershipAndAcquisition),
            token.s_AllocationForPartnershipAndAcquisition()
        );
    }

    //owneshipTransfer
    function testtransferOwnershipFail() public {
        vm.expectRevert();
        address newOwner = USER_TWO;
        token.transferOwnership(newOwner);
        console.log("new owner", token.owner());
    }

      function testtransferOwnershipZeroAddressFail() public {
        vm.startPrank(token.owner());
        address newOwner = address(0);
        vm.expectRevert();
        token.transferOwnership(newOwner);
    }

    function testtransferOwnershipTrue() public {
        vm.startPrank(token.owner());
        address newOwner = USER_TWO;
        token.transferOwnership(newOwner);
        assertEq(token.owner(), USER_TWO);
    }


    // Allocations
    function testAllocations() public {
        uint8  decimal = token.decimals();
        uint256 Expected_Allocation_For_Sale = 210_000_000 * 10**uint256(decimal);
        uint256 Expected_Allocation_For_RewardsAndDistribution = 590_000_000 * 10**uint256(decimal);
        uint256 Expected_Allocation_For_TeamTokens = 100_000_000 * 10**uint256(decimal);
        uint256 Expected_Allocation_For_LiquidityAndReserve = 60_000_000 * 10**uint256(decimal);
        uint256 Expected_Allocation_For_PartnershipAndAcquisition = 40_000_000 * 10**uint256(decimal);

       uint256 Actual_Allocation_For_Sale = token.s_AllocationForForSale();
       uint256 Actual_Allocation_For_RewardsAndDistribution = token.s_AllocationRewardsAndDistribution();
       uint256 Actual_Allocation_For_TeamTokens = token.s_AllocationForTeamTokens();
       uint256 Actual_Allocation_For_LiquidityAndReserve = token.s_AllocationForForLiquidityAndReserve();
       uint256 Actual_Allocation_For_PartnershipAndAcquisition = token.s_AllocationForPartnershipAndAcquisition();

    assertEq(Expected_Allocation_For_Sale,Actual_Allocation_For_Sale);
    assertEq(Expected_Allocation_For_RewardsAndDistribution,Actual_Allocation_For_RewardsAndDistribution);
    assertEq(Expected_Allocation_For_TeamTokens,Actual_Allocation_For_TeamTokens);
    assertEq(Expected_Allocation_For_LiquidityAndReserve,Actual_Allocation_For_LiquidityAndReserve);
    assertEq(Expected_Allocation_For_PartnershipAndAcquisition,Actual_Allocation_For_PartnershipAndAcquisition);
    
    }
}
