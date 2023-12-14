// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiSigWallet {
    address public owner;
    mapping(address => bool) public isSigner;
    uint public quorum;

    struct Transaction {
        address destination;
        uint value;
        bytes data;
        bool executed;
        uint signatureCount;
    }

    Transaction[] public transactions;
    mapping(uint => mapping(address => bool)) public isApproved;

// The contract emits events when a transaction is proposed, approved, or executed, providing transparency and traceability.
    event TransactionProposed(uint indexed transactionId);
    event TransactionApproved(uint indexed transactionId, address indexed approver);
    event TransactionExecuted(uint indexed transactionId, address indexed executor);


//  The contract is initialized with a list of authorized signers and a required quorum.
    constructor(address[] memory _signers, uint _quorum) {
        require(_signers.length >= _quorum, "Insufficient signers for the quorum");
        owner = msg.sender;
        for(uint i = 0; i < _signers.length; i++) {
            isSigner[_signers[i]] = true;
        }
        quorum = _quorum;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier onlySigner() {
        require(isSigner[msg.sender], "Not an authorized signer");
        _;
    }



// Any user can propose a transaction. The transaction details are stored in an array.
    function proposeTransaction(address _destination, uint _value, bytes memory _data) public {
        uint transactionId = transactions.length;
        transactions.push(Transaction({
            destination: _destination,
            value: _value,
            data: _data,
            executed: false,
            signatureCount: 0
        }));
        emit TransactionProposed(transactionId);
    }



//  Authorized signers can approve proposed transactions. A transaction can't be approved more than once by the same signer.
    function approveTransaction(uint _transactionId) public onlySigner {
        require(_transactionId < transactions.length, "Invalid transaction ID");
        require(!isApproved[_transactionId][msg.sender], "Transaction already approved by this signer");
        require(!transactions[_transactionId].executed, "Transaction already executed");

        transactions[_transactionId].signatureCount++;
        isApproved[_transactionId][msg.sender] = true;
        emit TransactionApproved(_transactionId, msg.sender);
    }



// If the number of approvals meets or exceeds the quorum, the transaction can be executed by any signer.
    function executeTransaction(uint _transactionId) public {
        require(_transactionId < transactions.length, "Invalid transaction ID");
        require(transactions[_transactionId].signatureCount >= quorum, "Insufficient approvals");
        require(!transactions[_transactionId].executed, "Transaction already executed");

        Transaction storage transaction = transactions[_transactionId];
        transaction.executed = true;

        (bool success,) = transaction.destination.call{value: transaction.value}(transaction.data);
        require(success, "Transaction failed");

        emit TransactionExecuted(_transactionId, msg.sender);
    }



// The contract can receive Ether, which can be part of proposed transactions.
    receive() external payable {}



    // Function to check the contract's balance
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}
