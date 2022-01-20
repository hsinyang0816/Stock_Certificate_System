// contracts/SCS.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract SCS is ERC1155 {
    uint256 public constant SWORD = 3;

    // event SubmitTransaction(
    //     address indexed owner,
    //     uint indexed Transaction_Index,
    //     address indexed to,
    //     uint value
    // );
    // event ConfirmTransaction(address indexed owner, uint indexed Transaction_Index);
    // event RevokeConfirmation(address indexed owner, uint indexed Transaction_Index);
    // event ExecuteTransaction(address indexed owner, uint indexed Transaction_Index);

    address[] public directors;
    address merchant;
    mapping(address => bool) public isDirector;
    uint public threshold;

    struct Transaction {
        address Customer;
        uint ammount;
        bool deal;
        uint numOfAcknowledgments;
    }

    // mapping from tx index => owner => bool
    mapping(uint => mapping(address => bool)) public isConfirmed;

    Transaction[] public transactions;

    modifier Director_only() {
        require(isDirector[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].deal, "tx already executed");
        _;
    }

    modifier notConfirmed(uint _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    constructor(address[] memory _directors, uint _threshold, uint _originalShare) public ERC1155("https://raw.githubusercontent.com/hsinyang0816/Stock_Certificate_System/{id}.json}")
    {
        require(_directors.length > 0, "directors required");
        require(
            _threshold > 0 &&
                _threshold <= _directors.length,
            "invalid number of required confirmations"
        );

        for (uint i = 0; i < _directors.length; i++) {
            address director = _directors[i];

            require(director != address(0), "invalid director");
            require(!isDirector[director], "director not unique");

            isDirector[director] = true;
            directors.push(director);
        }

        require(isDirector[msg.sender], "Contract creator is not in directors list");

        merchant = msg.sender;
        threshold = _threshold;
        _mint(msg.sender, SWORD, _originalShare, "");
    }

    function getStock(address addr) view public returns (uint256){
        return balanceOf(addr, SWORD);
    }

    function burnStock(address addr, uint amount) public Director_only{
        _burn(addr, SWORD, amount);
    }

    function mintStock(uint amount) public Director_only{
        _mint(merchant, SWORD, amount, "");
    }

    function submitIssueRequest(address _Customer, uint _ammount) public{
        uint remain = balanceOf(merchant, SWORD);
        require(remain >= _ammount, "not enough stocks to give");
        uint txIndex = transactions.length;

        transactions.push(
            Transaction({
                Customer: _Customer,
                ammount: _ammount,
                deal: false,
                numOfAcknowledgments: 0
            })
        );

        // emit SubmitTransaction(msg.sender, txIndex, _to, _value);
    }

    // Owners approve pending transactions
    function confirmIssueRequest(uint _txIndex) public Director_only txExists(_txIndex) notExecuted(_txIndex) notConfirmed(_txIndex){
        Transaction storage transaction = transactions[_txIndex];
        transaction.numOfAcknowledgments += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        if (transaction.numOfAcknowledgments >= threshold) {
            executeTransaction(_txIndex);
        }

        // emit ConfirmTransaction(msg.sender, _txIndex);
    }

    function executeTransaction(uint _txIndex) private txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage txn = transactions[_txIndex];

        require(
            txn.numOfAcknowledgments >= threshold,
            "too few confirmations"
        );

        txn.deal = true;

        safeTransferFrom(merchant, txn.Customer, SWORD, txn.ammount, "");

        // emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(uint _txIndex) public Director_only txExists(_txIndex) notExecuted(_txIndex){
        Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");

        transaction.numOfAcknowledgments -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        // emit RevokeConfirmation(msg.sender, _txIndex);
    }

    function getOwners() public view returns (address[] memory) {
        return directors;
    }

    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    function getTransaction(uint _txIndex) public view
        returns (
            address to,
            uint value,
            bool deal,
            uint numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.Customer,
            transaction.ammount,
            transaction.deal,
            transaction.numOfAcknowledgments
        );
    }
}
