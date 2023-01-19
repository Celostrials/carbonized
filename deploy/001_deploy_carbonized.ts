import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"
import { deployProxyAndSave } from "../utils/utils"
import { deployments, ethers } from "hardhat"
import { ERC721__factory } from "../types/factories/ERC721__factory"

const func: DeployFunction = async function (hardhat: HardhatRuntimeEnvironment) {
  // testnet
  // let originalCollectionAddress = "0xAEDbf9394F1dc1d7Ab945b34299b88fD8105001A"
  // let gTokenAddress = "0x62384Ec02B97CF2A7D696f118706351dDCA10b87"
  // let carbonizedBaseURI = "https://ipfs.io/ipfs/QmTsPLiy7bMhhQzmpwhBKMNz4DKBX9g5RoBkWfQcMmwFda/" 
  // mainnet
  let originalCollectionAddress = "0xAc80c3c8b122DB4DcC3C351ca93aC7E0927C605d"
  let gTokenAddress = "0x8A1639098644A229d08F441ea45A63AE050Ee018"
  let carbonizedBaseURI = "https://ipfs.io/ipfs/QmTsPLiy7bMhhQzmpwhBKMNz4DKBX9g5RoBkWfQcMmwFda/" 

  if (!originalCollectionAddress) {
    let mockNFTAddress = (await hardhat.deployments.getOrNull("MockNFT"))?.address
    if (!mockNFTAddress) {
      const mockNFTFactory = await ethers.getContractFactory("MockNFT")
      const mockNFTabi = (await hardhat.artifacts.readArtifact("MockNFT")).abi
      const mockNFT = await mockNFTFactory.deploy("mock", "mock", "https://ipfs")

      let contractDeployment = {
        address: mockNFT.address,
        abi: mockNFTabi,
        receipt: await mockNFT.deployTransaction.wait(),
      }

      hardhat.deployments.save("MockNFT", contractDeployment)

      originalCollectionAddress = mockNFT.address
    }
  }

  if (!originalCollectionAddress) throw Error("No original collection specified or deployed")

  if (!gTokenAddress) {
    const mockGTokenFactory = await ethers.getContractFactory("MockGToken")
    const mockGTokenabi = (await hardhat.artifacts.readArtifact("MockGToken")).abi
    const mockGToken = await mockGTokenFactory.deploy()

    let contractDeployment = {
      address: mockGToken.address,
      abi: mockGTokenabi,
      receipt: await mockGToken.deployTransaction.wait(),
    }

    hardhat.deployments.save("MockGToken", contractDeployment)

    gTokenAddress = mockGToken.address
  }

  const originalCollection = ERC721__factory.connect(
    originalCollectionAddress,
    (await hardhat.ethers.getSigners())[0]
  )

  const originalCollectionSymbol = await originalCollection.symbol()
  const originalCollectionName = await originalCollection.name()

  // Deploy carbonizerDeployer
  const carbonizerDeployerFactory = await ethers.getContractFactory("CarbonizerDeployer")
  const carbonizerDeployerAbi = (await hardhat.artifacts.readArtifact("CarbonizerDeployer")).abi
  const carbonizerDeployer = await carbonizerDeployerFactory.deploy(gTokenAddress)

  let contractDeployment = {
    address: carbonizerDeployer.address,
    abi: carbonizerDeployerAbi,
    receipt: await carbonizerDeployer.deployTransaction.wait(),
  }

  hardhat.deployments.save("CarbonizerDeployer", contractDeployment)

  // Deploy CarbonizedCollection
  const carbonizedCollectionAbi = (await hardhat.artifacts.readArtifact("CarbonizedCollection")).abi
  const carbonizedCollectionArgs = [
    originalCollectionAddress,
    carbonizerDeployer.address,
    "Carbonized " + originalCollectionName,
    originalCollectionSymbol + "02",
    carbonizedBaseURI,
  ]

  await deployProxyAndSave(
    "CarbonizedCollection",
    carbonizedCollectionArgs,
    hardhat,
    carbonizedCollectionAbi
  )
}
export default func
