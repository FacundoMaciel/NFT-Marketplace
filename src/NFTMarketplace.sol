// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

contract NFTMarketplace is Ownable, ReentrancyGuard {
    struct Listing {
        address seller;
        address nftAddress;
        uint256 tokenId;
        uint256 price;
    }

    mapping(address => mapping(uint256 => Listing)) public listing;
    uint256 public marketplaceFeeBps = 250;

    event NTFTListed(address indexed seller, address indexed nftAddress, uint256 indexed tokenId, uint256 price);
    event NTFTCanceled(address indexed seller, address indexed nftAddress, uint256 indexed tokenId);
    event NFTSold(
        address indexed buyer, address indexed seller, address indexed nftAddress, uint256 tokenId, uint256 price
    );
    event MarketplaceFeeUpdated(uint256 newFeeBps);

    constructor() Ownable(msg.sender) {}

    // onlyOwner
    function setMarketplaceFee(uint256 feeBps_) external onlyOwner {
        require(feeBps_ <= 1000, "Fee too high");

        marketplaceFeeBps = feeBps_;

        emit MarketplaceFeeUpdated(feeBps_);
    }

    function listNFT(address nftAddress_, uint256 tokenId_, uint256 price_) external nonReentrant {
        require(price_ > 0, "Price cannot be 0");
        address owner_ = IERC721(nftAddress_).ownerOf(tokenId_);
        require(owner_ == msg.sender, "You are not the owner of the NFT");

        Listing memory listing_ =
            Listing({seller: msg.sender, nftAddress: nftAddress_, tokenId: tokenId_, price: price_});

        listing[nftAddress_][tokenId_] = listing_;

        emit NTFTListed(msg.sender, nftAddress_, tokenId_, price_);
    }

    function cancelList(address nftAddress_, uint256 tokenId_) external nonReentrant {
        Listing memory listing_ = listing[nftAddress_][tokenId_];
        require(listing_.seller == msg.sender, "You are not the seller of the NFT");

        delete listing[nftAddress_][tokenId_];

        emit NTFTCanceled(msg.sender, nftAddress_, tokenId_);
    }

    function buyNFT(address nftAddress_, uint256 tokenId_) external payable nonReentrant {
        Listing memory listing_ = listing[nftAddress_][tokenId_];
        require(listing_.price > 0, "Listing does not exist");
        require(msg.value == listing_.price, "Incorrect price");

        delete listing[nftAddress_][tokenId_];

        uint256 feeAmount_ = (msg.value * marketplaceFeeBps) / 10000;
        uint256 sellerAmount_ = msg.value - feeAmount_;

        IERC721(nftAddress_).safeTransferFrom(listing_.seller, msg.sender, listing_.tokenId);

        (bool success_,) = listing_.seller.call{value: sellerAmount_}("");
        require(success_, "Failed to transfer funds");

        // fee para owner
        (bool feeSuccess,) = owner().call{value: feeAmount_}("");
        require(feeSuccess, "Fee transfer failed");

        emit NFTSold(msg.sender, listing_.seller, nftAddress_, tokenId_, listing_.price);
    }
}
