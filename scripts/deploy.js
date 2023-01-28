const { ethers } = require("hardhat");

const main = async()=> {
 
  const NFT_CONTRACT_ADDRESS = "0xDB44a1b7105a4cdf6f1Bd8Fb81F2A65e1f1c2638";

  const nftMarketplaceInstance = await ethers.getContractFactory("FakeNFTMarketplace");
  const fakeNFTMarketplace = await nftMarketplaceInstance.deploy()
  await fakeNFTMarketplace.deployed()

  console.log("Fake NFT Marketplace address is ", fakeNFTMarketplace.address);

  const CryptoDevsDAO = await ethers.getContractFactory("CryptoDevsDAO");
  const cryptoDevsDAO = await CryptoDevsDAO.deploy(fakeNFTMarketplace.address, NFT_CONTRACT_ADDRESS);
  await cryptoDevsDAO.deployed();

  console.log("CryptoDevsDAO contract address = ", cryptoDevsDAO.address);
  
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
