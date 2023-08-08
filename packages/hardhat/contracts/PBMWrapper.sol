// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./PBMTokenManager.sol";
import "./PBMLogicFactory.sol";
import "./interfaces/IPBMWrapper.sol";
import "./interfaces/IPBMLogic.sol";
import "./interfaces/IPBMLogicFactory.sol";
import "./interfaces/IPBMTokenManager.sol";

contract PBM is ERC1155 {
    // underlying usdc token
    IERC20 public usdcToken;
    // IERC20 public usdcToken = IERC20(address(0x07865c6E87B9F70255377e024ace6630C1Eaa37F)); // USDC address on goerli

    // PBMTokenManager instance
    IPBMTokenManager public pbmTokenManager;
    // PBMLogic contract instance
    IPBMLogic public pbmLogic;

    address public contractOwner;

    event PBMrevokeWithdraw(address owner, uint256 tokenId);

    // tracks contract initialisation
    bool internal initialised = false;

    // time of expiry ( epoch )
    uint256 public contractExpiry;

    constructor(address allowedToken) ERC1155("") {
        usdcToken = IERC20(allowedToken);
        contractOwner = msg.sender;
        pbmTokenManager = IPBMTokenManager(address(new PBMTokenManager()));
    }

    //mapping to keep track of how much an user has loaded to PBM
    mapping(address => uint256) public userWalletBalance;

    //mapping to keep track of how much an user is allowed to withdraw from PBM
    mapping(address => mapping(address => uint256)) private _allowances;

    function initialise(bool isBlacklist, bool isWhitelist) external {
        require(!initialised, "PBM Logic already initialised");
        pbmLogic = IPBMLogic(IPBMLogicFactory(new PBMLogicFactory()).createPBMLogic(msg.sender, isBlacklist, isWhitelist));
        initialised = true;
    }

    function createPBMTokenType(
        string memory companyName,
        uint256 spotAmount,
        address creator,
        uint256 contractExpiry,
        bool isFixedSupply,
        uint256 initialSupply,
        bool isExpiring,
        uint256 tokenExpiry,
        address tokenOwner
    ) external {

        IPBMTokenManager.NewTokenType memory newToken = IPBMTokenManager.NewTokenType({
            companyName: companyName,
            spotAmount: spotAmount,
            creator: creator,
            contractExpiry: contractExpiry,
            isFixedSupply: isFixedSupply,
            initialSupply: initialSupply,
            isExpiring: isExpiring,
            tokenExpiry: tokenExpiry
        });

        uint256 tokenId = pbmTokenManager.createTokenType(newToken);
        if (initialSupply != 0) {
            _mint(tokenOwner, tokenId, initialSupply, "");
        }
    }

    function mint(uint256 tokenId, uint256 amount, address receiver) external {
        (,,,bool isFixedSupply,,,,) = pbmTokenManager.getTokenDetails(tokenId);
        require(!isFixedSupply, "Token id provided has set supply to be fixed, minting of new tokens is not allowed");
        require(pbmLogic.isTransferrable(receiver), "PBM: 'to' address blacklisted");

        pbmTokenManager.increaseBalanceSupply(serialise(tokenId), serialise(amount));
        _mint(receiver, tokenId, amount, "");
    }

    function batchMint(
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        address receiver
    ) external {
        require(!pbmLogic.isTransferrable(receiver), "PBM: 'to' address blacklisted");
        require(tokenIds.length == amounts.length, "Unequal ids and amounts supplied");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            (,,,bool isFixedSupply,,,,) = pbmTokenManager.getTokenDetails(tokenIds[i]);
            require(!isFixedSupply, "Token id provided has set supply to be fixed, minting of new tokens is not allowed");
        }

        pbmTokenManager.increaseBalanceSupply(tokenIds, amounts);
        _mintBatch(receiver, tokenIds, amounts, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override(ERC1155) {
        require(pbmTokenManager.areTokensValid(serialise(id)), "Invalid token id");
        require(pbmLogic.isTransferrable(to), "PBM: 'to' address blacklisted");

        _safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public override(ERC1155) {
        require(pbmTokenManager.areTokensValid(ids), "Invalid token ids");
        require(ids.length == amounts.length, "Unequal ids and amounts supplied");
        require(pbmLogic.isTransferrable(to), "PBM: 'to' address blacklisted");
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function revokePBM(uint256 tokenId) external {
        uint256 valueOfTokens = pbmTokenManager.getPBMRevokeValue(tokenId);

        // pbmTokenManager.revokePBM checks that the address passed in is indeed the owner of the token in the first place
        pbmTokenManager.revokePBM(tokenId, msg.sender);

        // transfering underlying USDC tokens
        require(usdcToken.transfer(msg.sender, usdcToken.balanceOf(address(this))), "Failed to transfer remaining USDC to owner");

    }

    function getTokenDetails(
        uint256 tokenId
    ) external view returns (string memory, uint256, address, bool, uint256, bool, uint256, bool){
        return pbmTokenManager.getTokenDetails(tokenId);
    }

    function redeem(uint256[] memory tokenIds, uint256[] memory amounts) public {
        uint256 totalRedeemValue = 0;
        // if whitelist feature enabled, only whitelisted accounts can redeem the tokens
        // if not, anyone can redeem the tokens
        require(pbmLogic.isUnwrappable(msg.sender), "Caller is not in the whitelist to redeem tokens");
        require(pbmTokenManager.areTokensValid(tokenIds), "Invalid token ids");
        require(tokenIds.length == amounts.length, "Unequal ids and amounts supplied"); 
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(balanceOf(msg.sender, tokenIds[i]) >= amounts[i], "Insufficient PBM tokens in account");
            totalRedeemValue = totalRedeemValue + (amounts[i] * pbmTokenManager.getTokenValue(tokenIds[i]));
        }
        // check that the contract has enough USDC to exchange for the value of the tokens
        require(usdcToken.balanceOf(address(this)) >= totalRedeemValue, "Contract does not have enough USDC to exchange for tokens");
        // decrease the supply of the tokens, burn the tokens
        _burnBatch(msg.sender, tokenIds, amounts);
        pbmTokenManager.decreaseBalanceSupply(tokenIds, amounts);
        // transfer digital money to the msg.sender
        require(usdcToken.transfer(msg.sender, totalRedeemValue), "Failed to transfer USDC to redeemer");
    }

    function serialise(uint256 num) internal pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = num;
        return array;
    }
}