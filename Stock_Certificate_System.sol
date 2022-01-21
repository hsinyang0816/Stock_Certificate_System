// contracts/SCS.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./Stock_Certificate_Company.sol";
import "hardhat/console.sol";

contract SCS is ERC1155Holder {
    
    mapping(string => SCC) public companies;
    mapping(string => bool) public registered;

    string[] public companyNames;

    function addCompoany(string memory _companyName, string memory _establishingDate,uint _shares , address[] memory _directors, uint _numConfirmationsRequired) public {
        require(registered[_companyName] == false, "ERROR: This company is already established");
        SCC c = new SCC(_companyName,  _establishingDate, _shares,  _directors, _numConfirmationsRequired);

        companies[_companyName] = c;
        registered[_companyName] = true;
        companyNames.push(_companyName);
    }

    modifier isRegistered(string memory name) {
        require(registered[name], "ERROR: Company does not exist");
        _;
    }


    function showCompany() public view{
        for(uint i = 0; i < companyNames.length; ++i) {
            console.log("%s: %s", companyNames[i], address(companies[companyNames[i]]));
        }
    }

    function issue(string memory _companyName, uint _ammount) 
    public 
    isRegistered(_companyName) 
    {
        SCC c = companies[_companyName];
        c.submitAction(msg.sender, "issue", address(0), _ammount);
    }

    function reissue(string memory _companyName, uint _ammount) 
    public 
    isRegistered(_companyName) 
    {
        SCC c = companies[_companyName];
        c.submitAction(msg.sender, "reissue", address(0), _ammount);
    }

    function transfer(string memory _companyName, address target, uint _ammount) 
    public
    isRegistered(_companyName)
    {
        SCC c = companies[_companyName];
        c.submitAction(msg.sender, "transfer", target, _ammount);
    }

    function redemption(string memory _companyName, address target, uint _ammount) 
    public
    isRegistered(_companyName)
    {
        SCC c = companies[_companyName];
        c.submitAction(msg.sender, "redeption", target, _ammount);
    }

    function confirmAction(string memory _companyName, uint _acIndex, uint _ammount) 
    public 
    isRegistered(_companyName)
    {
        SCC c = companies[_companyName];
        c.confirmAction(msg.sender, _acIndex, _ammount);
    }
}
