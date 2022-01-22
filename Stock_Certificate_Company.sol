// contracts/SCS.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "hardhat/console.sol";

contract SCC is ERC1155 {
    // defined our's token 
    uint256 public constant SWORD = 3;
   
    // Company's information initialization 
    string public name;
    address[] public directors;
    uint public numConfirmationsRequired;
    string public establishingDate;
    uint public shares;
    address public contract_creator;

    // Per condition checker
    mapping(address => bool) public isDirector;
    mapping(string => bool) public isValidAction;
    mapping(uint => mapping(address => bool)) public isConfirmed;

    // Action structure
    struct Action {
        address executor;
        bool executed;
        uint numConfirmations;
        string actionName;
        address target;
        uint amount;
    }

    Action[] private actions;

     
    // modifier
    modifier Director_only(address _Director) {
        require(isDirector[_Director], "ERROR: Thsi is not director");
        _;
    }

    modifier ValidAction_only(string memory _action) {
        require(isValidAction[_action], "ERROR: This action is invalid");
        _;
    }

    modifier notExecuted(uint _acIndex) {
        require(!actions[_acIndex].executed, "ERROR: This action is already exectued");
        _;
    }
    
    modifier notConfirmed(address _director, uint _acIndex) {
        require(!isConfirmed[_acIndex][_director], "ERROR: This action is already confirmed");
        _;
    }

    // event trigger
    event SubmitAction(
        address indexed executor,
        uint indexed acIndex, 
        uint indexed amount
    );

    event ConfirmAction(
        address indexed director,
        uint indexed acIndex
    );

    event ExecuteAction(
        address indexed executor,
        bool executed,
        uint numConfirmations,
        string indexed actionName,
        address indexed target,
        uint amount
    );

    // Company constructor, including company name, funding date, shares, directors list and number of confirmations required
    constructor(string memory _name, string memory _establishingDate, uint _shares, address[] memory _directors, uint _numConfirmationsRequired) ERC1155("https://raw.githubusercontent.com/hsinyang0816/Stock_Certificate_System/{id}.json}") {
        // Check whether directors list is given or not
        require(_directors.length > 0, "ERROR: Directors required");
        // Check whether the number of confirmations required reasonable or not
        require(_numConfirmationsRequired > 0 && _numConfirmationsRequired <= _directors.length, "ERROR: Invalid number of required confirmations");
        // Check whether shares number is zero or not
        require(_shares > 0, "ERROR: Shares should be at least 1");

        for (uint i = 0; i < _directors.length; i++) {
            address director = _directors[i];
            // Check whether there is invalid director or not
            require(director != address(0), "ERROR: Invalid director");
            // Check whether the director is repeat or not
            require(!isDirector[director], "ERROR: Director not unique");

            // Successfully construct the directors list
            isDirector[director] = true;
            directors.push(director);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
        name = _name;
        establishingDate = _establishingDate;
        shares = _shares;
        contract_creator = msg.sender;

        // mint the initial tokens
        _mint(msg.sender, SWORD, shares, "");

        // Below is the four valid action for each company to execute
        isValidAction["Issue"] = true;
        isValidAction["Reissue"] = true;
        isValidAction["Transfer"] = true;
        isValidAction["Redeption"] = true;
    }

    function getestablishingDate() public view returns (string memory) {
        return establishingDate;
    }

    function getnumConfirmationsRequired() public view returns (uint) {
        return numConfirmationsRequired;
    }

    function getshares() public view returns (uint) {
        return shares;
    }

    function getdirectors() public view returns (address[] memory) {
        return directors;
    }

    function getcontract_creator() public view returns (address) {
        return contract_creator;
    }

    // Function of comparing whether two input string is indentical or not 
    function withStrs(string memory a, string memory b) public pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    // function addressToString(address _addr) public pure returns(string) {
    //     bytes32 value = bytes32(uint256(uint160(_addr)));
    //     bytes memory alphabet = "0123456789abcdef";

    //     bytes memory str = new bytes(51);
    //     str[0] = "0";
    //     str[1] = "x";
    //     for (uint i = 0; i < 20; i++) {
    //         str[2+i*2] = alphabet[uint(uint8(value[i + 12] >> 4))];
    //         str[3+i*2] = alphabet[uint(uint8(value[i + 12] & 0x0f))];
    //     }
    //     return string(str);
    // }  


    // Function of issuing token
    function issue(uint _amount) private {
        _mint(msg.sender, SWORD, _amount, "");
        shares = shares + _amount;
        console.log("Issue %s token", _amount);
    }
    
    // Function of reissuing token
    function reissue(uint _amount) private {
        require(_amount <= shares, "ERROR: Not enough shares to burn");
        _burn(msg.sender, SWORD, _amount);
        _mint(msg.sender, SWORD, _amount*2, "");
        shares = shares + _amount*2;
        console.log("Reissue %s token", _amount*2);
    }

    // Function of transaction
    function transaction(address _target, uint _amount) private {
        // require(_amount <= shares, "ERROR: Not enough shares to transfer to : %s", addressToString(_target));
        safeTransferFrom(msg.sender, _target, SWORD, _amount, "");
        shares = shares - _amount;
        console.log("Transaction");
    }

    // Function of redemption
    function redemption(address _target, uint _amount) private {
        safeTransferFrom(_target, msg.sender, SWORD, _amount, "");
        _burn(msg.sender, SWORD, _amount);
        shares = shares + _amount;
        console.log("Redemption");
    }

    // Function of summiting action by the executor of company
    function submitAction(address _executor, string memory _actionName, address _target, uint _amount) public Director_only(_executor) ValidAction_only(_actionName){
        // Transaction and redemption require address
        if (withStrs(_actionName, "Transaction") || withStrs(_actionName, "Redemption") ) {
            require(_target != address(0), "ERROR: Address required");
        }

        // Initial new action
        uint actionID = actions.length;
        actions.push(
            Action({
                executor: _executor,
                executed: false,
                numConfirmations: 0,
                actionName: _actionName,
                target: _target, 
                amount: _amount
            })
        );
        console.log("The action ID is: %s", actionID);
        console.log("Please remember this ID and inform other directors to certify for this contract!");
        emit SubmitAction(_executor, actionID, _amount);
    }
    
    // Function of confirming action by the other directors of company
    function confirmAction(address _director, uint _actionID) public Director_only(_director) notExecuted(_actionID) notConfirmed(_director, _actionID){
        Action storage action = actions[_actionID];
        action.numConfirmations += 1;
        isConfirmed[_actionID][_director] = true;

        if (action.numConfirmations >= numConfirmationsRequired) 
            executeAction(_actionID);

        emit ConfirmAction(_director, _actionID);
    }

    // Function of executing action 
    function executeAction(uint _actionID) private{
        Action storage action = actions[_actionID];

        action.executed = true;
        if (withStrs(action.actionName, "Issue")) 
            issue(action.amount);
        else if (withStrs(action.actionName, "Reissue")) 
            reissue(action.amount);
        else if (withStrs(action.actionName, "Transaction")) 
            transaction(action.target, action.amount);
        else if (withStrs(action.actionName,"Redemption")) 
            redemption(action.target, action.amount);

        emit ExecuteAction(action.executor, action.executed, action.numConfirmations, action.actionName, action.target, action.amount);
    }

    function sharesModify(uint _amount, uint _actionID) public {
        Action storage action = actions[_actionID];
        if(action.executed)
            shares = shares + _amount;
        console.log("Shares now is %s: ", shares);
    }
}
