// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPBMTokenManager.sol";

contract PBMTokenManager is IPBMTokenManager{
    using Strings for uint256;

    // counter used to create new token types
    uint256 internal tokenTypeCount = 0;

    // structure representing all the details of a PBM type
    struct TokenConfig {
        string name;
        uint256 amount;
        address creator;
        bool isFixedSupply;
        uint256 balanceSupply;
        bool isExpiring;
        uint256 expiry;
        bool isRevoked;
    }

    // mapping of token ids to token details
    mapping(uint256 => TokenConfig) internal tokenTypes;

    function createTokenType(
        NewTokenType memory tokenType
    ) external returns(uint256) {
        require(tokenType.spotAmount != 0, "Spot amount is 0");
        if (tokenType.isFixedSupply) {
            require(tokenType.initialSupply != 0, "Initial supply cannot be 0 if supply is fixed");
        }
        if (tokenType.isExpiring) {
            require(tokenType.tokenExpiry != 0, "Token expiry cannot be 0");
            require(tokenType.tokenExpiry <= tokenType.contractExpiry, "Token expiry cannot be after contract expiry");
            require(tokenType.tokenExpiry > block.timestamp, "Token expiry cannot be before current time");
        }
        else {
            require(tokenType.tokenExpiry == 0, "Token expiry must be 0 since it is non expiring as it was declared non expiring");
        }

        string memory tokenName = string(abi.encodePacked(tokenType.companyName, tokenType.spotAmount.toString()));
        tokenTypes[tokenTypeCount].name = tokenName;
        tokenTypes[tokenTypeCount].amount = tokenType.spotAmount;
        tokenTypes[tokenTypeCount].creator = tokenType.creator;
        tokenTypes[tokenTypeCount].isFixedSupply = tokenType.isFixedSupply;
        tokenTypes[tokenTypeCount].balanceSupply = tokenType.initialSupply;
        tokenTypes[tokenTypeCount].isExpiring = tokenType.isExpiring;
        tokenTypes[tokenTypeCount].expiry = tokenType.tokenExpiry;
        tokenTypes[tokenTypeCount].isRevoked = false;

        emit NewPBMTypeCreated(tokenTypeCount, tokenName, tokenType.spotAmount, tokenType.tokenExpiry, tokenType.creator);
        uint256 tokenId = tokenTypeCount;
        tokenTypeCount += 1;
        return tokenId;
    }

    /**
     * @dev See {IPBMTokenManager-revokePBM}.
     *
     * Requirements:
     *
     * - only the pbm wrapper contract can call this function ( onlyOwner )
     * - token must be expired
     * - `tokenId` should be a valid id that has already been created
     * - `sender` must be the token type creator
     */
    function revokePBM(uint256 tokenId, address sender) external {
        require(tokenTypes[tokenId].isExpiring, "Token is non expiring and cannot be revoked");
        require(
            sender == tokenTypes[tokenId].creator && block.timestamp >= tokenTypes[tokenId].expiry,
            "PBM not revokable"
        );
        tokenTypes[tokenId].isRevoked = true;
        // essentially burning the remaining tokens in the supply?
        tokenTypes[tokenId].balanceSupply = 0;
    }

    /**
     * @dev See {IPBMTokenManager-increaseBalanceSupply}.
     *
     * Requirements:
     *
     * - only the pbm wrapper contract can call this function ( onlyOwner )
     * - `tokenId` should be a valid id that has already been created
     * - `sender` must be the token type creator
     */
    function increaseBalanceSupply(uint256[] memory tokenIds, uint256[] memory amounts) external {
        // would it make sense to do these checks before the function actually increases the supply of the tokens, coz if not it might get messy in terms of knowing whether the inputted token supplies increased
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                tokenTypes[tokenIds[i]].amount != 0 && !tokenTypes[tokenIds[i]].isRevoked,
                "PBM: Invalid Token Id(s)"
            );
            if (tokenTypes[tokenIds[i]].isExpiring) {
                require(block.timestamp < tokenTypes[tokenIds[i]].expiry, "Tokens have expired");
            }
            tokenTypes[tokenIds[i]].balanceSupply += amounts[i];
        }
    }

    /**
     * @dev See {IPBMTokenManager-decreaseBalanceSupply}.
     *
     * Requirements:
     *
     * - only the pbm wrapper contract can call this function ( onlyOwner )
     * - `tokenId` should be a valid id that has already been created
     * - `sender` must be the token type creator
     */
    function decreaseBalanceSupply(uint256[] memory tokenIds, uint256[] memory amounts) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                tokenTypes[tokenIds[i]].amount != 0 && !tokenTypes[tokenIds[i]].isRevoked,
                "PBM: Invalid Token Id(s)"
            );
            if (tokenTypes[tokenIds[i]].isExpiring) {
                require(block.timestamp < tokenTypes[tokenIds[i]].expiry, "Tokens have expired");
            }
            tokenTypes[tokenIds[i]].balanceSupply -= amounts[i];
        }
    }

    /**
     * @dev See {IPBMTokenManager-uri}.
     *
     */
    // function uri(uint256 tokenId) external view override returns (string memory) {
    //     if (block.timestamp >= tokenTypes[tokenId].expiry) {
    //         return tokenTypes[tokenId].postExpiryURI;
    //     }
    //     return tokenTypes[tokenId].uri;
    // }

    /**
     * @dev See {IPBMTokenManager-areTokensValid}.
     *
     */
    function areTokensValid(uint256[] memory tokenIds) external view returns (bool) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenTypes[i].amount == 0) {
                return false;
            }
            if (tokenTypes[tokenIds[i]].isRevoked) {
                return false;
            }
            if (tokenTypes[i].isExpiring) {
                if (block.timestamp > tokenTypes[i].expiry) {
                    return false;
                }
            }
        }
        return true;
    }

    /**
     * @dev See {IPBMTokenManager-getTokenDetails}.
     *
     * Requirements:
     *
     * - `tokenId` should be a valid id that has already been created
     */
    function getTokenDetails(
        uint256 tokenId
    ) external view returns (string memory, uint256, address, bool, uint256, bool, uint256, bool) {
        require(tokenTypes[tokenId].amount != 0, "PBM: Invalid Token Id(s)");
        require(bytes(tokenTypes[tokenId].name).length > 0, "PBM: Token not initialized");
        return (
            tokenTypes[tokenId].name,
            tokenTypes[tokenId].amount,
            tokenTypes[tokenId].creator,
            tokenTypes[tokenId].isFixedSupply,
            tokenTypes[tokenId].balanceSupply,
            tokenTypes[tokenId].isExpiring,
            tokenTypes[tokenId].expiry,
            tokenTypes[tokenId].isRevoked
        );
    }

    /**
     * @dev See {IPBMTokenManager-getPBMRevokeValue}.
     *
     * Requirements:
     *
     * - `tokenId` should be a valid id that has already been created
     */
    function getPBMRevokeValue(uint256 tokenId) external view returns (uint256) {
        require(tokenTypes[tokenId].amount != 0, "PBM: Invalid Token Id(s)");
        return tokenTypes[tokenId].amount * tokenTypes[tokenId].balanceSupply;
    }

    /**
     * @dev See {IPBMTokenManager-getTokenValue}.
     *
     * Requirements:
     *
     * - `tokenId` should be a valid id that has already been created
     */
    function getTokenValue(uint256 tokenId) external view returns (uint256) {
        require(
            tokenTypes[tokenId].amount != 0 && !tokenTypes[tokenId].isRevoked,
            "PBM: Invalid Token Id(s)"
        );
        if (tokenTypes[tokenId].isExpiring) {
            require(block.timestamp < tokenTypes[tokenId].expiry, "Tokens have expired");
        }
        return tokenTypes[tokenId].amount;
    }

    /**
     * @dev See {IPBMTokenManager-getTokenCount}.
     *
     * Requirements:
     *
     * - `tokenId` should be a valid id that has already been created
     */
    function getTokenCount(uint256 tokenId) external view returns (uint256) {
        require(
            tokenTypes[tokenId].amount != 0 && !tokenTypes[tokenId].isRevoked,
            "PBM: Invalid Token Id(s)"
        );
        if (tokenTypes[tokenId].isExpiring) {
            require(block.timestamp < tokenTypes[tokenId].expiry, "Tokens have expired");
        }
        return tokenTypes[tokenId].balanceSupply;
    }

    /**
     * @dev See {IPBMTokenManager-getTokenCreator}.
     *
     * Requirements:
     *
     * - `tokenId` should be a valid id that has already been created
     */
    function getTokenCreator(uint256 tokenId) external view returns (address) {
        require(
            tokenTypes[tokenId].amount != 0 && !tokenTypes[tokenId].isRevoked,
            "PBM: Invalid Token Id(s)"
        );
        if (tokenTypes[tokenId].isExpiring) {
            require(block.timestamp < tokenTypes[tokenId].expiry, "Tokens have expired");
        }
        return tokenTypes[tokenId].creator;
    }
}