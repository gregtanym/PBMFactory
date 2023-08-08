//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "hardhat/console.sol";

// import "@openzeppelin/contracts/access/Ownable.sol";
import './interfaces/IPBMLogic.sol';
import './interfaces/IPBMLogicFactory.sol';

contract PBMLogicContract is IPBMLogic {
    
    address public deployer; // should always be set to the factory contract

    // flags 
    bool public isBlacklist = false;
    bool public isWhitelist = false; 

    // variables
    address public owner; 
    mapping(address => bool) public blacklistedAddresses;
    mapping(address => bool) public whitelistedAddresses;


    // modifiers based on flags
    modifier whitelistFeature() {
        require(isWhitelist, "Whitelist feature is disabled for this contract");
        _; 
    }
    modifier blacklistFeature() {
        require(isBlacklist, "Blacklist feature is disabled for this contract");
        _; 
    }

    constructor(address _deployer, address _owner, bool _isBlacklist, bool _isWhitelist) {
        // i should put a check such that only the logic factory contract can call the constructor
        deployer = _deployer;
        owner = _owner;
        isBlacklist = _isBlacklist;
        isWhitelist = _isWhitelist;
    }

    function isTransferrable(address to) public returns(bool){
        if (!isBlacklist) {
            return true;
        }
        else if (blacklistedAddresses[to]) {
            return false;
        }
        else {
            return true;
        }
    }

    function isUnwrappable(address to) public returns(bool) {
        if (!isWhitelist) {
            return true;
        }
        else if (whitelistedAddresses[to]) {
            return true;
        }
        else {
            return false;
        }
    }

    function whitelistAddresses(address[] memory addresses, string memory metadata) public whitelistFeature returns(string memory){
        for(uint256 i = 0; i < addresses.length; i++) {
            whitelistedAddresses[addresses[i]] = true;
        }
        emit Whitelist("add", addresses, metadata);
        // return success message
        return "Addresses have been successfully added to whitelist";
    }

    function unWhitelistAddresses(address[] memory addresses, string memory metadata) public whitelistFeature returns(string memory) {
        for(uint256 i = 0; i < addresses.length; i++) {
            whitelistedAddresses[addresses[i]] = false;
        }
        emit Whitelist("remove", addresses, metadata);
        return "Addresses have been successfully removed from whitelist";
    }

    function blacklistAddresses(address[] memory addresses, string memory metadata) public blacklistFeature returns(string memory){
        for(uint256 i = 0; i < addresses.length; i++) {
            blacklistedAddresses[addresses[i]] = true;
        }
        emit Blacklist("add", addresses, metadata);
        return "Addresses have been successfully added to blacklist";
    }

    function unBlacklistAddresses(address[] memory addresses, string memory metadata) public blacklistFeature returns(string memory){
        for(uint256 i = 0; i < addresses.length; i++) {
            blacklistedAddresses[addresses[i]] = false;
        }
        emit Blacklist("remove", addresses, metadata);
        return "Addresses have been successfully removed from blacklist";
    }

    function isBlacklisted(address _address) public blacklistFeature returns(bool){
        return blacklistedAddresses[_address];
    }

    function isWhitelisted (address _address) public whitelistFeature returns(bool){
        return whitelistedAddresses[_address];
    }

}

contract PBMLogicFactory is IPBMLogicFactory {
    PBMLogicContract newLogicContract; 
    PBMLogicContract[] public listOfLogicContracts;

    function createPBMLogic(address owner, bool isBlacklist, bool isWhiteList) external returns(address){
        newLogicContract = new PBMLogicContract(address(this), owner, isBlacklist, isWhiteList);
        listOfLogicContracts.push(newLogicContract);
        return address(newLogicContract);
    }
}