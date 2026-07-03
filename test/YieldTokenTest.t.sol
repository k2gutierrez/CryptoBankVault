// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console2} from "../lib/forge-std/src/Test.sol";
import {BankAccounts} from "../src/BankAccounts.sol";
import {YieldToken} from "../src/YieldToken.sol";

contract YieldTokenTest is Test {

    string public constant NAME = "Test Token";
    string public constant SYMBOL = "TT";
    uint256 public constant AMOUNT_FOR_USER = 10 ether;

    YieldToken token;

    address owner = makeAddr("OWNER");
    address user = makeAddr("USER");

    function setUp() public {
        vm.deal(owner, AMOUNT_FOR_USER);
        vm.deal(user, AMOUNT_FOR_USER);

        vm.startBroadcast(owner);
        token = new YieldToken(NAME, SYMBOL, owner);
        vm.stopBroadcast();

    }

    function testOwnerAddress() external view {
        address tokenOwnerAddress = token.owner();

        assertEq(owner, tokenOwnerAddress);
    }

    function testRevertOnlyOwnerCanMint() external {
        address addressToSendTokens = owner;
        uint256 amountOfTokens = 10e18;

        vm.expectRevert();
        vm.prank(user);
        token.mint(addressToSendTokens, amountOfTokens);
    }

    function testOwnerCanMintToHisWallet() external {

        address addressToSendTokens = owner;
        uint256 amountOfTokens = 10e18;

        uint256 tokenBalanceOwnerBefore = token.balanceOf(owner);

        vm.prank(owner);
        token.mint(addressToSendTokens, amountOfTokens);

        uint256 tokenBalanceOwnerAfter = token.balanceOf(owner);

        assert(tokenBalanceOwnerBefore == 0);
        assert(tokenBalanceOwnerAfter == amountOfTokens);
        assertNotEq(tokenBalanceOwnerBefore, tokenBalanceOwnerAfter);
    }

    function testOwnerCanMintToAnotherWallet() external {

        address addressToSendTokens = user;
        uint256 amountOfTokens = 5e18;

        uint256 tokenBalanceUserBefore = token.balanceOf(user);

        vm.prank(owner);
        token.mint(addressToSendTokens, amountOfTokens);

        uint256 tokenBalanceUserAfter = token.balanceOf(user);

        assert(tokenBalanceUserBefore == 0);
        assert(tokenBalanceUserAfter == amountOfTokens);
        assertNotEq(tokenBalanceUserBefore, tokenBalanceUserAfter);
    }

}