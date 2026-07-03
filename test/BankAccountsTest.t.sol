// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console2} from "../lib/forge-std/src/Test.sol";
import {BankAccounts} from "../src/BankAccounts.sol";
import {BankScript} from "../script/BankScript.s.sol";

contract BankAccountsTest is Test {

    ///////// Constants for testing /////////

    uint256 public constant AMOUNT_FOR_USER = 10 ether;

    ///////// Users /////////
    address user1 = makeAddr("USER1");
    address user2 = makeAddr("USER2");

    ///////// contract for testing /////////

    BankAccounts public bankAccounts;

    function setUp() public {
        BankScript deployer = new BankScript();
        bankAccounts = deployer.run();
        vm.deal(user1, AMOUNT_FOR_USER);
        vm.deal(user2, AMOUNT_FOR_USER);
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
