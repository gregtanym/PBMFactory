// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title PBMTokenManager Interface.
/// @notice The PBMTokenManager is the stores details of the different data types.
interface IPBMTokenManager {

    struct NewTokenType {
        string companyName;
        uint256 spotAmount;
        address creator;
        uint256 contractExpiry;
        bool isFixedSupply;
        uint256 initialSupply;
        bool isExpiring;
        uint256 tokenExpiry;
    }

    /// @notice Checks if tokens Ids have been created and are not expired
    /// @param tokenIds The ids for the PBM in query
    /// @return Returns true if all the tokenId are valid else false
    function areTokensValid(uint256[] memory tokenIds) external view returns (bool);

    /// @notice gets the total value of underlying ERC20 tokens the PBM type holds
    /// @param tokenId The id for the PBM in query
    /// @return Returns the total ERC20 amount
    function getPBMRevokeValue(uint256 tokenId) external view returns (uint256);

    /// @notice gets the amount of underlying ERC20 tokens each of the the PBM type holds
    /// @param tokenId The id for the PBM in query
    /// @return Returns the underlying ERC20 amount
    function getTokenValue(uint256 tokenId) external view returns (uint256);

    /// @notice gets the count of the PBM type in supply
    /// @param tokenId The id for the PBM in query
    /// @return Returns the count of the PBM
    function getTokenCount(uint256 tokenId) external view returns (uint256);

    /// @notice gets the address of the creator of the PBM type
    /// @param tokenId The id for the PBM in query
    /// @return Returns the address of the creator
    function getTokenCreator(uint256 tokenId) external view returns (address);

    /// @notice Retreive the details for a PBM
    /// @param tokenId The id for the PBM in query
    /// @return name The name of the PBM type
    /// @return spotAmount Amount of underlying ERC20 held by the each of the PBM token
    /// @return expiry  Expiry time (in epoch) for the PBM type
    /// @return creator Creator for the PBM type
    function getTokenDetails(
        uint256 tokenId
    ) external view returns (string memory, uint256, address, bool, uint256, bool, uint256, bool) ;

    function createTokenType(
        NewTokenType memory tokenType
    ) external returns(uint256);

    /// @notice increases the supply count for the PBM
    /// @param tokenIds The ids for which the supply count needs to be increased
    /// @param amounts The amounts by whch the supply counnt needs to be increased
    function increaseBalanceSupply(uint256[] memory tokenIds, uint256[] memory amounts) external;

    /// @notice decreases the supply count for the PBM
    /// @param tokenIds The ids for which the supply count needs to be decreased
    /// @param amounts The amounts by whch the supply counnt needs to be decreased
    function decreaseBalanceSupply(uint256[] memory tokenIds, uint256[] memory amounts) external;

    /// @notice  performs all the necessary actions required after the revoking of a PBM type
    /// @param tokenId The PBM tokenId which has been revoked
    /// @param sender updated token URI to convey revoking, if part of design
    function revokePBM(uint256 tokenId, address sender) external;

    /// @notice Event emitted when a new PBM token type is created
    /// @param tokenId The account from which the tokens were sent, i.e. the balance decreased
    /// @param tokenName The account to which the tokens were sent, i.e. the balance increased
    /// @param amount The amount of tokens that were transferred
    /// @param expiry The time (in epoch) when the PBM type will expire
    /// @param creator The creator of the this PBM type
    event NewPBMTypeCreated(uint256 tokenId, string tokenName, uint256 amount, uint256 expiry, address creator);
}