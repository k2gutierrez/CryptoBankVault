// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console2} from "../lib/forge-std/src/Test.sol";
import {BankAccounts} from "../src/BankAccounts.sol";
import {BankScript} from "../script/BankScript.s.sol";
import {YieldToken} from "../src/YieldToken.sol";

contract BankAccountsTest is Test {

    ///////// Constants for testing /////////

    uint256 public constant AMOUNT_FOR_USER = 10 ether;
    uint256 public constant YIELD_RATE_DENOMINATOR = 100000;

    ///////// Users /////////
    address user1 = makeAddr("USER1");
    address user2 = makeAddr("USER2");
    address user3 = makeAddr("USER3");

    ///////// contract for testing /////////

    BankAccounts public bankAccounts;

    function setUp() public {
        BankScript deployer = new BankScript();
        bankAccounts = deployer.run();
        vm.deal(user1, AMOUNT_FOR_USER);
        vm.deal(user2, AMOUNT_FOR_USER);
    }

    ////////Only Owner function ////////

    function testSetYieldTokenRevertsNotOwner() external {
        address newYieldTokenAddress = makeAddr("YIELD");

        vm.expectRevert();
        vm.prank(user1);
        bankAccounts.setYieldToken(newYieldTokenAddress);
    }

    function testSetYieldTokenAsOwner() external {
        address lastYieldTokenAddress = bankAccounts.getYeildTokenAddress();
        address newYieldTokenAddress = makeAddr("YIELD");

        vm.prank(bankAccounts.owner());
        bankAccounts.setYieldToken(newYieldTokenAddress);

        address changedYieldTokenAddress = bankAccounts.getYeildTokenAddress();

        assertNotEq(lastYieldTokenAddress, changedYieldTokenAddress);
        assertEq(newYieldTokenAddress, changedYieldTokenAddress);
    }

    //////// Normal functions to use in tests ////////
    function _createSingleAccountAndDeposit(address _user, uint256 _amount) private returns(uint256 id) {
        address[] memory user = new address[](1);
        user[0] = _user;
        vm.startPrank(_user);
        bankAccounts.createAccount(BankAccounts.AccountType.Individual, user);
        id = bankAccounts.getUserAccounts(_user)[0];
        bankAccounts.deposit{value: _amount}(id);
        vm.stopPrank();
    }

    function _createJointAccountAndDeposit(address _user1, address _user2, uint256 _amount) private returns(uint256) {
        address[] memory user = new address[](2);
        user[0] = _user1;
        user[1] = _user2;
        vm.startPrank(_user1);
        bankAccounts.createAccount(BankAccounts.AccountType.Joint, user);
        uint256[] memory id = bankAccounts.getUserAccounts(_user1);
        uint256 jointId;

        for (uint256 i = 0; i < id.length; i++) {
            BankAccounts.Account memory acc = bankAccounts.getAccount(id[i]);
            if (acc.accType == BankAccounts.AccountType.Joint) jointId = id[i];
        }

        bankAccounts.deposit{value: _amount}(jointId);
        vm.stopPrank();

        return jointId;
    }

    //////// create Account function ////////

    function testSingleAccountRevertsInvalidOwnersCount() external {
         address[] memory user = new address[](2);
        user[0] = user2;
        user[1] = user3;

        vm.expectRevert(BankAccounts.BankAccounts__InvalidOwnersCount.selector);
        vm.prank(user2);
        bankAccounts.createAccount(BankAccounts.AccountType.Individual, user);
        
    }

    function testSingleAccountRevertsInvalidOwnersCountMustBeOwnerTheMsgSender() external {
         address[] memory user = new address[](1);
        user[0] = user2;

        vm.expectRevert(BankAccounts.BankAccounts__InvalidOwnersToRegisterMustBeMsgSender.selector);
        vm.prank(user1);
        bankAccounts.createAccount(BankAccounts.AccountType.Individual, user);
        
    }

    function testJointAccountRevertsInvalidOwnersCount() external {
        address[] memory user = new address[](1);
        user[0] = user2;

        vm.expectRevert(BankAccounts.BankAccounts__InvalidOwnersCount.selector);
        vm.prank(user2);
        bankAccounts.createAccount(BankAccounts.AccountType.Joint, user);
        
    }

    function testJointAccountRevertsAddressInJointCannotBeTheSame() external {
         address[] memory user = new address[](2);
        user[0] = user2;
        user[1] = user2;

        vm.expectRevert(BankAccounts.BankAccounts__OwnersCannotBeIdentical.selector);
        vm.prank(user2);
        bankAccounts.createAccount(BankAccounts.AccountType.Joint, user);
        
    }

    function testJointAccountRevertsMsgSenderIsNotOwnerOfAccount() external {
         address[] memory user = new address[](2);
        user[0] = user2;
        user[1] = user3;

        vm.expectRevert("Must be an owner");
        vm.prank(user1);
        bankAccounts.createAccount(BankAccounts.AccountType.Joint, user);
        
    }

    //////// Deposit function ////////

    function testDepositRevertsMsgValueIs0() external {
        uint256 amount = 0;

        address[] memory user = new address[](1);
        user[0] = user1;
        vm.startPrank(user1);
        bankAccounts.createAccount(BankAccounts.AccountType.Individual, user);

        uint256[] memory account = bankAccounts.getUserAccounts(user1);
        vm.expectRevert(BankAccounts.BankAccounts__ZeroDeposit.selector);
        bankAccounts.deposit{value: amount}(account[0]);
        vm.stopPrank();
    }

    function testDepositRevertsAccountIDis0() external {
        uint256 amount = 1e10;

        vm.startPrank(user1);
        vm.expectRevert(BankAccounts.BankAccounts__AccountDoesNotExist.selector);
        bankAccounts.deposit{value: amount}(0);
        vm.stopPrank();
    }

    function testDepositRevertsAccountIsnotCreated() external {
        uint256 amount = 1e10;

        vm.startPrank(user1);
        vm.expectRevert(BankAccounts.BankAccounts__AccountDoesNotExist.selector);
        bankAccounts.deposit{value: amount}(1);
        vm.stopPrank();
    }

    //////// Request Withdrawal function ////////

    function testWithdrawalRequestRevertsAccountDoesNotExists() external {
        uint256 amount = 1e18;
        uint256 id = 1;

        vm.startPrank(user1);
        vm.expectRevert(BankAccounts.BankAccounts__AccountDoesNotExist.selector);
        bankAccounts.requestWithdrawal(id, amount);
        vm.stopPrank();
    }

    function testWithdrawalRequestRevertsAccountInsufficientBalance() external {
        uint256 amount = 1e18;
        uint256 amountToWithdraw = 2e18;
        uint256 id = 1;

        _createSingleAccountAndDeposit(user1, amount);

        vm.startPrank(user1);
        vm.expectRevert(BankAccounts.BankAccounts__InsufficientFunds.selector);
        bankAccounts.requestWithdrawal(id, amountToWithdraw);
        vm.stopPrank();
    }

    function testWithdrawalRequestRevertsAccountNotAnOwner() external {
        uint256 amount = 1e18;
        uint256 amountToWithdraw = 1e9;
        uint256 id = 1;

        _createJointAccountAndDeposit(user1, user2, amount);

        vm.startPrank(user3);
        vm.expectRevert(BankAccounts.BankAccounts__NotAnOwner.selector);
        bankAccounts.requestWithdrawal(id, amountToWithdraw);
        vm.stopPrank();
    }

    //////// approveWithdrawal function ////////

    function testApproveWithdrawalRevertsAccountDoentExists() external {
        vm.expectRevert(BankAccounts.BankAccounts__AccountDoesNotExist.selector);
        vm.prank(user1);
        bankAccounts.approveWithdrawal(1);
    }

    function testApproveWithdrawalRevertsNotAJointAccount() external {
        uint256 amount = 1e18;
        _createSingleAccountAndDeposit(user1, amount);

        vm.expectRevert(BankAccounts.BankAccounts__NotAJointAccount.selector);
        vm.prank(user1);
        bankAccounts.approveWithdrawal(1);
    }

    function testApproveWithdrawalRevertsRequestAmountIsZero() external {
        uint256 amount = 1e18;
        _createJointAccountAndDeposit(user1, user2, amount);

        vm.expectRevert(BankAccounts.BankAccounts__NoPendingRequest.selector);
        vm.prank(user1);
        bankAccounts.approveWithdrawal(1);
    }

    function testApproveWithdrawalRevertsNotOwnerCalling() external {
        uint256 amount = 1e18;
        uint256 accountId = 1;
        _createJointAccountAndDeposit(user1, user2, amount);

        vm.startPrank(user1);
        bankAccounts.requestWithdrawal(accountId, (amount / 2));

        vm.stopPrank();


        vm.startPrank(user3);
        vm.expectRevert(BankAccounts.BankAccounts__NotAnOwner.selector);
        
        bankAccounts.approveWithdrawal(1);

        vm.stopPrank();
    }

    function testApproveWithdrawalRevertsCannotApproveSameAddress() external {
        uint256 amount = 1e18;
        uint256 accountId = 1;
        _createJointAccountAndDeposit(user1, user2, amount);

        vm.startPrank(user1);
        bankAccounts.requestWithdrawal(accountId, (amount / 2));

        vm.stopPrank();


        vm.startPrank(user1);
        vm.expectRevert(BankAccounts.BankAccounts__CannotApproveOwnRequest.selector);
        
        bankAccounts.approveWithdrawal(1);

        vm.stopPrank();
    }

    //////// Yield token function ////////

    function testGettingYieldToken() external {
        YieldToken token = YieldToken(bankAccounts.getYeildTokenAddress());
        uint256 accountId = 1;
        uint256 amount = 2 ether;
        uint256 timeElapsed = block.timestamp + 30 days;

        uint256 userTokensBefore = token.balanceOf(user1);

        _createSingleAccountAndDeposit(user1, amount);
        vm.warp(timeElapsed);

        vm.prank(user1);
        bankAccounts.requestWithdrawal(accountId, (amount/2));

        uint256 userTokensAfter = token.balanceOf(user1);

        assertNotEq(userTokensBefore, userTokensAfter);
        assert(userTokensAfter != 0);

    }

    //////// Getter functions ////////

    function testGetAccount() external {
        uint256 expectedId = 1;
        uint256 amount = .2 ether;
        uint256 time = block.timestamp;
        uint256 id = _createSingleAccountAndDeposit(user1, amount);
        BankAccounts.Account memory account = bankAccounts.getAccount(id);

        assert(account.id == expectedId);
        assert(account.accType == BankAccounts.AccountType.Individual);
        assert(account.owners[0] == user1);
        assert(account.owners.length == 1);
        assert(account.balance == amount);
        assert(account.lastUpdateTime == time);
        assert(account.isActive == true);
    }

    function testGetUserAccounts() external {
        uint256 expectedAccountAmountsForUser1 = 2;
        uint256 amount = .2 ether;
        _createSingleAccountAndDeposit(user1, amount);
        _createJointAccountAndDeposit(user1, user2, amount);
        uint256[] memory accounts = bankAccounts.getUserAccounts(user1);
        
        assert(accounts.length == expectedAccountAmountsForUser1);
        assert(accounts[0] == 1);
        assert(accounts[1] == 2);
    }

    function testGetWithdrawalRequest() external {
        uint256 expectedAccountAmountsForUser1 = 2;
        uint256 amount = 2e18;
        uint256 amountToWithdraw = 1e18;
        _createSingleAccountAndDeposit(user1, amount);
        _createJointAccountAndDeposit(user1, user2, amount);
        uint256[] memory accounts = bankAccounts.getUserAccounts(user1);

        BankAccounts.Account memory accountUser = bankAccounts.getAccount(accounts[1]);

        console2.log("Balance User joint account: ", accountUser.balance);
        
        assert(accounts.length == expectedAccountAmountsForUser1);
        assert(accounts[0] == 1);
        assert(accounts[1] == 2);

        vm.prank(user1);
        bankAccounts.requestWithdrawal(accounts[1], amountToWithdraw);

        BankAccounts.WithdrawalRequest memory withdrawalRequest = bankAccounts.getWithdrawalRequest(accounts[1]);

        assert(withdrawalRequest.amount == amountToWithdraw);
        assert(withdrawalRequest.requester == user1);
        assert(withdrawalRequest.approvedByOther == false);
        assert(withdrawalRequest.isExecuted == false);

    }

    function testGetYeildTokenAddress() external view {
        address tokenAddress = bankAccounts.getYeildTokenAddress();
        assert(tokenAddress != address(0));
    }

    function testGetContractBalance() external {
        uint256 amount = 5 ether;
        uint256 contractBalanceBefore = bankAccounts.getContractBalance();
        
        _createSingleAccountAndDeposit(user1, amount);
        uint256 contractBalanceAfter = bankAccounts.getContractBalance();

        assertNotEq(contractBalanceBefore, contractBalanceAfter);
        assertEq(contractBalanceAfter, amount);
    }

}
