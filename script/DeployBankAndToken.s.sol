// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Script, console2 } from "../lib/forge-std/src/Script.sol";
import { BankAccounts } from "../src/BankAccounts.sol";
import { YieldToken } from "../src/YieldToken.sol";

contract DeployBankAndToken is Script {

    string public constant NAME = "K2 Crypto Bank Token";
    string public constant SYMBOL = "$K2CBT";

    BankAccounts public bankAccount;
    YieldToken public yieldToken;


    address public owner = 0xca067E20db2cDEF80D1c7130e5B71C42c0305529;
    // function setUp() public {}

    function run() public returns(BankAccounts, YieldToken) {
        vm.startBroadcast(owner);

        yieldToken = new YieldToken(NAME, SYMBOL, owner);
        console2.log("YieldToken deployed at:", address(yieldToken));

        bankAccount = new BankAccounts(owner, address(yieldToken));
        console2.log("BankAccounts deployed at:", address(bankAccount));

        yieldToken.transferOwnership(address(bankAccount));
        console2.log("Ownership successfully transferred to the Bank!");

        vm.stopBroadcast();

        return (bankAccount, yieldToken);
    }
}
