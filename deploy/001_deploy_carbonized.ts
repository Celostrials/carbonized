import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"
import { deployProxyAndSave } from "../utils/utils"
import { deployments, ethers } from "hardhat"
import { ERC721__factory } from "../types/factories/ERC721__factory"

const func: DeployFunction = async function (hardhat: HardhatRuntimeEnvironment) {
  let originalCollectionAddress = "0xF19bDabB42228c0BcF1e561C74bE8195DD65d262"
  let gTokenAddress = "0x62384Ec02B97CF2A7D696f118706351dDCA10b87"
  let carbonizedBaseURI = "https://ipfs"

  if (!gTokenAddress) throw Error("No gToken address specified in env")
  if (!carbonizedBaseURI) throw Error("No carbonized base URI specified in env")

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
