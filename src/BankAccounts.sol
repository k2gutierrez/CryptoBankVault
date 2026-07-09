// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Ownable } from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import { IYieldToken } from "./IYieldToken.sol";

contract BankAccounts is Ownable {

    //////////////// Errors ////////////////
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
    error BankAccounts__InvalidOwnersToRegisterMustBeMsgSender();

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
        uint256 lastUpdateTime;
        bool isActive;
    }

    struct WithdrawalRequest {
        uint256 amount;
        address requester;
        bool approvedByOther;
        bool isExecuted;
    }

    //////////////// Constants ////////////////

    // The larger the denominator, the slower the tokens mint. 
    uint256 private constant YIELD_RATE_DENOMINATOR = 100000;

    //////////////// State Variables ////////////////

    IYieldToken private s_yieldToken;
    uint256 private s_nextAccountId = 1;

    // Mapping from Account ID -> Account Data
    mapping(uint256 accountId => Account accountData) private s_accounts;

    // Mapping to track which accounts belong to a specific user
    mapping(address usersAccount => uint256[] id ) private s_userAccounts;

    // Mapping from Account ID -> Withdrawal Requests (for Joint accounts)
    mapping(uint256 id => WithdrawalRequest) private s_withdrawalRequests;

    // Events
    event AccountCreated(uint256 indexed accountId, AccountType accType, address[] owners);
    event Deposited(uint256 indexed accountId, address indexed sender, uint256 amount);
    event WithdrawalRequested(uint256 indexed accountId, address indexed requester, uint256 amount);
    event WithdrawalExecuted(uint256 indexed accountId, address indexed requester, uint256 amount);

    constructor(address _owner, address _yieldTokenAddress) Ownable(_owner) {
        s_yieldToken = IYieldToken(_yieldTokenAddress);
    }

    //////////////// Owner function ////////////////

    /**
     * @dev Allows the owner to update the yield token address if needed.
     */
    function setYieldToken(address _newYieldTokenAddress) external onlyOwner {
        s_yieldToken = IYieldToken(_newYieldTokenAddress);
    }

    //////////////// External functions ////////////////

    /**
     * @dev Creates a new bank account (Individual or Joint)
     */
    function createAccount(AccountType _type, address[] calldata _owners) external {
        if (_type == AccountType.Individual) {
            if (_owners.length != 1) revert BankAccounts__InvalidOwnersCount();
            if (_owners[0] != msg.sender) revert BankAccounts__InvalidOwnersToRegisterMustBeMsgSender(); // Creator must be the owner
        } else if (_type == AccountType.Joint) {
            if (_owners.length != 2) revert BankAccounts__InvalidOwnersCount();
            if (_owners[0] == _owners[1]) revert BankAccounts__OwnersCannotBeIdentical();
            
            // Validate that the creator is among the owners
            require(_owners[0] == msg.sender || _owners[1] == msg.sender, "Must be an owner");
        }

        uint256 currentId = s_nextAccountId;

        // Save the account data
        s_accounts[currentId] = Account({
            id: currentId,
            accType: _type,
            owners: _owners,
            balance: 0,
            lastUpdateTime: block.timestamp,
            isActive: true
        });

        // Link the account to the users for easy frontend querying
        for (uint i = 0; i < _owners.length; i++) {
            s_userAccounts[_owners[i]].push(currentId);
        }

        s_nextAccountId++;

        emit AccountCreated(currentId, _type, _owners);
    }

    function pauseUnpauseAccount(uint256 _accountId) external {
        Account storage account = s_accounts[_accountId];
        bool ownerCalling;

        for (uint256 i = 0; i < account.owners.length; i++) {
            if (account.owners[i] == msg.sender) ownerCalling = true;
        }

        if (!ownerCalling) revert BankAccounts__NotAnOwner();

        account.isActive = !account.isActive;

    }

    /**
     * @dev Deposits Ether into a specific account
     */
    function deposit(uint256 _accountId) external payable {
        if (msg.value == 0) revert BankAccounts__ZeroDeposit();
        
        Account storage account = s_accounts[_accountId];
        if (account.id == 0) revert BankAccounts__AccountDoesNotExist();
        if (!account.isActive) revert BankAccounts__AccountInactive();

        _processYield(_accountId);
        account.balance += msg.value;

        emit Deposited(_accountId, msg.sender, msg.value);
    }

    /**
     * @dev Requests a withdrawal. If Individual, executes immediately. 
     * If Joint, saves the request waiting for the co-owner's approval.
     */
    function requestWithdrawal(uint256 _accountId, uint256 _amount) external {
        Account storage account = s_accounts[_accountId];
        
        if (account.id == 0) revert BankAccounts__AccountDoesNotExist();
        if (!account.isActive) revert BankAccounts__AccountInactive();
        if (account.balance < _amount) revert BankAccounts__InsufficientFunds();

        // Verify that the sender is one of the owners
        bool isOwner = false;
        for (uint i = 0; i < account.owners.length; i++) {
            if (account.owners[i] == msg.sender) {
                isOwner = true;
                break;
            }
        }
        if (!isOwner) revert BankAccounts__NotAnOwner();

        if (account.accType == AccountType.Individual) {
            _processYield(_accountId);
            // Direct execution for individual accounts
            account.balance -= _amount;
            (bool success, ) = msg.sender.call{value: _amount}("");
            require(success, "Transfer failed");
            
        } else if (account.accType == AccountType.Joint) {
            // Create a request for joint accounts
            s_withdrawalRequests[_accountId] = WithdrawalRequest({
                amount: _amount,
                requester: msg.sender,
                approvedByOther: false,
                isExecuted: false
            });
            
            emit WithdrawalRequested(_accountId, msg.sender, _amount);
        }
    }

    /**
     * @dev Approves and executes a pending withdrawal request for a Joint account.
     * Must be called by the co-owner of the account who did NOT initiate the request.
     * @param _accountId The ID of the joint account.
     */
    function approveWithdrawal(uint256 _accountId) external {
        Account storage account = s_accounts[_accountId];
        WithdrawalRequest storage request = s_withdrawalRequests[_accountId];

        // 1. Validations
        if (account.id == 0) revert BankAccounts__AccountDoesNotExist();
        if (account.accType != AccountType.Joint) revert BankAccounts__NotAJointAccount();
        if (request.amount == 0 || request.isExecuted) revert BankAccounts__NoPendingRequest();
        
        // 2. Ownership and Authorization Checks
        bool isOwner = false;
        for (uint i = 0; i < account.owners.length; i++) {
            if (account.owners[i] == msg.sender) {
                isOwner = true;
                break;
            }
        }
        
        if (!isOwner) revert BankAccounts__NotAnOwner();
        
        // The user approving cannot be the same one who requested the withdrawal
        if (msg.sender == request.requester) revert BankAccounts__CannotApproveOwnRequest();

        // 3. State Updates (Checks-Effects-Interactions pattern)
        request.approvedByOther = true;
        request.isExecuted = true;
        _processYield(_accountId);
        account.balance -= request.amount;
        
        // 4. External Interactions
        (bool success, ) = request.requester.call{value: request.amount}("");
        require(success, "Transfer failed");

        emit WithdrawalExecuted(_accountId, request.requester, request.amount);
    }

    //////////////// Internal functions ////////////////

    /**
     * @dev Calculates and mints yield based on balance and time elapsed.
     * Updates the lastUpdateTime to the current block timestamp.
     */
    function _processYield(uint256 _accountId) internal {
        Account storage account = s_accounts[_accountId];
        
        // We only calculate yield if there is actual Ether in the account
        if (account.balance > 0) {
            uint256 timeElapsed = block.timestamp - account.lastUpdateTime;
            
            // Formula: (balance * time elapsed) / rate
            uint256 yieldAmount = (account.balance * timeElapsed) / YIELD_RATE_DENOMINATOR;
            
            if (yieldAmount > 0) {
                // Split the yield equally among all account owners
                uint256 yieldPerOwner = yieldAmount / account.owners.length;
                
                for (uint i = 0; i < account.owners.length; i++) {
                    s_yieldToken.mint(account.owners[i], yieldPerOwner);
                }
            }
        }
        
        // Reset the timer regardless of whether yield was minted or not
        account.lastUpdateTime = block.timestamp;
    }
    
    //////////////// External View functions ////////////////

    /**
     * @dev Returns the full details of a specific account.
     */
    function getAccount(uint256 _accountId) external view returns (Account memory) {
        return s_accounts[_accountId];
    }

    /**
     * @dev Returns an array of account IDs that a specific user belongs to.
     */
    function getUserAccounts(address _user) external view returns (uint256[] memory) {
        return s_userAccounts[_user];
    }

    /**
     * @dev Returns the pending or last withdrawal request for a specific account.
     */
    function getWithdrawalRequest(uint256 _accountId) external view returns (WithdrawalRequest memory) {
        return s_withdrawalRequests[_accountId];
    }

    function getYeildTokenAddress() external view returns (address token) {
        token = address(s_yieldToken);
    }

    function getContractBalance() external view returns (uint256 balance) {
        balance = address(this).balance;
    }

}