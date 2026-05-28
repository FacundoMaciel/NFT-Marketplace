// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "lib/forge-std/src/Test.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "../src/NFTMarketplace.sol";

contract MockNFT is ERC721 {

    constructor() ERC721("MockNFT", "MNFT") {}

    function mint(address to_, uint256 tokenId_) external {
        _mint(to_, tokenId_);
    }
}

contract NFTMarketplaceTest is Test {
    
    NFTMarketplace marketplace;
    MockNFT mockNFT;
    address deployer = vm.addr(1);
    address user = vm.addr(2);
    uint256 tokenId = 0;

    function setUp() public {
        vm.startPrank(deployer);
        marketplace = new NFTMarketplace();
        mockNFT = new MockNFT();
        vm.stopPrank();
        
        vm.startPrank(user);
        mockNFT.mint(user, tokenId);
        vm.stopPrank();
    }

    function testMintNFT() public view {
        address ownerOf = mockNFT.ownerOf(tokenId);
        assert(ownerOf == user);

    }

    function testShouldRevertIfPriceIsZero() public {
        vm.startPrank(user);

        vm.expectRevert("Price cannot be 0");
        marketplace.listNFT(address(mockNFT), tokenId, 0);

        vm.stopPrank();
    }

    function testShouldRevertIfNotOwner() public {
        vm.startPrank(user);

        address user2_ = vm.addr(3);
        uint256 tokenId_ = 1;
        mockNFT.mint(user2_, 1);

        vm.expectRevert("You are not the owner of the NFT");
        marketplace.listNFT(address(mockNFT), tokenId_, 1);

        vm.stopPrank();
    }

    function testListNFTcorrectly() public {
         vm.startPrank(user);

        (address sellerBefore,,,) = marketplace.listing(address(mockNFT), tokenId);
        marketplace.listNFT(address(mockNFT), tokenId, 1e18);
        (address sellerAfter,,,) = marketplace.listing(address(mockNFT), tokenId);

        assert(sellerBefore == address(0) && sellerAfter == user);

        vm.stopPrank();
    }

    function testListShouldRevertIfNotOwner() public {
         vm.startPrank(user);

        (address sellerBefore,,,) = marketplace.listing(address(mockNFT), tokenId);
        marketplace.listNFT(address(mockNFT), tokenId, 1e18);
        (address sellerAfter,,,) = marketplace.listing(address(mockNFT), tokenId);

        assert(sellerBefore == address(0) && sellerAfter == user);

        vm.stopPrank();

        address user2_ = vm.addr(3);
        vm.startPrank(user2_);

        vm.expectRevert("You are not the seller of the NFT");
        marketplace.cancelList(address(mockNFT), tokenId);

        vm.stopPrank();
    }

    function testCancelListShouldWorkCorrectly() public {
        vm.startPrank(user);

        (address sellerBefore,,,) = marketplace.listing(address(mockNFT), tokenId);
        marketplace.listNFT(address(mockNFT), tokenId, 1e18);
        (address sellerAfter,,,) = marketplace.listing(address(mockNFT), tokenId);

        assert(sellerBefore == address(0) && sellerAfter == user);

        marketplace.cancelList(address(mockNFT), tokenId);
        (address sellerAfter2,,,) = marketplace.listing(address(mockNFT), tokenId);
        assert(sellerAfter2 == address(0));

        vm.stopPrank();
    }

    function testCanNotBuyUnlistedNFT() public {
        address user2_ = vm.addr(3);
        vm.startPrank(user2_);

        vm.expectRevert("Listing does not exist");
        marketplace.buyNFT(address(mockNFT), tokenId);

        vm.stopPrank();
    }

    function testCannotBuyWithIncorrectPrice() public {
        vm.startPrank(user);

        uint256 price_ = 1e18;
        (address sellerBefore,,,) = marketplace.listing(address(mockNFT), tokenId);
        marketplace.listNFT(address(mockNFT), tokenId, 1e18);
        (address sellerAfter,,,) = marketplace.listing(address(mockNFT), tokenId);
        assert(sellerBefore == address(0) && sellerAfter == user);

        vm.stopPrank();

        address user2_ = vm.addr(3);
        vm.startPrank(user2_);
        vm.deal(user2_, price_);
        vm.expectRevert("Incorrect price");
        marketplace.buyNFT{value: price_ - 1}(address(mockNFT), tokenId);

        vm.stopPrank();
    }

    function testShouldBuyNFTCorrectly() public {
        vm.startPrank(user);

        uint256 price_ = 1e18;

        (address sellerBefore,,,) = marketplace.listing(address(mockNFT), tokenId);
        marketplace.listNFT(address(mockNFT), tokenId, 1e18);
        (address sellerAfter,,,) = marketplace.listing(address(mockNFT), tokenId);

        assert(sellerBefore == address(0) && sellerAfter == user);

        mockNFT.approve(address(marketplace), tokenId);
        vm.stopPrank();

        address user2_ = vm.addr(3);
        vm.startPrank(user2_);
        vm.deal(user2_, price_);

        uint256 balanceBefore = address(user).balance;
        address ownerBefore = mockNFT.ownerOf(tokenId);
        (address sellerBefore2,,,) = marketplace.listing(address(mockNFT), tokenId);
        marketplace.buyNFT{value: price_}(address(mockNFT), tokenId);
        (address sellerAfter2,,,) = marketplace.listing(address(mockNFT), tokenId);
        address ownerAfter = mockNFT.ownerOf(tokenId);
        uint256 balanceAfter = address(user).balance;

        assert(sellerBefore2 == user && sellerAfter2 == address(0));
        assert(ownerBefore == user && ownerAfter == user2_);
        assert(balanceAfter == balanceBefore + price_);

        vm.stopPrank();
    }

}