// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Ownable } from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import { IYieldToken } from "./IYieldToken.sol";

contract BankAccounts is Ownable {

    // --- Custom Errors ---
    error BankAccounts__InvalidOwnersCount();
    error BankAccounts__OwnersCannotBeIdentical();
    error BankAccounts__AccountDoesNotExist();
    error BankAccounts__AccountInactive();
    error BankAccounts__ZeroDeposit();
    error BankAccounts__NotAnOwner();
    error BankAccounts__InsufficientFunds();
    error BankAccounts__NotAJointAccount();
    error BankAccounts__NoPendingRequest();
    error BankAccounts__CannotApproveOwnRequest();

    //////////////// Enum and Structs ////////////////

    enum AccountType {
        Individual,
        Joint
    }

    struct Account {
        uint256 id;
        AccountType accType;
        address[] owners;
        uint256 balance;
        bool isActive;
    }

    struct WithdrawalRequest {
        uint256 amount;
        address requester;
        bool approvedByOther;
        bool isExecuted;
    }

    //////////////// State Variables ////////////////

    IYieldToken public yieldToken;
    uint256 private s_nextAccountId = 1;

    // Mapping from Account ID -> Account Data
    mapping(uint256 accountId => Account accountData) private s_accounts;

    // Mapping to track which accounts belong to a specific user
    mapping(address => uint256[] ) private s_userAccounts;

    // Mapping from Account ID -> Withdrawal Requests (for Joint accounts)
    mapping(uint256 => WithdrawalRequest) private s_withdrawalRequests;

    // --- Events ---
    event AccountCreated(uint256 indexed accountId, AccountType accType, address[] owners);
    event Deposited(uint256 indexed accountId, address indexed sender, uint256 amount);
    event WithdrawalRequested(uint256 indexed accountId, address indexed requester, uint256 amount);
    event WithdrawalExecuted(uint256 indexed accountId, address indexed requester, uint256 amount);

    constructor(address _owner, address _yieldTokenAddress) Ownable(_owner) {
        yieldToken = IYieldToken(_yieldTokenAddress);
    }

    //////////////// Owner function ////////////////

    /**
     * @dev Allows the owner to update the yield token address if needed.
     */
    function setYieldToken(address _newYieldTokenAddress) external onlyOwner {
        yieldToken = IYieldToken(_newYieldTokenAddress);
    }

}