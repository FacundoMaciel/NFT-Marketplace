// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
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
    address deployer = vm.addr(1);

    function setUp() public {
        vm.startPrank(deployer);

        marketplace = new NFTMarketplace();


        vm.stopPrank();
    }


}