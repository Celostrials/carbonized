import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"
import { deployProxyAndSave } from "../utils/utils"
import { deployments, ethers } from "hardhat"
import { parseEther } from "ethers/lib/utils"
import { ERC721__factory } from "../types/factories/ERC721__factory"
import { CarbonRewards__factory, ERC20__factory } from "../types"

let originalNFTAddress = "<<Insert originalCollectionAddress>>"
let carbonAddress = "<<Insert carbon address>>"
let rewardAddress = "<<Insert reward address>>"

const func: DeployFunction = async function (hardhat: HardhatRuntimeEnvironment) {
  if (hardhat.network.name == "localhost" || hardhat.network.name == "celo-alfajores") {
    let mockNFTAddress = (await hardhat.deployments.getOrNull("MockNFT"))?.address
    if (!mockNFTAddress) {
      const mockNFT = await deployments.deploy("MockNFT", {
        from: (await hardhat.ethers.getSigners())[0].address,
        args: ["mock", "mock", "https://ipfs"],
      })
      originalNFTAddress = mockNFT.address
    }

    let mockCarbonAddress = (await hardhat.deployments.getOrNull("MockCarbon"))?.address
    if (!mockCarbonAddress) {
      const mockCarbon = await deployments.deploy("MockCarbon", {
        from: (await hardhat.ethers.getSigners())[0].address,
        args: [parseEther("100000000")],
      })
      carbonAddress = mockCarbon.address
    }

    let mockRewardAddress = (await hardhat.deployments.getOrNull("MockReward"))?.address
    if (!mockRewardAddress) {
      const mockReward = await deployments.deploy("MockReward", {
        from: (await hardhat.ethers.getSigners())[0].address,
        args: [parseEther("100000000")],
      })
      rewardAddress = mockReward.address
    }
  }
  // CarbonRewards deploy
  const carbonRewardsAbi = (await hardhat.artifacts.readArtifact("CarbonRewards")).abi
  let carbonRewardsArgs = [(await hardhat.ethers.getSigners())[0].address, rewardAddress]
  const carbonRewardsAddress = await deployProxyAndSave(
    "CarbonRewards",
    carbonRewardsArgs,
    hardhat,
    carbonRewardsAbi
  )

  const collectionName = await ERC721__factory.connect(
    originalNFTAddress,
    (
      await hardhat.ethers.getSigners()
    )[0]
  ).name()

  const collectionSymbol = await ERC721__factory.connect(
    originalNFTAddress,
    (
      await hardhat.ethers.getSigners()
    )[0]
  ).symbol()

  const carbonSymbol = await ERC20__factory.connect(
    carbonAddress,
    (
      await hardhat.ethers.getSigners()
    )[0]
  ).symbol()

  // CarbonizedCollection deploy
  const carbonizedCollectionAbi = (await hardhat.artifacts.readArtifact("CarbonizedCollection")).abi
  const carbonizedCollectionArgs = [
    originalNFTAddress,
    carbonAddress,
    carbonRewardsAddress,
    "Carbonized" + collectionName,
    collectionSymbol + "-" + carbonSymbol,
  ]

  const carbonizedCollectionAddress = await deployProxyAndSave(
    "CarbonizedCollection",
    carbonizedCollectionArgs,
    hardhat,
    carbonizedCollectionAbi
  )

  await (
    await CarbonRewards__factory.connect(
      carbonRewardsAddress,
      (
        await hardhat.ethers.getSigners()
      )[0]
    ).setCarbonCollection(carbonizedCollectionAddress)
  ).wait()
}
export default func
func.tags = ["carbon"]
