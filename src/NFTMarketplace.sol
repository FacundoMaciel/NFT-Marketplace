// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

contract NFTMarketplace is Ownable {
    struct Listing {
        address seller;
        address nftAddress;
        uint256 tokenId;
        uint256 price;
    }

    mapping(address => mapping(uint256 => Listing)) listing;

    event NTFTListed(address indexed seller, address indexed nftAddress, uint256 indexed tokenId, uint256 price);
    event NTFTCanceled(address indexed seller, address indexed nftAddress, uint256 indexed tokenId);

    constructor() Ownable(msg.sender) {}

    function listNFT(address nftAddress_, uint256 tokenId_, uint256 price_) external {
        require(price_ > 0, "Price cannot be 0");
        address owner_ = IERC721(nftAddress_).ownerOf(tokenId_);
        require(owner_ == msg.sender, "You are not the owner of the NFT");

        Listing memory listing_ =
            Listing({seller: msg.sender, nftAddress: nftAddress_, tokenId: tokenId_, price: price_});

        listing[nftAddress_][tokenId_] = listing_;

        emit NTFTListed(msg.sender, nftAddress_, tokenId_, price_);
    }

    function cancelList(address nftAddress_, uint256 tokenId_) external {
        Listing memory listing_ = listing[nftAddress_][tokenId_];
        require(listing_.seller == msg.sender, "You are not the seller of the NFT");

        delete listing[nftAddress_][tokenId_];

        emit NTFTCanceled(msg.sender, nftAddress_, tokenId_);
    }
}
