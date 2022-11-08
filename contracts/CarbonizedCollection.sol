// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interface/IGTokenEscrow.sol";
import "./interface/IEscrowDeployer.sol";

/// @title CarbonizedCollection
/// @author Bridger Zoske
/// @dev This contract inherits from both ERC721 that ERC721Receiver which enables both mint
/// and burn as well as the safe storage of other ERC721 tokens.
contract CarbonizedCollection is
    OwnableUpgradeable,
    ERC721EnumerableUpgradeable,
    IERC721ReceiverUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC721Upgradeable public originalCollection;
    IEscrowDeployer public deployer;
    address public gTokenVaultAddress;
    address public carbonCredit;
    string public baseURI;
    string public baseExtension;
    uint256 public carbonPerGTokenStored;
    // tokenId => carbonAmount
    mapping(uint256 => uint256) public carbonDeposit;
    // tokenId => GTokenEscrow
    mapping(uint256 => address) public gTokenEscrow;
    // tokenId => carbon credits per token paid
    mapping(uint256 => uint256) public idCarbonPerTokenPaid;
    uint256 totalGToken;

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
        gTokenVaultAddress = _gTokenVaultAddress;
        carbonCredit = _carbonCredit;
        baseExtension = ".json";
        baseURI = _baseURI;
    }

    function carbonize(uint256 tokenId) public payable _updateCarbonDeposits(int256(tokenId)) {
        originalCollection.safeTransferFrom(msg.sender, address(this), tokenId);
        // deploy gTokenEscrow contract if not already deployed
        if (gTokenEscrow[tokenId] == address(0)) gTokenEscrow[tokenId] = deployer.deploy();
        IGTokenEscrow(gTokenEscrow[tokenId]).deposit{value: msg.value}();
        totalGToken += msg.value;
        mint(tokenId);
    }

    function startDecarbonize(uint256 tokenId) external {
        require(
            gTokenEscrow[tokenId] == address(0),
            "CarbonizedCollection: tokenId is not carbonized"
        );
        IGTokenEscrow(gTokenEscrow[tokenId]).withdraw();
    }

    function decarbonize(uint256 tokenId) public _updateCarbonDeposits(int256(tokenId)) {
        originalCollection.safeTransferFrom(address(this), msg.sender, tokenId);
        totalGToken -= IGTokenEscrow(gTokenEscrow[tokenId]).gTokenBalance();
        IGTokenEscrow(gTokenEscrow[tokenId]).claim();
        _burn(tokenId);
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
        returns (uint256[] memory, uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        uint256[] memory carbonDeposits = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
            carbonDeposits[i] = carbonCollected(tokenIds[i]);
        }
        return (tokenIds, carbonDeposits);
    }

    function carbonCollected(uint256 tokenId) public view returns (uint256 carbon) {
        return (((IGTokenEscrow(gTokenEscrow[tokenId]).gTokenBalance() *
            (carbonPerGToken() - idCarbonPerTokenPaid[tokenId])) / 1e18) + carbonDeposit[tokenId]);
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
            (IERC20Upgradeable(carbonCredit).balanceOf(address(this)) / totalGToken);
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
