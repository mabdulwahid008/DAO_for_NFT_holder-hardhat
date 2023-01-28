// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IFakeNFTMarketplace {

    function purchase(uint256 _tokenId) external payable;

    function getPrice() external view returns(uint256);

    function available(uint256 _tokenId) external view returns(bool);

}

interface ICryptoDevsToken {

    function balanceOf(address owner) external view returns(uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns(uint256);
}