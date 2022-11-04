// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./interface/ImpactVaultInterface.sol";

/// @title CarbonizedCollection
/// @author Bridger Zoske
/// @notice
/// @dev This contract inherits from both ERC721 that ERC721Receiver which enables both mint
/// and burn as well as the safe storage of other ERC721 tokens.
contract CarbonizedCollection is
    OwnableUpgradeable,
    ERC721EnumerableUpgradeable,
    IERC721ReceiverUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC721Upgradeable public originalCollection;
    ImpactVaultInterface public gTokenVault;
    address public carbonCredit;
    string public baseURI;
    string public baseExtension;
    uint256 public carbonPerGTokenStored;
    // tokenId => carbonAmount
    mapping(uint256 => uint256) public carbonDeposit;
    // tokenId => gTokenBalance
    mapping(uint256 => uint256) public gTokenBalance;
    // tokenId => carbon credits per token paid
    mapping(uint256 => uint256) public idCarbonPerTokenPaid;
    uint256 totalGToken;
    uint256 carbonCreditsRetired;

    function initialize(
        address _originalCollection,
        address _gTokenVaultAddress,
        address _carbonCredit,
        string memory _name,
        string memory _symbol,
        string memory _baseURI
    ) external virtual initializer {
        __Ownable_init();
        __ERC721_init(_name, _symbol);
        originalCollection = IERC721Upgradeable(_originalCollection);
        gTokenVault = ImpactVaultInterface(_gTokenVaultAddress);
        carbonCredit = _carbonCredit;
        baseExtension = ".json";
        baseURI = _baseURI;
    }

    function carbonize(uint256 tokenId, uint256 amount)
        public
        _updateCarbonDeposits(int256(tokenId))
    {
        gTokenVault.asset().safeTransferFrom(msg.sender, address(this), amount);
        gTokenVault.asset().approve(address(gTokenVault), amount);
        gTokenVault.deposit(amount, address(this));
        originalCollection.safeTransferFrom(msg.sender, address(this), tokenId);
        gTokenBalance[tokenId] += amount;
        totalGToken += amount;
        mint(tokenId);
    }

    function decarbonize(uint256 tokenId) public _updateCarbonDeposits(int256(tokenId)) {
        require(gTokenBalance[tokenId] != 0, "CarbonizedCollection: tokenId has no gToken");
        originalCollection.safeTransferFrom(address(this), msg.sender, tokenId);
        gTokenVault.withdraw(gTokenBalance[tokenId], msg.sender, msg.sender);
        totalGToken -= gTokenBalance[tokenId];
        gTokenBalance[tokenId] = 0;
        _burn(tokenId);
    }

    function carbonizeBatch(uint256[] memory tokenIds, uint256[] memory amounts) external {
        require(
            tokenIds.length == amounts.length,
            "CarbonizedCollection: invalid tokenIds and amounts"
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            carbonize(tokenIds[i], amounts[i]);
        }
    }

    function decarbonizeBatch(uint256[] memory tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            decarbonize(tokenIds[i]);
        }
    }

    // TODO: When Celo carbon retirment available
    // function retireCarbon(uint256 amount) external _updateCarbonDeposits(-1) {
    //     require(
    //         IERC20Upgradeable(carbonCredit).balanceOf(address(this)) > 0,
    //         "CarbonizedCollection: No credits to retire."
    //     );
    //
    //     carbonCreditsRetired += amount;
    // }

    function carbonBalance(address account) external view returns (uint256 carbon) {
        (, uint256[] memory carbonBalances, ) = walletOfOwner(account);
        for (uint256 i = 0; i < carbonBalances.length; i++) {
            carbon += carbonBalances[i];
        }
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function mint(uint256 tokenId) private {
        _safeMint(msg.sender, tokenId);
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        uint256[] memory carbonDeposits = new uint256[](ownerTokenCount);
        uint256[] memory gTokenBalances = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
            carbonDeposits[i] = carbonDeposit[tokenIds[i]];
            gTokenBalances[i] = gTokenBalance[tokenIds[i]];
        }
        return (tokenIds, carbonDeposits, gTokenBalances);
    }

    function carbonCollected(uint256 tokenId) public view returns (uint256 carbon) {
        return (((gTokenBalance[tokenId] * (carbonPerGToken() - idCarbonPerTokenPaid[tokenId])) /
            1e18) + carbonDeposit[tokenId]);
    }

    modifier _updateCarbonDeposits(int256 tokenId) {
        carbonPerGTokenStored = carbonPerGToken();
        if (tokenId > -1) {
            carbonDeposit[uint256(tokenId)] = carbonCollected(uint256(tokenId));
            idCarbonPerTokenPaid[uint256(tokenId)] = carbonPerGTokenStored;
        }
        _;
    }

    function carbonPerGToken() public view returns (uint256) {
        if (totalGToken == 0) {
            return carbonPerGTokenStored;
        }
        return
            carbonPerGTokenStored +
            ((carbonCreditsRetired + IERC20Upgradeable(carbonCredit).balanceOf(address(this))) /
                totalGToken);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}
