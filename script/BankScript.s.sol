// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Script, console2 } from "../lib/forge-std/src/Script.sol";
import { BankAccounts } from "../src/BankAccounts.sol";
import { YieldToken } from "../src/YieldToken.sol";

contract BankScript is Script {

    string public constant NAME = "Crypto Bank Token";
    string public constant SYMBOL = "$CBT";

    BankAccounts public bankAccount;
    YieldToken public yieldToken;

    address public owner = makeAddr("OWNER");

    // function setUp() public {}

    function run() public returns(BankAccounts) {
        vm.startBroadcast(owner);

        yieldToken = new YieldToken(NAME, SYMBOL, owner);

        vm.stopBroadcast();

       address yieldTokenAddress = address(yieldToken);

        vm.startBroadcast(owner);

        
        bankAccount = new BankAccounts(owner, yieldTokenAddress);

        vm.stopBroadcast();

        address bankAccountAddress = address(bankAccount);

        vm.prank(owner);
        yieldToken.transferOwnership(bankAccountAddress);

        return bankAccount;
    }
}
