// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title PBM Address list Interface.
/// @notice The PBM address list stores and manages whitelisted merchants and blacklisted address for the PBMs
interface IPBMLogic {

    function isTransferrable(address to) external returns(bool);

    function isUnwrappable(address to) external returns(bool);

    /// @notice Adds wallet addresses to the blacklist who are unable to receive the pbm tokens.
    /// @param addresses The list of merchant wallet address
    /// @param metadata any comments on the addresses being added
    function blacklistAddresses(address[] memory addresses, string memory metadata) external returns(string memory);

    /// @notice Removes wallet addresses from the blacklist who are  unable to receive the PBM tokens.
    /// @param addresses The list of merchant wallet address
    /// @param metadata any comments on the addresses being added
    function unBlacklistAddresses(address[] memory addresses, string memory metadata) external returns(string memory);

    /// @notice Adds wallet addresses of merchants who are the only wallets able to receive the underlying ERC-20 tokens (whitelisting).
    /// @param addresses The list of merchant wallet address
    /// @param metadata any comments on the addresses being added
    function whitelistAddresses(address[] memory addresses, string memory metadata) external returns(string memory);

    /// @notice Removes wallet addresses from the merchant addresses who are  able to receive the underlying ERC-20 tokens (un-whitelisting).
    /// @param addresses The list of merchant wallet address
    /// @param metadata any comments on the addresses being added
    function unWhitelistAddresses(address[] memory addresses, string memory metadata) external returns(string memory);

    /// @notice Event emitted when the Merchant List is edited
    /// @param action Tags "add" or "remove" for action type
    /// @param addresses The list of merchant wallet address
    /// @param metadata any comments on the addresses being added
    event Whitelist(string action, address[] addresses, string metadata);

    /// @notice Event emitted when the Blacklist is edited
    /// @param action Tags "add" or "remove" for action type
    /// @param addresses The list of merchant wallet address
    /// @param metadata any comments on the addresses being added
    event Blacklist(string action, address[] addresses, string metadata);
}