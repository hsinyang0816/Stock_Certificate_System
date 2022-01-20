// contracts/SCS.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "hardhat/console.sol";

contract SCC is ERC1155 {
    uint256 public constant SWORD = 3;
    struct Action {
        address promotor;
        bool executed;
        uint numConfirmations;
        string actionName;
        address target;
        uint amount;
    }

    string name;
    string fundingDate;
    uint shares;
    address[] public funders;
    uint public numConfirmationsRequired;

    Action[] public actions;

    mapping(address => bool) public isFunder;
    mapping(string => bool) public isValidAction;
    mapping(uint => mapping(address => bool)) public isConfirmed;

    event SubmitAction(
        address indexed promotor,
        uint indexed acIndex, 
        uint indexed amount
    );

    event ConfirmAction(
        address indexed funder,
        uint indexed acIndex,
        uint indexed amount
    );

    modifier onlyFunder(address _funder) {
        require(isFunder[_funder], "not funder");
        _;
    }

    modifier onlyValidAction(string memory _action) {
        require(isValidAction[_action], "action is invalid");
        _;
    }

    modifier notExecuted(uint _acIndex) {
        require(!actions[_acIndex].executed, "action already exectued");
        _;
    }
    
    modifier notConfirmed(address _funder, uint _acIndex) {
        require(!isConfirmed[_acIndex][_funder], "action already confirmed");
        _;
    }

    constructor(string memory _name, string memory _fundingDate, uint _shares, address[] memory _funders, uint _numConfirmationsRequired) ERC1155("https://raw.githubusercontent.com/hsinyang0816/Stock_Certificate_System/{id}.json}") {
        require(_funders.length > 0, "owners required");
        require(_numConfirmationsRequired > 0 && 
                _numConfirmationsRequired <= _funders.length,
                "invalid number of required confirmations"
        );
        require(_shares > 0, "shares should be at least 1");

        for (uint i = 0; i < _funders.length; i++) {
            address funder = _funders[i];

            require(funder != address(0), "invalid owner");
            require(!isFunder[funder], "funder not unique");

            isFunder[funder] = true;
            funders.push(funder);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
        name = _name;
        fundingDate = _fundingDate;
        shares = _shares;

        // mint the genesis SCN
        _mint(msg.sender, SWORD, shares, "");

        isValidAction["Issue"] = true;
        isValidAction["Reissue"] = true;
        isValidAction["Transfer"] = true;
        isValidAction["Redeption"] = true;
    }

    function compareString(string memory a, string memory b) public pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function submitAction(address _promotor, string memory _actionName, address _target, uint _amount) 
    public 
    onlyFunder(_promotor)
    onlyValidAction(_actionName)
    {

        if (compareString(_actionName, "Transfer") || compareString(_actionName, "Redemption") ) {
            require(_target != address(0));
        }

        uint acIndex = actions.length;
        actions.push(
            Action({
                promotor: _promotor,
                executed: false,
                numConfirmations: 0,
                actionName: _actionName,
                target: _target, 
                amount: _amount
            })
        );

        emit SubmitAction(_promotor, acIndex, _amount);
    }
    
    function confirmAction(address _funder, uint _acIndex, uint _amount)
    public
    onlyFunder(_funder)
    notExecuted(_acIndex)
    notConfirmed(_funder, _acIndex)
    {
        Action storage action = actions[_acIndex];
        action.numConfirmations += 1;
        isConfirmed[_acIndex][_funder] = true;

        if (action.numConfirmations >= numConfirmationsRequired) {
            executeAction(_acIndex, _amount);
        }

        emit ConfirmAction(_funder, _acIndex, _amount);
    }

    function executeAction(uint _acIndex, uint _amount) private{
        Action storage action = actions[_acIndex];

        action.executed = true;

        if (compareString(action.actionName, "Issue")) {
            issue(_amount);
        }else if (compareString(action.actionName, "Reissue")) {
            reissue(_amount);
        }else if (compareString(action.actionName, "Transfer")) {
            transfer(action.target, _amount);
        }else if (compareString(action.actionName,"Redemption")) {
            redemption(action.target, _amount);
        }
    }

    function issue(uint _amount) private {
        _mint(msg.sender, SWORD, _amount, "");
        // console.log("issue a token");
        console.log("Issue %s token", _amount);
    }
    
    function reissue(uint _amount) private {
        _burn(msg.sender, SWORD, _amount);
        _mint(msg.sender, SWORD, _amount*2, "");
        // console.log("reissue 2 token");
        console.log("Reissue %s token", _amount*2);
    }

    function transfer(address target, uint _amount) private {
        safeTransferFrom(msg.sender, target, SWORD, _amount, "");
        console.log("Transfered");
    }

    function redemption(address target, uint _amount) private {
        safeTransferFrom(target, msg.sender, SWORD, _amount, "");
        _burn(msg.sender, SWORD, _amount);
        console.log("Redemption");
    }
}
