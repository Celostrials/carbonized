// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interface/ICarbonizer.sol";
import "./interface/ICarbonizerDeployer.sol";

/// @title CarbonizedCollection
/// @author Bridger Zoske
/// @dev This contract inherits from both ERC721 that ERC721Receiver which enables the mint,
/// burn and safe storage of other ERC721 tokens.
contract CarbonizedCollection is
    OwnableUpgradeable,
    ERC721EnumerableUpgradeable,
    IERC721ReceiverUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /* ========== STATE VARIABLES ========== */

    IERC721Upgradeable public originalCollection;
    ICarbonizerDeployer public deployer;
    string public baseURI;
    string public baseExtension;
    // tokenId => carbonizer
    mapping(uint256 => address) public carbonizer;

    /* ========== INITIALIZER ========== */

    function initialize(
        address _originalCollection,
        address _deployer,
        string memory _name,
        string memory _symbol,
        string memory _baseURI
    ) external virtual initializer {
        __Ownable_init();
        __ERC721_init(_name, _symbol);
        originalCollection = IERC721Upgradeable(_originalCollection);
        deployer = ICarbonizerDeployer(_deployer);
        baseExtension = ".json";
        baseURI = _baseURI;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function carbonize(uint256 tokenId) public payable {
        // deploy carbonizer contract if not already deployed
        if (carbonizer[tokenId] == address(0)) carbonizer[tokenId] = deployer.deploy(address(this));
        // if token not already carbonized
        if (!exists(tokenId)) {
            originalCollection.safeTransferFrom(msg.sender, address(this), tokenId);
            _safeMint(msg.sender, tokenId);
        }
        ICarbonizer(carbonizer[tokenId]).deposit{value: msg.value}();
        emit TokenIdCarbonized(tokenId, msg.value);
    }

    function startDecarbonize(uint256 tokenId) external {
        require(
            carbonizer[tokenId] != address(0),
            "CarbonizedCollection: tokenId is not carbonized"
        );
        ICarbonizer(carbonizer[tokenId]).withdraw(); 
    }
 
    function decarbonize(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "CarbonizedCollection: caller does not own tokenId");
        originalCollection.safeTransferFrom(address(this), msg.sender, tokenId);
        ICarbonizer(carbonizer[tokenId]).claim(msg.sender); 
        _burn(tokenId);
        emit TokenIdDecarbonized(tokenId);
    }

    /* ========== VIEWS ========== */

    function getDeposit(uint256 tokenId) external view returns (uint256) {
        return ICarbonizer(carbonizer[tokenId]).getDeposit();
    }

    function withdrawls(uint256 tokenId) external view returns (uint256 value, uint256 timestamp) {
        return ICarbonizer(carbonizer[tokenId]).withdrawls();
    }

    function getYield(uint256 tokenId) external view returns (uint256) {
        return ICarbonizer(carbonizer[tokenId]).getYield();
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory, address[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        address[] memory carbonizers = new address[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
            carbonizers[i] = carbonizer[tokenIds[i]];
        }
        return (tokenIds, carbonizers);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    /* ========== EVENTS ========== */   

    event TokenIdCarbonized(uint256 tokenId, uint256 amount);
    
    event TokenIdDecarbonized(uint256 tokenId);
}
