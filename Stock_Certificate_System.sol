// contracts/SCS.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./Stock_Certificate_Company.sol";
import "hardhat/console.sol";

contract SCS is ERC1155Holder {
    // List of companies
    string[] public companyNames;

    // Per condition checker
    mapping(string => SCC) public companies;
    mapping(string => bool) public registered;

    // modifier
    modifier isRegistered(string memory _companyName) {
        require(registered[_companyName], "ERROR: Company does not exist");
        _;
    }

    // Function of adding new company
    function addCompoany(string memory _companyName, string memory _establishingDate, uint _shares, address[] memory _directors, uint _numConfirmationsRequired) public {
        require(registered[_companyName] == false, "ERROR: This company is already established");
        SCC c = new SCC(_companyName,  _establishingDate, _shares,  _directors, _numConfirmationsRequired);

        companies[_companyName] = c;
        registered[_companyName] = true;
        companyNames.push(_companyName);
    }

    // Function of showing company's information
    function showCompanyInformation() public view{
        for(uint i = 0; i < companyNames.length; ++i) {
            console.log("Company Name: %s", companyNames[i]);
            console.log("Company Establishing Date: %s", companies[companyNames[i]].getestablishingDate());
            console.log("Number of confirmations required: %s", companies[companyNames[i]].getnumConfirmationsRequired());
            console.log("Company's stocks remain: %s", companies[companyNames[i]].getshares());
            console.log("Directors list: ");
            for(uint j = 0; j < companies[companyNames[i]].getdirectors().length; ++j){
                console.log("       %s", companies[companyNames[i]].getdirectors()[j]);         
            }
        }
        console.log("----------------------------------------------------------------");
    }

    // Function of issuing stock for designated company
    function issue(string memory _companyName, uint _ammount) public isRegistered(_companyName){
        SCC c = companies[_companyName];
        c.submitAction(msg.sender, "Issue", address(0), _ammount);
    }

    // Function of reissuing stock for designated company
    function reissue(string memory _companyName, uint _ammount) public isRegistered(_companyName){
        SCC c = companies[_companyName];
        c.submitAction(msg.sender, "Reissue", address(0), _ammount);
    }

    // Function transferring stock from company A to company B
    function transaction(string memory _companyName, address target, uint _ammount) public isRegistered(_companyName){
        SCC c = companies[_companyName];
        c.submitAction(msg.sender, "Transaction", target, _ammount);
    }

    // Function redeeming stock from company B back to company A
    function redemption(string memory _companyName, address target, uint _ammount) public isRegistered(_companyName){
        SCC c = companies[_companyName];
        c.submitAction(msg.sender, "Redeption", target, _ammount);
    }

    // Function for others directors confirm the action
    function confirmAction(string memory _companyName, uint  _actionID) public isRegistered(_companyName){
        SCC c = companies[_companyName];
        c.confirmAction(msg.sender,  _actionID);
    }
}
