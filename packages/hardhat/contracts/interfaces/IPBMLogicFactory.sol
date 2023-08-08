// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title PBM Address list Interface.
/// @notice The PBM address list stores and manages whitelisted merchants and blacklisted address for the PBMs
interface IPBMLogicFactory {
    function createPBMLogic(address owner, bool isBlacklist, bool isWhiteList) external returns(address);
}