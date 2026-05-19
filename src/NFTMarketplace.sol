// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract NFTMarketplace is Ownable {

    struct Listing {
        address seller;
        address nftAddress;
        uint256 tokenId;
        uint256 price;
    }

    mapping(address => mapping(uint256 => Listing)) listing;

    constructor() Ownable(msg.sender) {}
    
    function listNFT(address nftAddress_, uint256 tokenId_, uint256 price_) external {
        Listing listing_ = Listing({
            seller: msg.sender,
            nftAddress: nftAddress_,
            tokenId: tokenId_,
            price: price_
        })
    }


}